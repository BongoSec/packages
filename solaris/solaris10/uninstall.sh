#!/bin/sh
# uninstall script for bongosec-agent
# Bongosec, Inc 2015

control_binary="bongosec-control"

if [ ! -f /var/ossec/bin/${control_binary} ]; then
  control_binary="ossec-control"
fi

## Stop and remove application
/var/ossec/bin/${control_binary} stop
rm -rf /var/ossec/

## stop and unload dispatcher
#/bin/launchctl unload /Library/LaunchDaemons/com.bongosec.agent.plist

# remove launchdaemons
rm -f /etc/init.d/bongosec-agent
rm -rf /etc/rc2.d/S97bongosec-agent
rm -rf /etc/rc3.d/S97bongosec-agent

## Remove User and Groups
userdel bongosec 2> /dev/null
groupdel bongosec 2> /dev/null

exit 0
