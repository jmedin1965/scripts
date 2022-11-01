#!/bin/bash

host="admin@mgt-host04.gli.lan"
ssh_opts="-oKexAlgorithms=+diffie-hellman-group1-sha1"

declare -A ilo_data

ilo_cmd()
{
    echo /usr/bin/ssh $ssh_opts $host "$1"
    /usr/bin/ssh $ssh_opts $host "$1"
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

                        echo "v \"$v\""
                        echo "d  =\"$d\""
                        ilo_data["$v"]="$d"
                    fi
                fi
                ;;
        esac
    done <<< "$(/usr/bin/ssh $ssh_opts $host "show -a" | /usr/bin/sed 's/\r$//')"
}

get_values

echo
echo fan1 DesiredSpeed = ${ilo_data[/system1/fan1/DesiredSpeed]}
${ilo_data[/system1/fan1/DesiredSpeed]}
exit 0


ilo_cmd 'fan pid 11 sp 5900'
ilo_cmd 'fan pid 31 sp 5300'
ilo_cmd 'fan pid 40 sp 4700'
ilo_cmd 'fan pid 42 lo 10000'
ilo_cmd 'fan pid 46 sp 4400'
ilo_cmd 'fan pid 50 sp 3800'

exit 0
