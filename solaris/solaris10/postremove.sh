#!/bin/sh
# postremove script for bongosec-agent
# Bongosec, Inc 2015

if getent passwd bongosec > /dev/null 2>&1; then
  userdel bongosec
fi

if getent group bongosec > /dev/null 2>&1; then
  groupdel bongosec
fi
