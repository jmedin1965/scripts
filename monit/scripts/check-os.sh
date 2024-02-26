#!/bin/bash

source "$(/usr/bin/dirname "$0")/functions.sh"

main()
{
    local os_description
    local os_id
    local os_release
    local os_core
    local Process Version Build Other
    local check_os_auto_add_sha1sum="0"
    local check_os_auto_add_f="$conf_d/check_os_auto"
    local EV="0"

    # save sha1sum
    [ -e "$check_os_auto_add_f" ] && check_os_auto_add_sha1sum="$(sha1sum "$check_os_auto_add_f")"

    status_or_err "$(monit_uptime)"
    status_or_err "Monit $(monit_uptime -v) uptime: $(monit_uptime -s)s"

    echo "check, monit uptime: $(monit_uptime -s)s" >> /tmp/monit.log

    get_os_info

    status_or_err "Distributor ID:" "$os_id"          "is unknown"
    status_or_err "Description:   " "$os_description" "is unknown"
    status_or_err "Release:       " "$os_release"     "is unknown"
    status_or_err "Codename:      " "$os_codename"    "is unknown"

    case "$os_id" in
        debian)
            check_os_auto_add include "${conf_groups}/debian/*"
            check_os_auto_add include "${conf_groups}/debian-based/*"
            ;;
        ubuntu)
            check_os_auto_add include "${conf_groups}/ubuntu/*"
            check_os_auto_add include "${conf_groups}/debian-based/*"
            ;;
        IPFire)
            check_os_auto_add include "${conf_groups}/ipfire/*"
            ;;
    esac

    # now checke for known systems
    #

    # openmediavault
    if [ -x /usr/sbin/omv-sysinfo ]
    then
        eval $(to_vars /usr/sbin/omv-sysinfo omv-version)
        status_or_err "omv Release: " "$Release"  "is unknown"
        status_or_err "omv Codename:" "$Codename" "is unknown"

        check_os_auto_add include "${conf_enabled}/*"
        check_os_auto_add include "${conf_groups}/omv/*"
    fi

    # proxmox Mail Gateway
    if [ -e /usr/bin/pmgversion ]
    then
        IFS="/ " read Process Version Build Other <<< "$(/usr/bin/pmgversion)"
        status_or_err "proxmox mail gateway Process: " "$Process" "is unknown"
        status_or_err "proxmox mail gateway Version: " "$Version" "is unknown"
        status_or_err "proxmox mail gateway Build:   " "$Build" "is unknown"
        status_or_err "proxmox mail gateway Other:   " "$Other" "is unknown"

        check_os_auto_add include "${conf_groups}/proxmox-mgw/*"
    fi

    # proxmox
    if [ -e /usr/bin/pveversion ]
    then
        IFS="/ " read Process Version Build Other <<< "$(/usr/bin/pveversion)"
        status_or_err "proxmox Process: " "$Process" "is unknown"
        status_or_err "proxmox Version: " "$Version" "is unknown"
        status_or_err "proxmox Build:   " "$Build" "is unknown"
        status_or_err "proxmox Other:   " "$Other" "is unknown"

        check_os_auto_add include "${conf_groups}/proxmox/*"
    fi

    # Process $check_os_auto_add_f file
    if [ "$check_os_auto_add_sha1sum" != "$(echo "$check_os_auto" | sha1sum)" ]
    then
        echo "$check_os_auto" > "$conf_d/check_os_auto"
        /usr/bin/monit reload
    fi

    err_print

    return "$EV"
}


status_or_err()
{
    local name="$1"
    local msg="$2"
    local alt_msg="$3"
    local rv="0"

    if [ $# == 1 ]
    then
        info "$name"

    elif [ -n "$msg" ]
    then
        info "$name" "$msg"
    elif [ -n "$alt_msg" ]
    then
        info "$name" "$alt_msg"
    else
        err "$name" "unknown"
        rv="1"
    fi

    EV=$((EV + ev))

    return $rv
}


# Append to the check_os_auto string
# 
#
check_os_auto=""
check_os_auto_add()
{
    local dir

    if [ $# -gt 1 ]
    then
        case "$1" in
            include)
                if [ "$(/usr/bin/basename "$2")" == '*' ]
                then
                    dir="$(/usr/bin/dirname "$2")"
                    [ -n "$dir" -a ! -d "$dir" ] && /bin/mkdir -p "$dir"
                fi
                ;;
        esac
    fi

    check_os_auto="$check_os_auto
$1 $2"
}

main "$@"

