#!/bin/bash


default_port="8384"
TUN_PID=""
BROWSER_PID=""
[ -z "$DISPLAY" ] && export DISPLAY=":0"
prog="$(basename "$0")"
conf="$HOME/.$prog.conf"
host=""
last_host=""

declare -A port_list
declare -A pid_list
next_port="$default_port"

kill_all()
{
    local key
    local PID

    for key in "${!pid_list[@]}"
    do
        PID="${pid_list[$key]}"
        echo "kill host tunnel for \"$key\" with pid $PID"
        if kill -0 "$PID" &> /dev/null
        then
            kill $PID
        else
            echo "$key with PID=$PID is not running"
        fi
    done
}

# a function to trap CTRL_C since ssh-add times out or waits forever
ctrl_c() {
    echo "** Trapped CTRL-C"
    kill_all
    echo "msg: trap done"
    echo hit the ENTER key; read and
    exit 0
}
# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

main()
{
    local PID

    if [ ! -e "$conf" ]
    then
        touch "$conf"
    fi

    mapfile -t hosts < "$conf"
    new_window="--new-window"

    while :
    do
        if [ "${#hosts[@]}" == "0" ]
        then
            echo -n "Connect to which host:port or just host with default port on $default_port, or 'q', to quit: "
            read host
            if [ "$host" != "q" ]
            then
                echo "$host" >> "$conf"
            fi
        else
            menu "${hosts[@]}"
            clear
        fi

        echo host=$host

        if [ "$host" == "q" ]
        then
            kill_all
            exit 0

        elif [ "$host" == "+" ]
        then
            echo -n "Add which host:port or just host, default port is $default_port, or 'q', to quit: "
            read host
            echo "$host" >> "$conf"
        fi

        #[ -n "$TUN_PID" ] && kill -0 "$TUN_PID" && kill $TUN_PID && sleep 3

        last_host="$host"
        port="${host##*:}"
        echo port=$port
        [ -z "$port" -o "$port" == "$host" ] && port="$default_port"
        echo port=$port

        host="${host%%:*}"
        echo host=$host

        echo "port $port from host $host will be available locally on port $next_port"
        echo "DISPLAY=$DISPLAY"
        echo "conf=$conf"
        pwd
        echo HOME=$HOME
        echo next_port=$next_port

        PID=""
        [[ -v pid_list[$last_host] ]] && PID="${pid_list[$last_host]}"
        echo check host $last_host with pid $PID

        #echo hit the ENTER key; read and


        echo "ssh -4 -L $next_port:localhost:$port -J jmedin@192.168.10.127 -A root@$host -N"

        if [ -n "$PID" ] && kill -0 "$PID" &> /dev/null
        then
            echo "Tunnel already open, not opening another."
        else

            #echo hit the ENTER key; read and

            ssh -o StrictHostKeyChecking=accept-new -4 -L $next_port:localhost:$port -J jmedin@192.168.10.127 -A root@$host -N 2>/dev/null&

            pid_list[$last_host]="$!"
            port_list[$last_host]="$next_port"

            echo "tunell started in background with pid=${pid_list[$last_host]}"
            (( next_port++ ))
        fi
        sleep 4
        
        /snap/bin/chromium $new_window "https://localhost:${port_list[$last_host]}" >/dev/null  2>&1 &
        new_window=""

        #wait $TUN_PID
    done
}


menu()
{
    declare -A menu
    menu=()

    while [ $# -gt 0 ]
    do
        if [ -n "${port_list[$1]}" ]
        then
            menu["$1"]="connected on port ${port_list[$1]} with pid=${pid_list[$1]}"
        else
            menu["$1"]="connect to host"
        fi
        shift
    done
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
        host="q"
        ;;
      3)
        echo "Add pressed."
        host="+"
        ;;
      255)
        echo "Box closed."
        host="q"
        ;;
      *)
        echo "Unknown retval: $retval"
        host="q"
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
        [ "$key" != "q" ] && i+=("$key")
    done

    # sort the keys
    local ifs="$IFS"
    IFS=$'\n' i=($(sort <<<"${i[*]}"))
    IFS="$ifs"
    i+=("q")

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

    result="$(dialog "$@" --stdout --radiolist "ssh tunnel next_port=$next_port, last_host=$last_host" 0 0 12 "${m[@]}")"
    retval=$?
    echo "$result"
    return "$retval"
}

main "$@"
exit $?

