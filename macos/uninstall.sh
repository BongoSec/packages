#!/bin/sh

## Stop and remove application
sudo /Library/Ossec/bin/bongosec-control stop
sudo /bin/rm -r /Library/Ossec*

## stop and unload dispatcher
/bin/launchctl unload /Library/LaunchDaemons/com.bongosec.agent.plist

# remove launchdaemons
/bin/rm -f /Library/LaunchDaemons/com.bongosec.agent.plist

## remove StartupItems
/bin/rm -rf /Library/StartupItems/BONGOSEC

## Remove User and Groups
/usr/bin/dscl . -delete "/Users/bongosec"
/usr/bin/dscl . -delete "/Groups/bongosec"

/usr/sbin/pkgutil --forget com.bongosec.pkg.bongosec-agent
/usr/sbin/pkgutil --forget com.bongosec.pkg.bongosec-agent-etc

# In case it was installed via Puppet pkgdmg provider

if [ -e /var/db/.puppet_pkgdmg_installed_bongosec-agent ]; then
    rm -f /var/db/.puppet_pkgdmg_installed_bongosec-agent
fi

echo
echo "Bongosec agent correctly removed from the system."
echo

exit 0
