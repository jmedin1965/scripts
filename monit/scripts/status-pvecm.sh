#!/bin/bash

declare -A pvecm_status
nodes=()
EV="0"

main()
{
    if [ -e "/etc/pve/corosync.conf" ]
    then
        check_cluster "$@"

        if [ "${pvecm_status[Quorate]}" != Yes ]
        then
            EV="1"
            echo "Error: Quorum information: Quorate: ${pvecm_status[Quorate]}"
        fi

        #echo "Total votes    = ${pvecm_status[Total votes]}"
        #echo "Expected votes = ${pvecm_status[Expected votes]}"
        #echo "Node = ${pvecm_status[Name0x00000001]}"
        #echo ${nodes[@]}

    else
        echo "/etc/pve/corosync.conf: file does not exist, not part of a cluster"
    fi

    return $EV
}

check_cluster()
{
    local var
    local data
    local state=""

    while read line
    do
        echo "$line"
        case "$line" in
            *":"*)
                var="${line%%:*}"
                data="${line#*:}"

                # remove leading whitespace characters
                data="${data#"${data%%[![:space:]]*}"}"

                pvecm_status["$var"]="$data"
                ;;
            "Membership information") ;;
            "Quorum information") ;;
            "Votequorum information") ;;
            "Cluster information") ;;
            "Nodeid Votes Name") ;;
            "") ;;
            "------"*) ;;
            *)
                #echo line: \"$line\"
                read Nodeid Votes Name <<< "$line"
                if [ "$Nodeid" == Nodeid -a "$Votes" == Votes -a "$Name" == Name ]
                then
                    state="Nodeid"
                elif [ "$state" == Nodeid ]
                then
                    #echo "Nodeid=\"$Nodeid\", Votes=\"$Votes\", Name=\"$Name\""
                    nodes+=("$Nodeid")
                    pvecm_status["Votes$Nodeid"]="$Votes"
                    pvecm_status["Name$Nodeid"]="$Name"
                fi
                ;;
        esac
    done <<< "$(/usr/bin/pvecm status)"

    echo

}

main "$@"
