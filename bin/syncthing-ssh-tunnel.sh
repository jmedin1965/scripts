#!/bin/bash


default_port="8384"
TUN_PID=""
BROWSER_PID=""
[ -z "$DISPLAY" ] && export DISPLAY=":0"
prog="$(basename "$0")"
conf="$HOME/.$prog.conf"
host=""
last_host=""

# a function to trap CTRL_C since ssh-add times out or waits forever
ctrl_c() {
    echo "** Trapped CTRL-C"
    [ -n "$TUN_PID" ] && kill $TUN_PID
    echo "msg: trap done"
}
# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

main()
{
    if [ ! -e "$conf" ]
    then
        touch "$conf"
    fi

    mapfile -t hosts < "$conf"

    while :
    do
        if [ "${#hosts[@]}" == "0" ]
        then
            echo -n "Connect to which host:port or just host, default port is $default_port, or 'q', to quit: "
            read host
            if [ "$host" != "q" ]
            then
                echo "$host" >> "$conf"
            fi
        else
            menu "${hosts[@]}"
            clear
        fi

        if [ "$host" == "q" ]
        then
            echo $TUN_PID=$TUN_PID
            [ -n "$TUN_PID" ] && kill -0 "$TUN_PID" && kill $TUN_PID
            exit 0

        elif [ "$host" == "+" ]
        then
            echo -n "Add which host:port or just host, default port is $default_port, or 'q', to quit: "
            read host
            echo "$host" >> "$conf"
        fi

        [ -n "$TUN_PID" ] && kill -0 "$TUN_PID" && kill $TUN_PID && sleep 3

        last_host="$host"
        port="${host##*:}"
        echo port=$port
        [ -z "$port" -o "$port" == "$host" ] && port="$default_port"
        echo port=$port

        host="${host%%:*}"
        echo host=$host

        echo "port $port from host $host will be available locally"
        echo "DISPLAY=$DISPLAY"
        echo "conf=$conf"
        pwd
        echo HOME=$HOME

        ssh -L $default_port:localhost:$port -J jmedin@192.168.10.127 -A root@$host -N &
        TUN_PID="$!"

        echo tunell started in background
        sleep 3
        
        new_window="--new-window"
        if [ -z "$BROWSER_PID" ] || ! kill -0 "$BROWSER_PID"
        then
            /snap/bin/chromium $new_window "https://localhost:$default_port"
            BROWSER_PID="$(pgrep -f chromium | tail -n 1)"
        fi

        #wait $TUN_PID
    done
}


menu()
{
    declare -A menu
    menu=()

    while [ $# -gt 0 ]
    do
        menu["$1"]="connect to host $1"
        shift
    done
    #[ -n "$TUN_PID" ] && menu["kill"]="kill running tunnel with PID=$TUN_PID"
    menu["q"]="quit"
    #menu["b"]="$BROWSER_PID"

    host=""
    if which dialog > /dev/null
    then
        radiolist="radiolist"
    else
        radiolist="radiolist_txt"
    fi

    host="$($radiolist --title "DIALOG RADIOLIST" --backtitle "A user-built list" --extra-button --extra-label "Add")"
    retval="$?"

    case $retval in
      0)
        echo "The user chose '$result' - '${menu[$result]}'.";;
      1)
        echo "Cancel pressed."
        result="q"
        ;;
      3)
        echo "Add pressed."
        result="+"
        ;;
      255)
        echo "Box closed."
        result="q"
        ;;
      *)
        echo "Unknown retval: $retval"
        result="q"
        echo -n "Hit ENTER to contunue"
        read ans
        ;;
    esac

    return "$retval"
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

    result="$(dialog "$@" --stdout --radiolist "ssh tunnel port=$default_port, host=$last_host" 0 0 12 "${m[@]}")"
    retval=$?
    echo "$result"
    return "$retval"
}

main "$@"
exit $?

