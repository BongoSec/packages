#!/bin/sh
# uninstall script for bongosec-agent
# Bongosec, Inc 2015

install_path=$1
control_binary=$2

## Stop and remove application
${install_path}/bin/${control_binary} stop
rm -r /var/ossec*

# remove launchdaemons
rm -f /etc/init.d/bongosec-agent

## Remove User and Groups
userdel bongosec
groupdel bongosec

exit 0
