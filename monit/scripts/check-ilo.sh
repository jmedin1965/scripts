#!/bin/bash

host="admin@10.10.1.33"
host="admin@192.168.10.33"

ssh_opts=(
        "-oKexAlgorithms=+diffie-hellman-group1-sha1" 
        "-oConnectTimeout=5"
    )

# warn if fan percent is thi value or higher
fan_warn="56"

declare -A ilo_data

EV="0"

main()
{
    local val
    local scale
    local warn="no"

    local opt
    local opt_cron=""

    local info=""

    for opt in "$@"
    do
        case "$opt" in
            cron)   opt_cron="$opt";;
        esac
    done

    get_values

    echo
    for fan in 1 2 3 4 5 6 7 8
    do
        val="${ilo_data[/system1/fan$fan/DesiredSpeed]}"

        if [ -n "$val" ]
        then
            scale="$(set -- $val; echo $2)"
            val="$(set -- $val; echo $1)"
            info="${ilo_data[/system1/fan$fan/DeviceID]}: ${ilo_data[/system1/fan$fan/OperationalStatus]}: $val $scale"
            if [ "$val" -ge "$fan_warn" ]
            then
                warn="yes"
                echo "$info"
            else
                if [ -z "$opt_cron" ]
                then
                    echo "$info"
                fi
            fi
        fi
    done

    if [ "$warn" == yes ] 
    then
        ilo_cmd 'fan pid 11 sp 6000'
        ilo_cmd 'fan pid 31 sp 5300'
        ilo_cmd 'fan pid 40 sp 4700'
        ilo_cmd 'fan pid 42 lo 10000'
        ilo_cmd 'fan pid 46 sp 4400'
        ilo_cmd 'fan pid 49 sp 6000'
        ilo_cmd 'fan pid 50 sp 3800'
        echo "Warning: Fan speed greater that $fan_warn $scale, setting fan speed."
        EV=$((EV + 1))
    fi

    return $EV
}

ilo_cmd()
{
    local str

    str="$(/usr/bin/ssh "${ssh_opts[@]}" $host "$1")"
    EV=$((EV + $?))
    str="$( echo "$str" | /usr/bin/grep -v -e '^\s*$' )"
    EV=$((EV + $?))
}

#/map1/oemhp_alertmail1                
#  Targets                   
#  Properties                     
#    oemhp_alertmail_enable=yes
#    oemhp_alertmail_email=jmedin1965@gmail.com
#    oemhp_alertmail_sender_domain=jmsh-home.com
#    oemhp_alertmail_smtp_server=smtp.dodo.com.au
#    oemhp_alertmail_smtp_port=25
#  Verbs                                                            
#    cd version exit show set oemhp_sendTestAlertmail
#"/system1/fan5/DeviceID=Fan Block 5"
#"/system1/fan5/ElementName=System"
#"/system1/fan5/OperationalStatus=Ok"
#"/system1/fan5/VariableSpeed=Yes"
#"/system1/fan5/DesiredSpeed=39 percent"
#"/system1/fan5/HealthState=Ok"



get_values()
{
    local var=""
    local mode=""
    local str

    # get result and capture return value
    str="$(/usr/bin/ssh "${ssh_opts[@]}" $host "show -a")"
    EV=$((EV + $?))

    #remove CR
    str="$(echo "$str" | /usr/bin/sed 's/\r$//')"
    EV=$((EV + $?))

    #/usr/bin/ssh ${ssh_opts[@]}" $host "show -a" | /usr/bin/sed 's/\r$//' | while read line
    while read -r line
    do
        case "$line" in
            "/"*)           var="$line";;
            "Targets" )     mode="$line";;
            "Properties")   mode="$line";;
            "Verbs")        mode="$line";;
            "")
                var=""
                mode=""
                ;;
            *)
                if [ -n "$var" ]
                then
                    d="${line#*=}"
                    v="$var/${line%=*}"
                    if [ "$mode" == Properties ]
                    then

                        #echo "v \"$v\""
                        #echo "d  =\"$d\""
                        ilo_data["$v"]="$d"
                    fi
                fi
                ;;
        esac
    done <<< "$str"
}

main "$@"

