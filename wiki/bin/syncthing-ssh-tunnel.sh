#!/bin/bash


port="8384"
TUN_PID=""
BROWSER_PID=""

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
    while :
    do
        if [ $# == "0" ]
        then
            echo -n "Connect to which host, or 'q', to quit: "
            read result
            set -- "$result"

        elif [ $# == 1 -a -z "$TUN_PID" ]
        then
            result="$1"
        else
            menu "$@"
        fi

        if [ "$result" == "q" ]
        then
            echo $TUN_PID=$TUN_PID
            [ -n "$TUN_PID" ] && kill -0 "$TUN_PID" && kill $TUN_PID
            exit 0

        elif [ "$result" == "+" ]
        then
            echo -n "Add which host: "
            read result
            set -- "$@" "$result"
        fi

        [ -n "$TUN_PID" ] && kill -0 "$TUN_PID" && kill $TUN_PID && sleep 3

        echo "port $port from host $result will be available locally"
        ssh -L 8384:localhost:8384 -J jmedin@192.168.10.127 -A root@$result -N &
        echo tunell started in background
        sleep 3
        TUN_PID="$!"
        
        new_window="--new-window"
        if [ -z "$BROWSER_PID" ] || ! kill -0 "$BROWSER_PID"
        then
            /snap/bin/chromium $new_window "https://localhost:$port"
            BROWSER_PID="$(pgrep -f chromium | tail -n 1)"
        fi

        #wait $TUN_PID

        [ $# -gt 1 ] || exit 0

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
    #menu["q"]="quit"
    #menu["b"]="$BROWSER_PID"

    result=""
    if which dialog > /dev/null
    then
        radiolist="radiolist"
    else
        radiolist="radiolist_txt"
    fi

    result="$($radiolist --title "DIALOG RADIOLIST" --backtitle "A user-built list" --extra-button --extra-label "Add")"
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
        echo -n pause
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

    result="$(dialog "$@" --stdout --radiolist "Nextcloud OCC Menu" 0 0 12 "${m[@]}")"
    retval=$?
    echo "$result"
    return "$retval"
}

main "$@"
exit $?

