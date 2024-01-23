#!/bin/bash

#DEBUG="true"
log="/tmp/wsl-commands.log"

main()
{
    /bin/rm -f "$log"
    info user=$user
    info tmp=$tmp
    info drive=$drive
    info DEBUG=$DEBUG
    info

    #
    # Get windows user and strip domain part
    #
    user="$(/usr/bin/id -u -n 1000)"
    group="$(/usr/bin/id -g -n 1000)"

    info "whoami=$(/bin/whoami)"

    #start services
    /usr/sbin/service cron start
    /usr/sbin/service ssh start

    #
    # A temp folder mounter as a tmpfs ram disk
    #
    tmp="/home/$user/.ssh/tmp"
    tmp="$(/usr/bin/realpath "$tmp" )"

    info user=$user
    info tmp=$tmp
    info drive=$drive
    info DEBUG=$DEBUG
    info

    # create tmp if it doesnt exist, make sure access permissions are correct
    if [ ! -d "$tmp" ]
    then
        info $tmp: not exist
        /bin/mkdir -p "$tmp"
    fi
    /bin/chmod 755 "/home/$user/.ssh"
    /bin/chmod 700 "$tmp"

    # mount tmp folder
    if ! is_mounted "$tmp"
    then
        info mount $tmp
        /bin/mount -t tmpfs -o size=1G none "$tmp"
    fi
    /bin/chmod 700 "$tmp"
    /bin/chown -R ${user}:${group} "/home/$user/.ssh/tmp"

    # make all foder mount points
    for drive in {c..z}
    do
        [ -d "/mnt/$drive" ] || /bin/mkdir "/mnt/$drive"
    done

    unset user tmp drive DEBUG
}


info()
{
    if [ -n "$DEBUG" ]
    then
        if [ $# == 0 ]
        then
            echo >> "$log"
        else
            echo "Info:" "$@" >> "$log"
        fi
    fi
}


is_mounted()
{
    local path="$(/usr/bin/realpath "$1")"
    info 1=$1
    info path=$path
    [ -n "$path" -a "$(/bin/mount | /usr/bin/fgrep " $path " -c)" != 0 ]
}

main "$@"
exit 0

