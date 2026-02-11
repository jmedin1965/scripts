#!/bin/bash
# choose pinentry depending on PINENTRY_USER_DATA
# requires pinentry-curses and pinentry-gtk2
# this *only works* with gpg 2
# see https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=802020

log()
{
    echo "info:" "$@" >> /tmp/my-pinentry.sh.log
}

send()
{
    echo "$@"
    log "sent:" "$@"
    send_list+=("$@")
}

got()
{
    log "got:" "$@"
}

send_list=()
option_touch_file=""

log "argc = $#"
for arg in "$@"
do
    log "arg = $arg"
done

#set >> /tmp/my-pinentry.sh.log

pe_gpg4win="/mnt/c/Program Files (x86)/Gpg4win/bin/pinentry.exe"

case $PINENTRY_USER_DATA in
gtk)
    exec /usr/bin/pinentry-gtk-2 "$@"
    ;;
none)
    exit 1 # do not ask for passphrase
    ;;
*)
    if [ -e "$pe_gpg4win" ] 
    then
        cd "/mnt/c"

        send "OK Pleased to meet you"

        while read line
        do
            got "$line"
            case "$line" in

                "OPTION touch-file="* ) 
                    option_touch_file="${line##OPTION touch-file=}"
                    send "OK";;
                "OPTION"* ) 
                    send "OK";;
                "GETINFO flavor")
                    send "D qt"
                    send "OK"
                    ;;
                "GETINFO version")
                    send "D 1.2.1"
                    send "OK"
                    ;;
                "GETINFO ttyinfo")
                    send "D - - - - 0/0 -"
                    send "OK"
                    ;;
                "GETINFO pid")
                    send "D $$"
                    send "OK"
                    ;;
                "SETKEYINFO"*)
                    send "OK"
                    ;;
                "SETDESC"*)
                    send "OK"
                    ;;
                "SETPROMPT"*)
                    send "OK"
                    ;;
                "GETPIN")
                    send "D GXK5EHcu3fdfaJ"
                    log "option_touch_file = $option_touch_file"
                    [ -n "$option_touch_file" ] && /bin/touch "$option_touch_file" && log "file touched"
                    send "OK"
                    ;;
                "BYE:"*)
                    send "OK"
                    ;;
                *)  
                    log "got unknown: $line"
                    exit 1
                    ;;
            esac
        done
        # exec "$pe_gpg4win" "$@"
    else
        exec /usr/bin/pinentry-curses "$@"
    fi
esac
                                                                                                17 
