#!/bin/bash

set -x

# Bongosec package builder
# Copyright (C) 2021, Bongosec Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

set -e

# Script parameters to build the package
target="bongosec-indexer"
architecture=$1
revision=$2
future=$3
reference=$4
directory_base="/usr/share/bongosec-indexer"

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
    cp ./bongosec*/stack/indexer/rpm/${target}.spec ${rpm_build_dir}/SPECS/${pkg_name}.spec
    cp -r ./bongosec*/* /root/
else
    cp /root/stack/indexer/rpm/${target}.spec ${rpm_build_dir}/SPECS/${pkg_name}.spec
fi

# Generating source tar.gz
cd ${build_dir} && tar czf "${rpm_build_dir}/SOURCES/${pkg_name}.tar.gz" "${pkg_name}"

# Building RPM
/usr/bin/rpmbuild --define "_topdir ${rpm_build_dir}" --define "_version ${version}" \
    --define "_release ${revision}" --define "_localstatedir ${directory_base}" \
    --target ${architecture} -ba ${rpm_build_dir}/SPECS/${pkg_name}.spec

cd ${pkg_path} && sha512sum ${rpm_file} > /tmp/${rpm_file}.sha512


find ${pkg_path}/ -maxdepth 3 -type f -name "${file_name}*" -exec mv {} /tmp/ \;
