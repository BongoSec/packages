# Bongosec installer - indexer.sh functions.
# Copyright (C) 2015, Bongosec Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

function indexer_configure() {

    common_logger -d "Configuring Bongosec indexer."
    eval "export JAVA_HOME=/usr/share/bongosec-indexer/jdk/"

    # Configure JVM options for Bongosec indexer
    ram_gb=$(free -m | awk 'FNR == 2 {print $2}')
    ram="$(( ram_mb / 2 ))"

    if [ "${ram}" -eq "0" ]; then
        ram=1024;
    fi
    eval "sed -i "s/-Xms1g/-Xms${ram}m/" /etc/bongosec-indexer/jvm.options ${debug}"
    eval "sed -i "s/-Xmx1g/-Xmx${ram}m/" /etc/bongosec-indexer/jvm.options ${debug}"

    if [ -n "${AIO}" ]; then
        eval "installCommon_getConfig indexer/indexer_all_in_one.yml /etc/bongosec-indexer/opensearch.yml ${debug}"
    else
        eval "installCommon_getConfig indexer/indexer_unattended_distributed.yml /etc/bongosec-indexer/opensearch.yml ${debug}"
        if [ "${#indexer_node_names[@]}" -eq 1 ]; then
            pos=0
            {
            echo "node.name: ${indxname}"
            echo "network.host: ${indexer_node_ips[0]}"
            echo "cluster.initial_master_nodes: ${indxname}"
            echo "plugins.security.nodes_dn:"
            echo '        - CN='"${indxname}"',OU=Bongosec,O=Bongosec,L=California,C=US'
            } >> /etc/bongosec-indexer/opensearch.yml
        else
            echo "node.name: ${indxname}" >> /etc/bongosec-indexer/opensearch.yml
            echo "cluster.initial_master_nodes:" >> /etc/bongosec-indexer/opensearch.yml
            for i in "${indexer_node_names[@]}"; do
                echo "        - ${i}" >> /etc/bongosec-indexer/opensearch.yml
            done

            echo "discovery.seed_hosts:" >> /etc/bongosec-indexer/opensearch.yml
            for i in "${indexer_node_ips[@]}"; do
                echo "        - ${i}" >> /etc/bongosec-indexer/opensearch.yml
            done

            for i in "${!indexer_node_names[@]}"; do
                if [[ "${indexer_node_names[i]}" == "${indxname}" ]]; then
                    pos="${i}";
                fi
            done

            echo "network.host: ${indexer_node_ips[pos]}" >> /etc/bongosec-indexer/opensearch.yml

            echo "plugins.security.nodes_dn:" >> /etc/bongosec-indexer/opensearch.yml
            for i in "${indexer_node_names[@]}"; do
                    echo "        - CN=${i},OU=Bongosec,O=Bongosec,L=California,C=US" >> /etc/bongosec-indexer/opensearch.yml
            done
        fi
    fi

    indexer_copyCertificates

    jv=$(java -version 2>&1 | grep -o -m1 '1.8.0' )
    if [ "$jv" == "1.8.0" ]; then
        {
        echo "bongosec-indexer hard nproc 4096"
        echo "bongosec-indexer soft nproc 4096"
        echo "bongosec-indexer hard nproc 4096"
        echo "bongosec-indexer soft nproc 4096"
        } >> /etc/security/limits.conf
        echo -ne "\nbootstrap.system_call_filter: false" >> /etc/bongosec-indexer/opensearch.yml
    fi

    common_logger "Bongosec indexer post-install configuration finished."
}

function indexer_copyCertificates() {

    common_logger -d "Copying Bongosec indexer certificates."
    eval "rm -f ${indexer_cert_path}/* ${debug}"
    name=${indexer_node_names[pos]}

    if [ -f "${tar_file}" ]; then
        if ! tar -tvf "${tar_file}" | grep -q "${name}" ; then
            common_logger -e "Tar file does not contain certificate for the node ${name}."
            installCommon_rollBack
            exit 1;
        fi
        eval "mkdir ${indexer_cert_path} ${debug}"
        eval "sed -i s/indexer.pem/${name}.pem/ /etc/bongosec-indexer/opensearch.yml ${debug}"
        eval "sed -i s/indexer-key.pem/${name}-key.pem/ /etc/bongosec-indexer/opensearch.yml ${debug}"
        eval "tar -xf ${tar_file} -C ${indexer_cert_path} bongosec-install-files/${name}.pem --strip-components 1 ${debug}"
        eval "tar -xf ${tar_file} -C ${indexer_cert_path} bongosec-install-files/${name}-key.pem --strip-components 1 ${debug}"
        eval "tar -xf ${tar_file} -C ${indexer_cert_path} bongosec-install-files/root-ca.pem --strip-components 1 ${debug}"
        eval "tar -xf ${tar_file} -C ${indexer_cert_path} bongosec-install-files/admin.pem --strip-components 1 ${debug}"
        eval "tar -xf ${tar_file} -C ${indexer_cert_path} bongosec-install-files/admin-key.pem --strip-components 1 ${debug}"
        eval "rm -rf ${indexer_cert_path}/bongosec-install-files/ ${debug}"
        eval "chown -R bongosec-indexer:bongosec-indexer ${indexer_cert_path} ${debug}"
        eval "chmod 500 ${indexer_cert_path} ${debug}"
        eval "chmod 400 ${indexer_cert_path}/* ${debug}"
    else
        common_logger -e "No certificates found. Could not initialize Bongosec indexer"
        installCommon_rollBack
        exit 1;
    fi

}

function indexer_initialize() {

    common_logger "Initializing Bongosec indexer cluster security settings."
    eval "common_curl -XGET https://"${indexer_node_ips[pos]}":9200/ -uadmin:admin -k --max-time 120 --silent --output /dev/null"
    e_code="${PIPESTATUS[0]}"

    if [ "${e_code}" -ne "0" ]; then
        common_logger -e "Cannot initialize Bongosec indexer cluster."
        installCommon_rollBack
        exit 1
    fi

    if [ -n "${AIO}" ]; then
        eval "sudo -u bongosec-indexer JAVA_HOME=/usr/share/bongosec-indexer/jdk/ OPENSEARCH_CONF_DIR=/etc/bongosec-indexer /usr/share/bongosec-indexer/plugins/opensearch-security/tools/securityadmin.sh -cd /etc/bongosec-indexer/opensearch-security -icl -p 9200 -nhnv -cacert ${indexer_cert_path}/root-ca.pem -cert ${indexer_cert_path}/admin.pem -key ${indexer_cert_path}/admin-key.pem -h 127.0.0.1 ${debug}"
        if [  "${PIPESTATUS[0]}" != 0  ]; then
            common_logger -e "The Bongosec indexer cluster security configuration could not be initialized."
            installCommon_rollBack
            exit 1
        else
            common_logger "Bongosec indexer cluster security configuration initialized."
        fi
    fi

    if [ "${#indexer_node_names[@]}" -eq 1 ] && [ -z "${AIO}" ]; then
        installCommon_changePasswords
    fi

    common_logger "Bongosec indexer cluster initialized."

}

function indexer_install() {

    common_logger "Starting Bongosec indexer installation."

    if [ "${sys_type}" == "yum" ]; then
        installCommon_yumInstall "bongosec-indexer" "${bongosec_version}-*"
    elif [ "${sys_type}" == "apt-get" ]; then
        installCommon_aptInstall "bongosec-indexer" "${bongosec_version}-*"
    fi

    common_checkInstalled
    if [  "$install_result" != 0  ] || [ -z "${indexer_installed}" ]; then
        common_logger -e "Bongosec indexer installation failed."
        installCommon_rollBack
        exit 1
    else
        common_logger "Bongosec indexer installation finished."
    fi

    eval "sysctl -q -w vm.max_map_count=262144 ${debug}"

}

function indexer_startCluster() {

    common_logger -d "Starting Bongosec indexer cluster."
    for ip_to_test in "${indexer_node_ips[@]}"; do
        eval "common_curl -XGET https://"${ip_to_test}":9200/ -k -s -o /dev/null"
        e_code="${PIPESTATUS[0]}"

        if [ "${e_code}" -eq "7" ]; then
            common_logger -e "Connectivity check failed on node ${ip_to_test} port 9200. Possible causes: Bongosec indexer not installed on the node, the Bongosec indexer service is not running or you have connectivity issues with that node. Please check this before trying again."
            exit 1
        fi
    done

    eval "bongosec_indexer_ip=( $(cat /etc/bongosec-indexer/opensearch.yml | grep network.host | sed 's/network.host:\s//') )"
    eval "sudo -u bongosec-indexer JAVA_HOME=/usr/share/bongosec-indexer/jdk/ OPENSEARCH_CONF_DIR=/etc/bongosec-indexer /usr/share/bongosec-indexer/plugins/opensearch-security/tools/securityadmin.sh -cd /etc/bongosec-indexer/opensearch-security -icl -p 9200 -nhnv -cacert /etc/bongosec-indexer/certs/root-ca.pem -cert /etc/bongosec-indexer/certs/admin.pem -key /etc/bongosec-indexer/certs/admin-key.pem -h ${bongosec_indexer_ip} ${debug}"
    if [  "${PIPESTATUS[0]}" != 0  ]; then
        common_logger -e "The Bongosec indexer cluster security configuration could not be initialized."
        installCommon_rollBack
        exit 1
    else
        common_logger "Bongosec indexer cluster security configuration initialized."
    fi

    # Bongosec alerts template injection
    eval "common_curl --silent ${filebeat_bongosec_template} --max-time 300 --retry 5 --retry-delay 5 ${debug}" | eval "common_curl -X PUT 'https://${indexer_node_ips[pos]}:9200/_template/bongosec' -H 'Content-Type: application/json' -d @- -uadmin:admin -k --silent --max-time 300 --retry 5 --retry-delay 5 ${debug}"
    if [  "${PIPESTATUS[0]}" != 0  ]; then
        common_logger -e "The bongosec-alerts template could not be inserted into the Bongosec indexer cluster."
        exit 1
    else
        common_logger -d "Inserted bongosec-alerts template into the Bongosec indexer cluster."
    fi


}
