#!/bin/bash
#
# REF: https://unix.stackexchange.com/questions/230673/how-to-generate-a-random-string
#

host="$1"
user="$2"
password="$(/usr/bin/shuf -er -n20  {A..Z} {a..z} {0..9} | /usr/bin/tr -d '\n')"

if [ -z "$host" -o -z "$user" ]
then
    echo "Usage: $(/usr/bin/basename "$0") <host> <user>

    Change proxmox user password to a random password and returns the new password.
    Also sets user expiry to 1 day

Where:

    host - proxmox host, can include user@host
    user - pve user whose password will change
" > /dev/stderr
else
    echo "$password
$password" | /usr/bin/ssh "$host" /usr/sbin/pveum passwd "$user" 2> /dev/null
    if [ $? == 0 ]
    then
        echo "$password"
        seconds="$(( $(/bin/date "+%s") + 60 ))"
        /usr/bin/ssh "$host" /usr/sbin/pveum user modify "$user" -expire $seconds 2> /dev/null
    else
        echo ""
    fi
fi

