#!/bin/bash

# Bongosec package builder
# Copyright (C) 2021, Bongosec Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

set -e
# Script parameters to build the package
target="bongosec-dashboard"
architecture=$1
revision=$2
future=$3
plugin_main=$4
plugin_updates=$5
plugin_core=$6
reference=$7
directory_base="/usr/share/bongosec-dashboard"

if [ -z "${revision}" ]; then
    revision="1"
fi

if [ "${future}" = "yes" ];then
    version="99.99.0"
else
    if [ "${reference}" ];then
        version=$(curl -sL https://raw.githubusercontent.com/bongosec/packages/${reference}/VERSION | cat)
    else
        version=$(cat /root/VERSION)
    fi
fi

if [ "${plugin_main}" ] && [ "${plugin_updates}" ] && [ "${plugin_core}" ] ;then
    valid_url='(https?|ftp|file)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'
    if [[ "${plugin_main}" =~ $valid_url ]];then
        url_main="${plugin_main}"
        if ! curl --output /dev/null --silent --head --fail "${url_main}"; then
            echo "The given URL to download the Bongosec main plugin ZIP does not exist: ${url_main}"
            exit 1
        fi
    else
        url_main="https://packages-dev.bongosec.com/${app_url}/ui/dashboard/bongosec-${version}-${revision}.zip"
    fi
    if [[ "${plugin_updates}" =~ $valid_url ]];then
        url_updates="${plugin_updates}"
        if ! curl --output /dev/null --silent --head --fail "${url_updates}"; then
            echo "The given URL to download the Bongosec Check Updates plugin ZIP does not exist: ${url_updates}"
            exit 1
        fi
    else
        url_updates="https://packages-dev.bongosec.com/${app_url}/ui/dashboard/bongosecCheckUpdates-${version}-${revision}.zip"
    fi
    if [[ "${plugin_core}" =~ $valid_url ]];then
        url_core="${plugin_core}"
        if ! curl --output /dev/null --silent --head --fail "${url_core}"; then
            echo "The given URL to download the Bongosec Core plugin ZIP does not exist: ${url_core}"
            exit 1
        fi
    else
        url_core="https://packages-dev.bongosec.com/${app_url}/ui/dashboard/bongosecCore-${version}-${revision}.zip"
    fi
else
    url_main="https://packages-dev.bongosec.com/pre-release/ui/dashboard/bongosec-${version}-${revision}.zip"
    url_updates="https://packages-dev.bongosec.com/pre-release/ui/dashboard/bongosecCheckUpdates-${version}-${revision}.zip"
    url_core="https://packages-dev.bongosec.com/pre-release/ui/dashboard/bongosecCore-${version}-${revision}.zip"
fi

# Build directories
build_dir=/build
rpm_build_dir=${build_dir}/rpmbuild
file_name="${target}-${version}-${revision}"
pkg_path="${rpm_build_dir}/RPMS/${architecture}"
rpm_file="${file_name}.${architecture}.rpm"
mkdir -p ${rpm_build_dir}/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}

# Prepare the sources directory to build the source tar.gz
pkg_name=${target}-${version}
mkdir ${build_dir}/${pkg_name}

# Including spec file
if [ "${reference}" ];then
    curl -sL https://github.com/bongosec/packages/tarball/${reference} | tar zx
    cp ./bongosec*/stack/dashboard/rpm/${target}.spec ${rpm_build_dir}/SPECS/${pkg_name}.spec
    cp -r ./bongosec*/* /root/
else
    cp /root/stack/dashboard/rpm/${target}.spec ${rpm_build_dir}/SPECS/${pkg_name}.spec
fi

# Generating source tar.gz
cd ${build_dir} && tar czf "${rpm_build_dir}/SOURCES/${pkg_name}.tar.gz" "${pkg_name}"

# Building RPM
/usr/bin/rpmbuild --define "_topdir ${rpm_build_dir}" --define "_version ${version}" \
    --define "_release ${revision}" --define "_localstatedir ${directory_base}" \
    --define "_url_plugin_main ${url_main}" --define "_url_plugin_updates ${url_updates}" --define "_url_plugin_core ${url_core}" \
    --target ${architecture} -ba ${rpm_build_dir}/SPECS/${pkg_name}.spec

cd ${pkg_path} && sha512sum ${rpm_file} > /tmp/${rpm_file}.sha512

find ${pkg_path}/ -maxdepth 3 -type f -name "${file_name}*" -exec mv {} /tmp/ \;
