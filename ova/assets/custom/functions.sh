function installCommon_changePasswords() {

    common_logger -d "Setting Bongosec indexer cluster passwords."
    if [ -f "${tar_file}" ]; then
        eval "tar -xf ${tar_file} -C /tmp bongosec-install-files/bongosec-passwords.txt ${debug}"
        p_file="/tmp/bongosec-install-files/bongosec-passwords.txt"
        common_checkInstalled
        if [ -n "${start_indexer_cluster}" ] || [ -n "${AIO}" ]; then
            changeall=1
            passwords_readUsers
        fi
        installCommon_readPasswordFileUsers
    else
        common_logger -e "Cannot find passwords file. Exiting"
        exit 1
    fi
    if [ -n "${start_indexer_cluster}" ] || [ -n "${AIO}" ]; then
        passwords_getNetworkHost
        passwords_createBackUp
        passwords_generateHash
    fi

    passwords_changePassword

    if [ -n "${start_indexer_cluster}" ] || [ -n "${AIO}" ]; then
        passwords_runSecurityAdmin
    fi

}