#!/bin/bash

function check_package() {

    if [ "${sys_type}" == "deb" ]; then
        if ! apt list --installed 2>/dev/null | grep -q "${1}"; then
            echo "INFO: The package "${1}" is not installed."
            return 1
        fi
    elif [ "${sys_type}" == "rpm" ]; then
        if ! yum list installed 2>/dev/null | grep -q "${1}"; then
            echo "INFO: The package "${1}" is not installed."
            return 1
        fi
    fi
    return 0

}

function check_system() {

    if [ -n "$(command -v yum)" ]; then
        sys_type="rpm"
        echo "INFO: RPM system detected."
    elif [ -n "$(command -v apt-get)" ]; then
        sys_type="deb"
        echo "INFO: DEB system detected."
    else
        echo "ERROR: could not detect the system."
        exit 1
    fi

}

function check_file() {

    if [ ! -f "${1}" ]; then
        echo "ERROR: The ${1} file could not be downloaded."
        exit 1
    fi

}

function check_shards() {

    retries=0
    until [ "$(curl -s -k -u admin:admin "https://127.0.0.1:9200/_template/bongosec?pretty&filter_path=bongosec.settings.index.number_of_shards" | grep "number_of_shards")" ] || [ "${retries}" -eq 5 ]; do
        sleep 5
        retries=$((retries+1))
    done

    if [ ${retries} -eq 5 ]; then
        echo "ERROR: Could not get the number of shards."
        exit 1
    fi
    curl -s -k -u admin:admin "https://127.0.0.1:9200/_template/bongosec?pretty&filter_path=bongosec.settings.index.number_of_shards"
    echo "INFO: Number of shards detected."

}

function dashboard_installation() {

    install_package "bongosec-dashboard"
    check_package "bongosec-dashboard"

    echo "INFO: Generating certificates of the Bongosec dashboard..."
    NODE_NAME=dashboard
    mkdir /etc/bongosec-dashboard/certs
    mv -n bongosec-certificates/$NODE_NAME.pem /etc/bongosec-dashboard/certs/dashboard.pem
    mv -n bongosec-certificates/$NODE_NAME-key.pem /etc/bongosec-dashboard/certs/dashboard-key.pem
    cp bongosec-certificates/root-ca.pem /etc/bongosec-dashboard/certs/
    chmod 500 /etc/bongosec-dashboard/certs
    chmod 400 /etc/bongosec-dashboard/certs/*
    chown -R bongosec-dashboard:bongosec-dashboard /etc/bongosec-dashboard/certs

    if [ "${sys_type}" == "deb" ]; then
        enable_start_service "bongosec-dashboard"
    elif [ "${sys_type}" == "rpm" ]; then
        /usr/share/bongosec-dashboard/bin/opensearch-dashboards "-c /etc/bongosec-dashboard/opensearch_dashboards.yml" --allow-root > /dev/null 2>&1 &
    fi

    retries=0
    # In this context, 302 HTTP code refers to SSL certificates warning: success.
    until [ "$(curl -k -s -I -w "%{http_code}" https://127.0.0.1 -o /dev/null --fail)" -ne "302" ] || [ "${retries}" -eq 5 ]; do
        echo "INFO: Sleeping 10 seconds."
        sleep 10
        retries=$((retries+1))
    done
    if [ ${retries} -eq 5 ]; then
        echo "ERROR: The Bongosec dashboard installation has failed."
        exit 1
    else
        echo "INFO: The Bongosec dashboard is ready."
    fi

}

function download_resources() {

    check_file "${ABSOLUTE_PATH}"/bongosec-install.sh
    bash "${ABSOLUTE_PATH}"/bongosec-install.sh -dw "${sys_type}"
    echo "INFO: Downloading the resources..."

    curl -sO https://bongosec.github.io/packages/4.3/config.yml
    check_file "config.yml"

    sed -i -e '0,/<indexer-node-ip>/ s/<indexer-node-ip>/127.0.0.1/' config.yml
    sed -i -e '0,/<bongosec-manager-ip>/ s/<bongosec-manager-ip>/127.0.0.1/' config.yml
    sed -i -e '0,/<dashboard-node-ip>/ s/<dashboard-node-ip>/127.0.0.1/' config.yml

    curl -sO https://bongosec.github.io/packages/4.3/bongosec-certs-tool.sh
    check_file "bongosec-certs-tool.sh"
    chmod 744 bongosec-certs-tool.sh
    ./bongosec-certs-tool.sh --all

    tar xf bongosec-offline.tar.gz
    echo "INFO: Download finished."

    if [ ! -d ./bongosec-offline ]; then
        echo "ERROR: Could not download the resources."
        exit 1
    fi

}

function enable_start_service() {

    systemctl daemon-reload
    systemctl enable "${1}"
    systemctl start "${1}"

    retries=0
    until [ "$(systemctl status "${1}" | grep "active")" ] || [ "${retries}" -eq 3 ]; do
        sleep 2
        retries=$((retries+1))
        systemctl start "${1}"
    done

    if [ ${retries} -eq 3 ]; then
        echo "ERROR: The "${1}" service could not be started."
        exit 1
    fi

}

function filebeat_installation() {

    install_package "filebeat"
    check_package "filebeat"

    cp ./bongosec-offline/bongosec-files/filebeat.yml /etc/filebeat/ &&\
    cp ./bongosec-offline/bongosec-files/bongosec-template.json /etc/filebeat/ &&\
    chmod go+r /etc/filebeat/bongosec-template.json

    sed -i 's|\("index.number_of_shards": \)".*"|\1 "1"|' /etc/filebeat/bongosec-template.json
    filebeat keystore create
    echo admin | filebeat keystore add username --stdin --force
    echo admin | filebeat keystore add password --stdin --force
    tar -xzf ./bongosec-offline/bongosec-files/bongosec-filebeat-0.4.tar.gz -C /usr/share/filebeat/module

    echo "INFO: Generating certificates of Filebeat..."
    NODE_NAME=bongosec-1
    mkdir /etc/filebeat/certs
    mv -n bongosec-certificates/$NODE_NAME.pem /etc/filebeat/certs/filebeat.pem
    mv -n bongosec-certificates/$NODE_NAME-key.pem /etc/filebeat/certs/filebeat-key.pem
    cp bongosec-certificates/root-ca.pem /etc/filebeat/certs/
    chmod 500 /etc/filebeat/certs
    chmod 400 /etc/filebeat/certs/*
    chown -R root:root /etc/filebeat/certs

    if [ "${sys_type}" == "deb" ]; then
        enable_start_service "filebeat"
    elif [ "${sys_type}" == "rpm" ]; then
        /usr/share/filebeat/bin/filebeat --environment systemd -c /etc/filebeat/filebeat.yml --path.home /usr/share/filebeat --path.config /etc/filebeat --path.data /var/lib/filebeat --path.logs /var/log/filebeat &
    fi

    sleep 10
    check_shards
    eval "filebeat test output"
    if [ "${PIPESTATUS[0]}" != 0 ]; then
        echo "ERROR: The Filebeat installation has failed."
        exit 1
    fi

}

function indexer_initialize() {

    retries=0
    until [ "$(cat /var/log/bongosec-indexer/bongosec-cluster.log | grep "Node started")" ] || [ "${retries}" -eq 5 ]; do
        sleep 5
        retries=$((retries+1))
    done

    if [ ${retries} -eq 5 ]; then
        echo "ERROR: The indexer node is not started."
        exit 1
    fi
    /usr/share/bongosec-indexer/bin/indexer-security-init.sh

}

function indexer_installation() {

    if [ "${sys_type}" == "rpm" ]; then
        rpm --import ./bongosec-offline/bongosec-files/GPG-KEY-BONGOSEC
    fi

    install_package "bongosec-indexer"
    check_package "bongosec-indexer"

    echo "INFO: Generating certificates of the Bongosec indexer..."
    NODE_NAME=node-1
    mkdir /etc/bongosec-indexer/certs
    mv -n bongosec-certificates/$NODE_NAME.pem /etc/bongosec-indexer/certs/indexer.pem
    mv -n bongosec-certificates/$NODE_NAME-key.pem /etc/bongosec-indexer/certs/indexer-key.pem
    mv bongosec-certificates/admin-key.pem /etc/bongosec-indexer/certs/
    mv bongosec-certificates/admin.pem /etc/bongosec-indexer/certs/
    cp bongosec-certificates/root-ca.pem /etc/bongosec-indexer/certs/
    chmod 500 /etc/bongosec-indexer/certs
    chmod 400 /etc/bongosec-indexer/certs/*
    chown -R bongosec-indexer:bongosec-indexer /etc/bongosec-indexer/certs

    sed -i 's|\(network.host: \)"0.0.0.0"|\1"127.0.0.1"|' /etc/bongosec-indexer/opensearch.yml

    if [ "${sys_type}" == "rpm" ]; then
        runuser "bongosec-indexer" --shell="/bin/bash" --command="OPENSEARCH_PATH_CONF=/etc/bongosec-indexer /usr/share/bongosec-indexer/bin/opensearch" > /dev/null 2>&1 &
        sleep 5
    elif [ "${sys_type}" == "deb" ]; then
        enable_start_service "bongosec-indexer"
    fi

    indexer_initialize
    sleep 10
    eval "curl -s -XGET https://127.0.0.1:9200 -u admin:admin -k --fail"
    if [ "${PIPESTATUS[0]}" != 0 ]; then
        echo "ERROR: The Bongosec indexer installation has failed."
        exit 1
    fi

}

function install_dependencies() {

    if [ "${sys_type}" == "rpm" ]; then
        dependencies=( util-linux initscripts openssl )
        not_installed=()
        for dep in "${dependencies[@]}"; do
            if [ "${dep}" == "openssl" ]; then
                if ! yum list installed 2>/dev/null | grep -q "${dep}\.";then
                    not_installed+=("${dep}")
                fi
            elif ! yum list installed 2>/dev/null | grep -q "${dep}";then
                not_installed+=("${dep}")
            fi
        done

        if [ "${#not_installed[@]}" -gt 0 ]; then
            echo "--- Dependencies ---"
            for dep in "${not_installed[@]}"; do
                echo "Installing $dep."
                eval "yum install ${dep} -y"
                if [  "${PIPESTATUS[0]}" != 0  ]; then
                    echo "ERROR: Cannot install dependency: ${dep}."
                    exit 1
                fi
            done
        fi

    elif [ "${sys_type}" == "deb" ]; then
        eval "apt-get update -q > /dev/null"
        dependencies=( openssl )
        not_installed=()

        for dep in "${dependencies[@]}"; do
            if ! apt list --installed 2>/dev/null | grep -q "${dep}"; then
                not_installed+=("${dep}")
            fi
        done

        if [ "${#not_installed[@]}" -gt 0 ]; then
            echo "--- Dependencies ----"
            for dep in "${not_installed[@]}"; do
                echo "Installing $dep."
                apt-get install -y "${dep}"
                if [ "${install_result}" != 0 ]; then
                    echo "ERROR: Cannot install dependency: ${dep}."
                    exit 1
                fi
            done
        fi
    fi

}

function install_package() {

    if [ "${sys_type}" == "deb" ]; then
        dpkg -i ./bongosec-offline/packages/"${1}"*.deb
    elif [ "${sys_type}" == "rpm" ]; then
        rpm -ivh ./bongosec-offline/packages/"${1}"*.rpm
    fi

}

function manager_installation() {

    install_package "bongosec-manager"
    check_package "bongosec-manager"

    if [ "${sys_type}" == "deb" ]; then
        enable_start_service "bongosec-manager"
    elif [ "${sys_type}" == "rpm" ]; then
        /var/ossec/bin/bongosec-control start
    fi

}
