# Bongosec installer - variables
# Copyright (C) 2015, Bongosec Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

## Package vars
readonly bongosec_major="5.0"
readonly bongosec_version="5.0.0"
readonly filebeat_version="7.10.2"
readonly bongosec_install_version="0.1"
readonly source_branch="v${bongosec_version}"

## Links and paths to resources
readonly resources="https://${bucket}/${bongosec_major}"
readonly base_url="https://${bucket}/${repository}"
base_path="$(dirname "$(readlink -f "$0")")"
readonly base_path
config_file="${base_path}/config.yml"
readonly tar_file_name="bongosec-install-files.tar"
tar_file="${base_path}/${tar_file_name}"

readonly filebeat_bongosec_template="https://raw.githubusercontent.com/bongosec/bongosec/${source_branch}/extensions/elasticsearch/7.x/bongosec-template.json"

readonly dashboard_cert_path="/etc/bongosec-dashboard/certs"
readonly filebeat_cert_path="/etc/filebeat/certs"
readonly indexer_cert_path="/etc/bongosec-indexer/certs"

readonly logfile="/var/log/bongosec-install.log"
debug=">> ${logfile} 2>&1"
readonly yum_lockfile="/var/run/yum.pid"
readonly apt_lockfile="/var/lib/dpkg/lock"

## Offline Installation vars
readonly base_dest_folder="bongosec-offline"
readonly manager_deb_base_url="${base_url}/apt/pool/main/w/bongosec-manager"
readonly filebeat_deb_base_url="${base_url}/apt/pool/main/f/filebeat"
readonly filebeat_deb_package="filebeat-oss-${filebeat_version}-amd64.deb"
readonly indexer_deb_base_url="${base_url}/apt/pool/main/w/bongosec-indexer"
readonly dashboard_deb_base_url="${base_url}/apt/pool/main/w/bongosec-dashboard"
readonly manager_rpm_base_url="${base_url}/yum"
readonly filebeat_rpm_base_url="${base_url}/yum"
readonly filebeat_rpm_package="filebeat-oss-${filebeat_version}-x86_64.rpm"
readonly indexer_rpm_base_url="${base_url}/yum"
readonly dashboard_rpm_base_url="${base_url}/yum"
readonly bongosec_gpg_key="https://${bucket}/key/GPG-KEY-BONGOSEC"
readonly filebeat_config_file="${resources}/tpl/bongosec/filebeat/filebeat.yml"

adminUser="bongosec"
adminPassword="bongosec"

http_port=443
bongosec_aio_ports=( 9200 9300 1514 1515 1516 55000 "${http_port}")
readonly bongosec_indexer_ports=( 9200 9300 )
readonly bongosec_manager_ports=( 1514 1515 1516 55000 )
bongosec_dashboard_port="${http_port}"
assistant_yum_dependencies=( systemd grep tar coreutils sed procps-ng gawk curl lsof openssl )
readonly assistant_apt_dependencies=( systemd grep tar coreutils sed procps gawk curl lsof openssl )
readonly bongosec_yum_dependencies=( libcap )
readonly bongosec_apt_dependencies=( apt-transport-https libcap2-bin software-properties-common gnupg )
readonly indexer_yum_dependencies=( coreutils )
readonly indexer_apt_dependencies=( debconf adduser procps gnupg apt-transport-https )
readonly dashboard_yum_dependencies=( libcap )
readonly dashboard_apt_dependencies=( debhelper tar curl libcap2-bin gnupg apt-transport-https )
assistant_deps_to_install=()
