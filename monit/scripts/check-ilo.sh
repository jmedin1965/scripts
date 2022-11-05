#!/bin/bash

source "$(/usr/bin/dirname "$0")/functions.sh"

host="admin@mgt-host04.gli.lan"
ssh_opts="-oKexAlgorithms=+diffie-hellman-group1-sha1"

# warn if fan percent is thi value or higher
fan_warn="45"

declare -A ilo_data

main()
{
    local val
    local scale
    local warn="no"
    local EV="0"

    get_ilo_values $ssh_opts  "$host"

    for fan in 1 2 3 4 5 6 7 8
    do
        val="${ilo_data[/system1/fan$fan/DesiredSpeed]}"

        if [ -n "$val" ]
        then
            scale="$(set -- $val; echo $2)"
            val="$(set -- $val; echo $1)"
            info "${ilo_data[/system1/fan$fan/DeviceID]}: ${ilo_data[/system1/fan$fan/OperationalStatus]}: $val $scale"
            [ "$val" -ge "$fan_warn" ] && warn="yes"
        fi
    done

    if [ "$warn" == yes ] 
    then
        info "$(ilo_cmd 'fan pid 11 sp 5900')"
        info "$(ilo_cmd 'fan pid 31 sp 5300')"
        info "$(ilo_cmd 'fan pid 40 sp 4700')"
        info "$(ilo_cmd 'fan pid 42 lo 10000')"
        info "$(ilo_cmd 'fan pid 46 sp 4400')"
        info "$(ilo_cmd 'fan pid 50 sp 3800')"
        err "Fan speed greater that $fan_warn $scale, setting fan speed."
        EV="1"
    fi

    err_print
    return $EV
}

ilo_cmd()
{
    #echo /usr/bin/ssh $ssh_opts $host "$1"
    /usr/bin/ssh $ssh_opts $host "$1" | /usr/bin/grep -v -e '^\s*$'
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



get_ilo_values()
{
    local var=""
    local mode=""

    #/usr/bin/ssh $ssh_opts $host "show -a" | /usr/bin/sed 's/\r$//' | while read line
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
    done <<< "$(/usr/bin/ssh "$@" "show -a" | /usr/bin/sed 's/\r$//')"
}

main "$@"

