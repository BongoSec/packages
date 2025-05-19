#!/bin/bash

bongosec_branch=$1
checksum=$2
revision=$3

bongosec_version=""
splunk_version=""

build_dir="/pkg"
destination_dir="/bongosec_splunk_app"
checksum_dir="/var/local/checksum"
package_json="${build_dir}/package.json"

download_sources() {
    if ! curl -L https://github.com/bongosec/bongosec-splunk/tarball/${bongosec_branch} | tar zx ; then
        echo "Error downloading the source code from GitHub."
        exit 1
    fi
    mv bongosec-* ${build_dir}
    bongosec_version=$(python -c "import json, os; f=open(\""${package_json}"\"); pkg=json.load(f); f.close(); print(pkg[\"version\"])")
    splunk_version=$(python -c "import json, os; f=open(\""${package_json}"\"); pkg=json.load(f); f.close(); print(pkg[\"splunk\"])")}
}

remove_execute_permissions() {
    chmod -R -x+X * ./SplunkAppForBongosec/appserver
}

build_package() {

    download_sources

    cd ${build_dir}

    remove_execute_permissions

    if [ -z ${revision} ]; then
        bongosec_splunk_pkg_name="bongosec_splunk-${bongosec_version}_${splunk_version}.tar.gz"
    else
        bongosec_splunk_pkg_name="bongosec_splunk-${bongosec_version}_${splunk_version}-${revision}.tar.gz"
    fi

    tar -zcf ${bongosec_splunk_pkg_name} SplunkAppForBongosec

    mv ${bongosec_splunk_pkg_name} ${destination_dir}

    if [ ${checksum} = "yes" ]; then
        cd ${destination_dir} && sha512sum "${bongosec_splunk_pkg_name}" > "${checksum_dir}/${bongosec_splunk_pkg_name}".sha512
    fi

    exit 0
}

build_package