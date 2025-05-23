#! /bin/bash
# By Spransy, Derek" <DSPRANS () emory ! edu> and Charlie Scott
# Modified by Bongosec, Inc. <info@bongosec.com>.
# This program is a free software; you can redistribute it and/or modify it under the terms of GPLv2

#####
# This checks for an error and exits with a custom message
# Returns zero on success
# $1 is the message
# $2 is the error code

DIR="/Library/Ossec"

if [ -d "${DIR}" ]; then
    if [ -f "${DIR}/BONGOSEC_PKG_UPGRADE" ]; then
        rm -f "${DIR}/BONGOSEC_PKG_UPGRADE"
    fi
    if [ -f "${DIR}/BONGOSEC_RESTART" ]; then
        rm -f "${DIR}/BONGOSEC_RESTART"
    fi
    touch "${DIR}/BONGOSEC_PKG_UPGRADE"
    upgrade="true"
    if ${DIR}/bin/bongosec-control status | grep "is running" > /dev/null 2>&1; then
        touch "${DIR}/BONGOSEC_RESTART"
        restart="true"
    elif ${DIR}/bin/ossec-control status | grep "is running" > /dev/null 2>&1; then
        touch "${DIR}/BONGOSEC_RESTART"
        restart="true"
    fi
fi

# Stops the agent before upgrading it
if [ -f ${DIR}/bin/bongosec-control ]; then
    ${DIR}/bin/bongosec-control stop
elif [ -f ${DIR}/bin/ossec-control ]; then
    ${DIR}/bin/ossec-control stop
fi

if [ -n "${upgrade}" ]; then
    mkdir -p ${DIR}/config_files/
    cp -r ${DIR}/etc/{ossec.conf,client.keys,local_internal_options.conf,shared} ${DIR}/config_files/

    if [ -d ${DIR}/logs/ossec ]; then
        mv ${DIR}/logs/ossec ${DIR}/logs/bongosec
    fi
    
    if [ -d ${DIR}/queue/ossec ]; then
        mv ${DIR}/queue/ossec ${DIR}/queue/sockets
    fi
fi

if [ -n "${upgrade}" ]; then
    if pkgutil --pkgs | grep -i bongosec-agent-etc > /dev/null 2>&1 ; then
        pkgutil --forget com.bongosec.pkg.bongosec-agent-etc
    fi
fi

if [[ ! -f "/usr/bin/dscl" ]]
    then
    echo "Error: I couldn't find dscl, dying here";
    exit
fi

DSCL="/usr/bin/dscl";

function check_errm
{
    if  [[ ${?} != "0" ]]
        then
        echo "${1}";
        exit ${2};
        fi
}

# get unique id numbers (uid, gid) that are greater than 100
unset -v i new_uid new_gid idvar;
declare -i new_uid=0 new_gid=0 i=100 idvar=0;
while [[ $idvar -eq 0 ]]; do
    i=$[i+1]
    if [[ -z "$(/usr/bin/dscl . -search /Users uid ${i})" ]] && [[ -z "$(/usr/bin/dscl . -search /Groups gid ${i})" ]];
        then
        new_uid=$i
        new_gid=$i
        idvar=1
        #break
   fi
done

echo "UID available for bongosec user is:";
echo ${new_uid}

# Verify that the uid and gid exist and match
if [[ $new_uid -eq 0 ]] || [[ $new_gid -eq 0 ]];
    then
    echo "Getting unique id numbers (uid, gid) failed!";
    exit 1;
fi
if [[ ${new_uid} != ${new_gid} ]]
    then
    echo "I failed to find matching free uid and gid!";
    exit 5;
fi

# Stops the agent before upgrading it
if [ -f ${DIR}/bin/bongosec-control ]; then
    ${DIR}/bin/bongosec-control stop
elif [ -f ${DIR}/bin/ossec-control ]; then
    ${DIR}/bin/ossec-control stop
fi

# Creating the group
if [[ $(dscl . -read /Groups/bongosec) ]]
    then
    echo "bongosec group already exists.";
else
    sudo ${DSCL} localhost -create /Local/Default/Groups/bongosec
    check_errm "Error creating group bongosec" "67"
    sudo ${DSCL} localhost -createprop /Local/Default/Groups/bongosec PrimaryGroupID ${new_gid}
    sudo ${DSCL} localhost -createprop /Local/Default/Groups/bongosec RealName bongosec
    sudo ${DSCL} localhost -createprop /Local/Default/Groups/bongosec RecordName bongosec
    sudo ${DSCL} localhost -createprop /Local/Default/Groups/bongosec RecordType: dsRecTypeStandard:Groups
    sudo ${DSCL} localhost -createprop /Local/Default/Groups/bongosec Password "*"
fi

# Creating the user
if [[ $(dscl . -read /Users/bongosec) ]]
    then
    echo "bongosec user already exists.";
else
    sudo ${DSCL} localhost -create /Local/Default/Users/bongosec
    check_errm "Error creating user bongosec" "77"
    sudo ${DSCL} localhost -createprop /Local/Default/Users/bongosec RecordName bongosec
    sudo ${DSCL} localhost -createprop /Local/Default/Users/bongosec RealName bongosec
    sudo ${DSCL} localhost -createprop /Local/Default/Users/bongosec UserShell /usr/bin/false
    sudo ${DSCL} localhost -createprop /Local/Default/Users/bongosec NFSHomeDirectory /var/bongosec
    sudo ${DSCL} localhost -createprop /Local/Default/Users/bongosec UniqueID ${new_uid}
    sudo ${DSCL} localhost -createprop /Local/Default/Users/bongosec PrimaryGroupID ${new_gid}
    sudo ${DSCL} localhost -append /Local/Default/Groups/bongosec GroupMembership bongosec
    sudo ${DSCL} localhost -createprop /Local/Default/Users/bongosec Password "*"
fi

#Hide the fixed users
dscl . create /Users/bongosec IsHidden 1