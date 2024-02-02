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
    info DEBUG=$DEBUG
    info

    info "whoami=$(/bin/whoami)"

    #
    # update /etc/resolv.conf
    #
    # REF: https://gist.github.com/ThePlenkov/6ecf2a43e2b3898e8cd4986d277b5ecf
    #
    info "check and update dns on /etc/resolv.conf"
    dns="$(/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe -Command \
        '$(Get-DnsClientServerAddress -AddressFamily IPv4).ServerAddresses | select-object -Unique | ForEach-Object { "nameserver $_" }' | \
        /usr/bin/tr -d '\r')"
    if [ -n "$dns" ]
    then
        info "updating DNS on /etc/resolv.conf"
        info "dns = $dns"
        /usr/bin/sed -i '/nameserver/d' /etc/resolv.conf
        echo "$dns" >> /etc/resolv.conf
    fi

    info
    info user=$user
    info DEBUG=$DEBUG
    info
}


info()
{
    if [ -n "$DEBUG" ]
    then
        if [ $# == 0 ]
        then
            echo >> "$log"
        else
            echo "Info: ${prog}: $(/bin/date):" "$@" >> "$log"
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

