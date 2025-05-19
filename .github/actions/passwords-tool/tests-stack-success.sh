#!/bin/bash

users=( admin kibanaserver kibanaro logstash readall snapshotrestore )
api_users=( bongosec bongosec-wui )

echo '::group:: Change indexer password, password providing it.'

bash bongosec-passwords-tool.sh -u admin -p LN*X1v.VNtCZ5sESEtLfijPAd39LXGAI
if curl -s -XGET https://localhost:9200/ -u admin:LN*X1v.VNtCZ5sESEtLfijPAd39LXGAI -k -w %{http_code} | grep "401"; then
    exit 1
fi
echo '::endgroup::'

echo '::group:: Change indexer password without providing it.'

indx_pass="$(bash bongosec-passwords-tool.sh -u admin | awk '/admin/{ print $NF }' | tr -d \' )"
if curl -s -XGET https://localhost:9200/ -u admin:"${indx_pass}" -k -w %{http_code} | grep "401"; then
    exit 1
fi

echo '::endgroup::'

echo '::group:: Change all passwords except Bongosec API ones.'

mapfile -t pass < <(bash bongosec-passwords-tool.sh -a | grep 'The password for' | awk '{ print $NF }')
for i in "${!users[@]}"; do
    if curl -s -XGET https://localhost:9200/ -u "${users[i]}":"${pass[i]}" -k -w %{http_code} | grep "401"; then
        exit 1
    fi
done

echo '::endgroup::'

echo '::group:: Change all passwords.'

bongosec_pass="$(cat bongosec-install-files/bongosec-passwords.txt | awk "/username: 'bongosec'/{getline;print;}" | awk '{ print $2 }' | tr -d \' )"

mapfile -t passall < <(bash bongosec-passwords-tool.sh -a -au bongosec -ap "${bongosec_pass}" | grep 'The password for' | awk '{ print $NF }' ) 
passindexer=("${passall[@]:0:6}")
passapi=("${passall[@]:(-2)}")

for i in "${!users[@]}"; do
    if curl -s -XGET https://localhost:9200/ -u "${users[i]}":"${passindexer[i]}" -k -w %{http_code} | grep "401"; then
        exit 1
    fi
done

for i in "${!api_users[@]}"; do
    if curl -s -u "${api_users[i]}":"${passapi[i]}" -w "%{http_code}" -k -X POST "https://localhost:55000/security/user/authenticate" | grep "401"; then
        exit 1
    fi
done

echo '::endgroup::'

echo '::group:: Change single Bongosec API user.'

bash bongosec-passwords-tool.sh -au bongosec -ap "${passapi[0]}" -u bongosec -p BkJt92r*ndzN.CkCYWn?d7i5Z7EaUt63 -A 
    if curl -s -w "%{http_code}" -u bongosec:BkJt92r*ndzN.CkCYWn?d7i5Z7EaUt63 -k -X POST "https://localhost:55000/security/user/authenticate" | grep "401"; then
        exit 1
    fi
echo '::endgroup::'

echo '::group:: Change all passwords except Bongosec API ones using a file.'

mapfile -t passfile < <(bash bongosec-passwords-tool.sh -f bongosec-install-files/bongosec-passwords.txt | grep 'The password for' | awk '{ print $NF }' ) 
for i in "${!users[@]}"; do
    if curl -s -XGET https://localhost:9200/ -u "${users[i]}":"${passfile[i]}" -k -w %{http_code} | grep "401"; then
        exit 1
    fi
done
echo '::endgroup::'

echo '::group:: Change all passwords from a file.'
mapfile -t passallf < <(bash bongosec-passwords-tool.sh -f bongosec-install-files/bongosec-passwords.txt -au bongosec -ap BkJt92r*ndzN.CkCYWn?d7i5Z7EaUt63 | grep 'The password for' | awk '{ print $NF }' )
passindexerf=("${passallf[@]:0:6}")
passapif=("${passallf[@]:(-2)}")

for i in "${!users[@]}"; do
    if curl -s -XGET https://localhost:9200/ -u "${users[i]}":"${passindexerf[i]}" -k -w %{http_code} | grep "401"; then
        exit 1
    fi
done

for i in "${!api_users[@]}"; do
    if curl -s -u "${api_users[i]}":"${passapif[i]}" -w "%{http_code}" -k -X POST "https://localhost:55000/security/user/authenticate" | grep "401"; then
        exit 1
    fi
done

echo '::endgroup::'
