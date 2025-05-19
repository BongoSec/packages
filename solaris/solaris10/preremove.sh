#!/bin/sh
# preremove script for bongosec-agent
# Bongosec, Inc 2015

control_binary="bongosec-control"

if [ ! -f /var/ossec/bin/${control_binary} ]; then
  control_binary="ossec-control"
fi

/var/ossec/bin/${control_binary} stop
