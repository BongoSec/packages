#!/bin/bash
set -e

bongosec_branch=$1

download_sources() {
    if ! curl -L https://github.com/bongosec/bongosec-puppet/tarball/${bongosec_branch} | tar zx ; then
        echo "Error downloading the source code from GitHub."
        exit 1
    fi
    cd bongosec-*
}

build_module() {

    download_sources

    pdk build --force --target-dir=/tmp/output/

    exit 0
}

build_module
