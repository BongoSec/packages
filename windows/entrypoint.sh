#! /bin/bash

set -ex

BRANCH=$1
JOBS=$2
DEBUG=$3
REVISION=$4
TRUST_VERIFICATION=$5
CA_NAME=$6
ZIP_NAME="windows_agent_${REVISION}.zip"

URL_REPO=https://github.com/bongosec/bongosec/archive/${BRANCH}.zip

# Download the bongosec repository
wget -O bongosec.zip ${URL_REPO} && unzip bongosec.zip

# Compile the bongosec agent for Windows
FLAGS="-j ${JOBS} IMAGE_TRUST_CHECKS=${TRUST_VERIFICATION} CA_NAME=\"${CA_NAME}\" "

if [[ "${DEBUG}" = "yes" ]]; then
    FLAGS+="-d "
fi

bash -c "make -C /bongosec-*/src deps TARGET=winagent ${FLAGS}"
bash -c "make -C /bongosec-*/src TARGET=winagent ${FLAGS}"

rm -rf /bongosec-*/src/external

# Zip the compiled agent and move it to the shared folder
zip -r ${ZIP_NAME} bongosec-*
cp ${ZIP_NAME} /shared
