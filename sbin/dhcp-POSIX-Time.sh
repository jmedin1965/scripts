#!/bin/bash

#
# A script to work out DHCP options 100 and 101 
#

# REF https://serverfault.com/questions/1093755/how-can-i-acquire-the-timezone-information-about-when-a-timezone-change-occurs
#
# REF: https://www.di-mgt.com.au/wclock/tz.html
#
# Adding or changing time zone settings
#
# To add to or edit the time zone data for Wclock, edit the file wclocktz.ini. This should be in the Wclock subdirectory of your personal %APPDATA% folder (see where is the wclocktz.ini file?).
#
# To specify a new time zone you need to specify a POSIX.1 TZ string. The full details are specified in POSIX 1003.1 section 8.3. See Explanation of TZ strings below.
# 
# You must use the full expanded format; namely:
# 
# stdoffset[dst[offset][,start[/time],end[/time]]]
# The full POSIX.1 standard is available for free in HTML format from The Open Group Base Specifications (requires registering). A summary of the syntax of TZ strings is explained here.
# 
# An entry for a location that has daylight saving looks like:
# 
# [Pacific/Auckland]
# TZ=NZST-12NZDT,M10.1.0/2,M3.3.0/3
# For a location that does not have daylight saving, an entry looks like:
# 
#     [Pacific/Honolulu]
#     TZ=HST10
#     Caution: edit this file at your own risk. We have provided some TZ values that we believe are correct but we offer no guarantees on their validity.
# 
#     It's up to you to derive the correct POSIX.1 TZ string for any new time zones you want to add. If the politicians in the zone in question mess around with the timing of daylight saving every year, you will have to edit the 
#     file to suit every year, too.
#
#

export PATH="/usr/sbin:/usr/bin:/sbin:/bin"

main()
{
    timezone="$(< /etc/timezone)"
    year="$(date +"%Y")"
    ((year++)) # consider next year only

    if [ $# == 0 ]
    then
        if [ -z "$timezone" ]
        then
            echo error: unable to get timezone from /etc/timezone
            exit 1
        fi

        do_tz "$(< /etc/timezone)"
    else
        while [ -n "$1" ]
        do
            do_tz "$1"
            shift
        done
    fi
}


do_tz()
{
    timezone="$1"
    local i="0"
    local last="" # this is the line before the year of interest. Used to pick up if there is no DST like in QLD
    declare -A names=()
    local name="" # the time name. Ignore settings whose name has not changed since the last one
    local keys=""
    local data=""

#    echo
#    echo Get DHCP option 100 and 101 for next year
#    echo
#    echo timezone=$timezone
#    echo year=$year
#    echo



    last=""
    while read line
    do
        set -- $line
        if [ -n "$6" ]
        then
            if [ -n "${14}" -a -z "${names["${14}"]}" ]
            then
                if [ "$6" -lt "$year" ]
                then
 #                   echo line $i = 1:$1 2:$2 3:$3 4:$4 5:$5 6:$6 7:$7 8:$8 9:$9 10:${10} 11:${11} 12:${12} 13:${13} 14:${14} 15:${15} 16:${16} 17:${17} 18:${18}
                    last="${14}$(get_offset "${16}")"
#                    echo "    last name = $name"
#                    echo "    this name = ${14}"
#                    echo "    ${14}"

                elif [ "$6" -eq "$year" ]
                then
                    last=""
#                    echo 16=${16}
#                    echo line $i = 1:$1 2:$2 3:$3 4:$4 5:$5 6:$6 7:$7 8:$8 9:$9 10:${10} 11:${11} 12:${12} 13:${13} 14:${14} 15:${15} 16:${16} 17:${17} 18:${18}
                    if [ "$name" != "${14}" ]
                    then
#                        echo 16=${16}
                        names["${14}$(get_offset "${16}")"]="$(get_Opt100_M $line)"
                    fi
#                    echo "    last name = $name"
#                    echo "    this name = ${14}"
#                    echo "    ${14}"
                fi
                name="${14}"
            fi
        fi
        [ "$i" == "10" ] && break
    done <<< "$(zdump -v "$timezone" )"

    if [ -n "$last" ]
    then
        echo "dhcp-option=100,\"$last\""
    else
        for key in "${!names[@]}"
        do
            keys="${keys}${key}"
            data="${data},${names["$key"]}"
            #echo "dhcp-option=100,\"${key},${names["$key"]}\""
        done
        echo "dhcp-option=100,\"${keys}${data}\""
    fi
    echo "dhcp-option=101,\"$timezone\""
    echo
}

get_Opt100_M()
{
    local m=""
    local w="1" # default of forst d - day of the month
    local d="7"
    local t="${12}"


    # unfortunately, havent been able to automate this
    # so need to add this manually depending on your timezone
    # The default might work of using the first day of the month
    case "$timezone" in
        "Australia/"*) w="1";; # first d of the month, 5 is last
    esac

    case "$9" in
        "Sun")  d="0";;
        "Mon")  d="1";;
        "Tue")  d="2";;
        "Wed")  d="3";;
        "Thu")  d="4";;
        "Fri")  d="5";;
        "Sat")  d="6";;
    esac

    case "$3" in
        "Jan")  m="1";;
        "Feb")  m="2";;
        "Mar")  m="3";;
        "Apr")  m="4";;
        "May")  m="5";;
        "Jun")  m="6";;
        "Jul")  m="7";;
        "Aug")  m="8";;
        "Sep")  m="9";;
        "Oct")  m="10";;
        "Nov")  m="11";;
        "Dec")  m="12";;
    esac

#    echo "    Month = $m" > /dev/stderr
#    echo "    Week  = $w" > /dev/stderr
#    echo "    Day   = $d" > /dev/stderr
#    echo "    M$m.$w.$d/${t#0}" > /dev/stderr
    echo "M$m.$w.$d/${t#0}"
}

get_offset()
{
    local h
    local m
    local s
    local offset="+" # don't think we need the + sign

    if [ -n "$1" ]
    then
        s="$1"
        s="${s##gmtoff=}"
        [ "$s" -lt 0 ] && offset="" # negateve numbers are ok, only positive need the + added
        #echo "s=$s offset=$offset" > /dev/stderr
        m="$((s / 60))"
        s="$((s % 60))"
        h="$((m / 60))"
        m="$((m % 60))"
        
        offset="${offset}$h"
        [ "$m" -gt 0 ] && offset="${offset}:$m"
        [ "$s" -gt 0 ] && offset="${offset}:$s"
    fi

    echo "$offset"
}

main "$@"

#echo
#echo "dhcp-option=100,\"$dhcp_option_100\""
#echo "dhcp-option=101,\"$dhcp_option_101\""

