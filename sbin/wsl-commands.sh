#!/bin/bash

DEBUG="true"
log="/var/log/wsl-commands.log"

main()
{
    #
    # Get windows user and strip domain part
    #
    user="$(/usr/bin/id -u -n 1000)"
    group="$(/usr/bin/id -g -n 1000)"
    prog="$(/bin/basename "$0")"

    info user=$user
    info tmp=$tmp
    info drive=$drive
    info DEBUG=$DEBUG
    info

    info "whoami=$(/bin/whoami)"

    is_mounted "/home/$user"            || /bin/mount --bind "/mnt/c/Users/$user" "/home/$user"
    is_mounted "/home/$user/.gnupg.win" || /bin/mount --bind "/mnt/c/Users/$user/AppData/Roaming/gnupg" "/home/$user/.gnupg.win"

    # update dns first before doing anithing else
    "$(/bin/dirname "$0")/wsl-crontab-commands.sh"

    #start services
    /usr/sbin/service cron start
    /usr/sbin/service ssh start

    #
    # A temp folder mounter as a tmpfs ram disk
    #
    tmp="/home/$user/.ssh/tmp"
    tmp="$(/usr/bin/realpath "$tmp" )"

    info
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
        /bin/mount -t tmpfs -o users,size=1G none "$tmp"
    fi
    /bin/chmod 700 "$tmp"
    /bin/chown -R ${user}:${group} "/home/$user/.ssh/tmp"
    info

    # make all foder mount points
    for drive in {c..z}
    do
        [ -d "/mnt/$drive" ] || /bin/mkdir "/mnt/$drive"
        is_mounted "/mnt/$drive" || /bin/mount -t drvfs -o users "${drive}:" "/mnt/$drive" > /dev/null 2>&1
        info
    done

    info "do mount -a"
    /bin/mount -a

    info
    info "all done."

    unset user tmp drive DEBUG dns
}


info()
{
    if [ -n "$DEBUG" ]
    then
        if [ $# == 0 ]
        then
            echo >> "$log"
        else
            echo "$(/bin/date): ${prog}: Info:" "$@" >> "$log"
        fi
    fi
}


is_mounted()
{
    local path="$(/usr/bin/realpath "$1")"
    local ev=0

    info "is_mounted $1"
    info "path = $path"
    [ -n "$path" -a "$(/bin/mount | /usr/bin/fgrep " $path " -c)" != 0 ]
    ev=$?
    info "is_mounted rv=$ev"
    return $ev
}

main "$@"
exit 0

