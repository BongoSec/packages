# Bongosec installer - manager.sh functions.
# Copyright (C) 2015, Bongosec Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

function manager_startCluster() {

    common_logger -d "Starting Bongosec manager cluster."
    for i in "${!server_node_names[@]}"; do
        if [[ "${server_node_names[i]}" == "${winame}" ]]; then
            pos="${i}";
        fi
    done

    for i in "${!server_node_types[@]}"; do
        if [[ "${server_node_types[i],,}" == "master" ]]; then
            master_address=${server_node_ips[i]}
        fi
    done

    key=$(tar -axf "${tar_file}" bongosec-install-files/clusterkey -O)
    bind_address="0.0.0.0"
    port="1516"
    hidden="no"
    disabled="no"
    lstart=$(grep -n "<cluster>" /var/ossec/etc/ossec.conf | cut -d : -f 1)
    lend=$(grep -n "</cluster>" /var/ossec/etc/ossec.conf | cut -d : -f 1)

    eval 'sed -i -e "${lstart},${lend}s/<name>.*<\/name>/<name>bongosec_cluster<\/name>/" \
        -e "${lstart},${lend}s/<node_name>.*<\/node_name>/<node_name>${winame}<\/node_name>/" \
        -e "${lstart},${lend}s/<node_type>.*<\/node_type>/<node_type>${server_node_types[pos],,}<\/node_type>/" \
        -e "${lstart},${lend}s/<key>.*<\/key>/<key>${key}<\/key>/" \
        -e "${lstart},${lend}s/<port>.*<\/port>/<port>${port}<\/port>/" \
        -e "${lstart},${lend}s/<bind_addr>.*<\/bind_addr>/<bind_addr>${bind_address}<\/bind_addr>/" \
        -e "${lstart},${lend}s/<node>.*<\/node>/<node>${master_address}<\/node>/" \
        -e "${lstart},${lend}s/<hidden>.*<\/hidden>/<hidden>${hidden}<\/hidden>/" \
        -e "${lstart},${lend}s/<disabled>.*<\/disabled>/<disabled>${disabled}<\/disabled>/" \
        /var/ossec/etc/ossec.conf'

}

function manager_configure(){

    common_logger -d "Configuring Bongosec manager."

    if [ ${#indexer_node_names[@]} -eq 1 ]; then
        eval "sed -i 's/<host>.*<\/host>/<host>https:\/\/${indexer_node_ips[0]}:9200<\/host>/g' /var/ossec/etc/ossec.conf ${debug}"
    else
        lstart=$(grep -n "<hosts>" /var/ossec/etc/ossec.conf | cut -d : -f 1)
        lend=$(grep -n "</hosts>" /var/ossec/etc/ossec.conf | cut -d : -f 1)
        for i in "${!indexer_node_ips[@]}"; do
            if [ $i -eq 0 ]; then
                eval "sed -i 's/<host>.*<\/host>/<host>https:\/\/${indexer_node_ips[0]}:9200<\/host>/g' /var/ossec/etc/ossec.conf ${debug}"
            else
                eval "sed -i '/<hosts>/a\      <host>https:\/\/${indexer_node_ips[$i]}:9200<\/host>' /var/ossec/etc/ossec.conf"
            fi
        done
    fi
    eval "sed -i s/filebeat.pem/${server_node_names[0]}.pem/ /var/ossec/etc/ossec.conf ${debug}"
    eval "sed -i s/filebeat-key.pem/${server_node_names[0]}-key.pem/ /var/ossec/etc/ossec.conf ${debug}"
    common_logger -d "Setting provisional Bongosec indexer password."
    eval "/var/ossec/bin/bongosec-keystore -f indexer -k username -v admin"
    eval "/var/ossec/bin/bongosec-keystore -f indexer -k password -v admin"  
    common_logger "Bongosec manager vulnerability detection configuration finished."
}

function manager_install() {

    common_logger "Starting the Bongosec manager installation."
    if [ "${sys_type}" == "yum" ]; then
        installCommon_yumInstall "bongosec-manager" "${bongosec_version}-*"
    elif [ "${sys_type}" == "apt-get" ]; then
        installCommon_aptInstall "bongosec-manager" "${bongosec_version}-*"
    fi

    common_checkInstalled
    if [  "$install_result" != 0  ] || [ -z "${bongosec_installed}" ]; then
        common_logger -e "Bongosec installation failed."
        installCommon_rollBack
        exit 1
    else
        common_logger "Bongosec manager installation finished."
    fi
}
