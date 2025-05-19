#!/bin/bash

apiPass="$(cat bongosec-install-files/bongosec-passwords.txt | awk "/username: 'bongosec'/{getline;print;}" | awk '{ print $2 }' | tr -d \' )"
adminPass="$(cat bongosec-install-files/bongosec-passwords.txt | awk "/username: 'admin'/{getline;print;}" | awk '{ print $2 }' | tr -d \')"

if ! bash bongosec-passwords-tool.sh -u wazuuuh | grep "ERROR"; then
   exit 1
elif ! sudo bash bongosec-passwords-tool.sh -u admin -p password | grep "ERROR"; then
   exit 1 
elif ! sudo bash bongosec-passwords-tool.sh -au bongosec -ap "${adminPass}" -u bongosec -p password -A | grep "ERROR"; then
   exit 1
elif ! curl -s -u bongosec:bongosec -k -X POST "https://localhost:55000/security/user/authenticate" | grep "Invalid credentials"; then
   exit 1
elif ! curl -s -u wazuuh:"${apiPass}" -k -X POST "https://localhost:55000/security/user/authenticate" | grep "Invalid credentials"; then
   exit 1
elif ! curl -s -XGET https://localhost:9200/ -u admin:admin -k | grep "Unauthorized"; then
   exit 1
elif ! curl -s -XGET https://localhost:9200/ -u adminnnn:"${adminPass}" -k | grep "Unauthorized"; then
   exit 1
fi
