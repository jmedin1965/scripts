#!/bin/bash
#
port="8384"

if [ -z "$1" ]
then
    echo Usage $(basename "$0") remote-host
    exit 1
fi

echo port $port from host $1 will be available locally

/mnt/c/Program\ Files/WSL/wslg.exe -d Ubuntu-24.04 --cd "~" -- /snap/bin/chromium https://localhost:$port

ssh -L 8384:localhost:8384 -J jmedin@192.168.10.127 root@$1 -N

#!/bin/bash

main()
{
    occ=""
    [ -e /var/www/nextcloud/occ ] && occ="/var/www/nextcloud/occ"
    [ -e /app/www/public/occ ]    && occ="/app/www/public/occ"

    updater_phar=""
    [ -e /var/www/nextcloud/updater/updater.phar ] && updater_phar="updater.phar"
    [ -e /app/www/public/updater/updater.phar ]    && updater_phar="/app/www/public/updater/updater.phar"

    conf_f=""
    [ -e "/var/www/nextcloud/config/config.php" ]         && conf_f="/var/www/nextcloud/config/config.php"
    [ -e "/data/config/www/nextcloud/config/config.php" ] && conf_f="/data/config/www/nextcloud/config/config.php"
    
    user="$(stat -c "%U" "$occ")"

    declare -A menu
    menu=()
     menu["q"]="quit"
     menu["1"]="db:add-missing-indices"
     menu["2"]="db:convert-filecache-bigint"
     menu["3"]="app:list"
     menu["4"]="app:disable"
[ -n "$conf_f" ] && \
    menu["ec"]="edit config.php"
     menu["f"]="groupfolders:scan"
     menu["s"]="status"
    menu["fc"]="files:cleanup         - occ files:cleanup"
    menu["fs"]="files:scan            - occ files:scan --path=path"
    menu["fa"]="files:scan            - occ files:scan --all"
     menu["u"]="upgrade apps          - occ upgrade"
[ -n "$updater_phar" ] && \
     menu["U"]="upgrade system        - updater/updater.phar"
     menu["e"]="exit maintenence mode - occ maintenance:mode --off"
    menu["mr"]="maintenance repair    - occ maintenance:repair --include-expensive"
    menu["sc"]="setupchecks           - occ setupchecks -vvv"


    result=""
    if which dialog > /dev/null
    then
        radiolist="radiolist"
    else
        radiolist="radiolist_txt"
    fi
    while [ "$result" != q ]
    do

        result="$($radiolist --title "DIALOG RADIOLIST" --backtitle "A user-built list")"
        retval="$?"

        case $retval in
          0)
            echo "The user chose '$result' - '${menu[$result]}'.";;
          1)
            echo "Cancel pressed."
            result="q"
            ;;
          255)
            echo "Box closed."
            result="q"
            ;;
          *)
            echo "Unknown retval: $retval"
            result="q"
            ;;
        esac

        if [ "$result" != "q" ]
        then
            echo "press ENTER to continue"
            read ans
        fi

        case "$result" in
            1) /usr/bin/sudo -u $user php $occ db:add-missing-indices | less;;
            2) /usr/bin/sudo -u $user php $occ db:convert-filecache-bigint | less;;
            3) /usr/bin/sudo -u $user php $occ app:list | less;;
            4)
                echo -n "which app to disable ? "
                read app
                /usr/bin/sudo -u $user php $occ app:disable $app | less
                ;;
            f)
                /usr/bin/sudo -u $user php $occ groupfolders:list
                echo -n "which folder number ? "
                read num
                /usr/bin/sudo -u $user php $occ groupfolders:scan $num | less
                ;;
            s)  /usr/bin/sudo -u $user php $occ status | less;;
            sc) /usr/bin/sudo -u $user php $occ setupchecks -vvv | less;;
            fc) /usr/bin/sudo -u $user php $occ files:ceanup | less;;
            fs) 
                echo "example: admin/files/bin"
                echo -n "which folder to scal ? "
                read folder
                /usr/bin/sudo -u $user php $occ files:scan --path="$folder" | less;;
            fa) /usr/bin/sudo -u $user php $occ files:scan --all | less;;
            mr) /usr/bin/sudo -u $user php $occ maintenance:repair --include-expensive | less;;
            u)  /usr/bin/sudo -u $user php $occ upgrade | less;;
            U)  /usr/bin/sudo -u $user php /var/www/nextcloud/updater/updater.phar | less;; # REF https://docs.nextcloud.com/server/latest/admin_manual/maintenance/update.html
            e)  /usr/bin/sudo -u $user php $occ maintenance:mode --off; echo "press enter to contunue"; read ans;;
            ec) vi "$conf_f";;
        esac
    done
}

radiolist_txt()
{
    local result=""
    local retval="0"
    local m=() # menu entries array
    local i=() # menu keys so we can sort them
    local key

    # get the array keys in array i
    for key in "${!menu[@]}"
    do
        i+=("$key")
    done

    # sort the keys
    local ifs="$IFS"
    IFS=$'\n' i=($(sort <<<"${i[*]}"))
    IFS="$ifs"

    # build the menu
    echo > /dev/stderr
    echo "------" > /dev/stderr
    echo "user=$user" > /dev/stderr
    echo "occ=$occ" > /dev/stderr
    echo  > /dev/stderr

    for key in "${i[@]}"
    do
        printf "%4s %s \n" "${key})" "${menu[$key]}" > /dev/stderr
    done
    echo > /dev/stderr
    echo -n "which ? " > /dev/stderr
    read result

    retval="0"
    echo "$result"
    return "$retval"
}


radiolist()
{
    local result=""
    local retval="0"
    local m=() # menu entries array
    local i=() # menu keys so we can sort them
    local key

    # get the array keys in array i
    for key in "${!menu[@]}"
    do
        i+=("$key")
    done

    # sort the keys
    local ifs="$IFS"
    IFS=$'\n' i=($(sort <<<"${i[*]}"))
    IFS="$ifs"

    # build the menu
    for key in "${i[@]}"
    do
        if [ -z "$m" ]
        then
            m=( "$key" )
            m+=( "${menu[${key}]}" )
            m+=( "on" )
        else
            m+=( "$key" )
            m+=( "${menu[${key}]}" )
            m+=( "off" )
        fi
    done

    result="$(dialog "$@" --stdout --radiolist "Nextcloud OCC Menu" 0 0 12 "${m[@]}")"
    retval=$?
    echo "$result"
    return "$retval"
}

main "$@"
exit $?
