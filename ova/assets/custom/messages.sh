#!/bin/sh

DEBUG=$1
BONGOSEC_VERSION=$2
SYSTEM_USER=$3

[[ ${DEBUG} = "yes" ]] && set -ex || set -e

# OVA Welcome message
cat > /etc/issue <<EOF

Welcome to the Bongosec OVA version
Bongosec - ${BONGOSEC_VERSION}
Login credentials:
  User: ${SYSTEM_USER}
  Password: bongosec

EOF

# User Welcome message
cat > /etc/update-motd.d/30-banner <<EOF

#!/bin/sh
cat << EOF
wwwwww.           wwwwwww.          wwwwwww.
wwwwwww.          wwwwwww.          wwwwwww.
 wwwwww.         wwwwwwwww.        wwwwwww.
 wwwwwww.        wwwwwwwww.        wwwwwww.
  wwwwww.       wwwwwwwwwww.      wwwwwww.
  wwwwwww.      wwwwwwwwwww.      wwwwwww.
   wwwwww.     wwwwww.wwwwww.    wwwwwww.
   wwwwwww.    wwwww. wwwwww.    wwwwwww.
    wwwwww.   wwwwww.  wwwwww.  wwwwwww.
    wwwwwww.  wwwww.   wwwwww.  wwwwwww.
     wwwwww. wwwwww.    wwwwww.wwwwwww.
     wwwwwww.wwwww.     wwwwww.wwwwwww.
      wwwwwwwwwwww.      wwwwwwwwwwww.
      wwwwwwwwwww.       wwwwwwwwwwww.      oooooo
       wwwwwwwwww.        wwwwwwwwww.      oooooooo
       wwwwwwwww.         wwwwwwwwww.     oooooooooo
        wwwwwwww.          wwwwwwww.      oooooooooo
        wwwwwww.           wwwwwwww.       oooooooo
         wwwwww.            wwwwww.         oooooo


         BONGOSEC Open Source Security Platform
                  https://bongosec.com


EOF
