#!/bin/bash

#
# Enable legacy to be able to ssh. This is done at /root/.ssh/config
#
# REF: /usr/local/scripts/monit/scripts/check-ilo.sh
#
# And now how to add the key to ilo4, I should have documented this
# The ilo4 web mentions to convert the key to pem, but no. The .pub key
# works fine.
# Navigate to Administration>>Security
# Click on the user and click "Authorise New Key"
# Add the key. The key needs to be generated special though
# REF: https://support.hpe.com/hpesc/public/docDisplay?docId=sd00001038en_us&page=GUID-748CFA7C-9B5D-4EF9-872F-C39402C0FBD3.html
#
# Authorizing a new SSH key by using the web interface
# Prerequisites
# Administer User Accounts privilege
#
# Procedure
# Generate a 2,048-bit DSA or RSA key by using ssh-keygen, puttygen.exe, or another SSH key utility.
# Save the public key as key.pub.
# Copy the contents of the key.pub file.
# Navigate to the Administration > Security page.
# Click the Secure Shell Key tab.
# Select the check box to the left of the user account to which you want to add an SSH key.
# Each user account can have only one key assigned.
#
# Click Authorize New Key.
# Paste the public key into the Public Key Import Data box.
# Click Import Public Key.
# The Authorized SSH Keys table is updated to show the hash of the SSH public key associated with the user account.
#

host="admin@192.168.10.33"

ssh_opts=(
        "-oKexAlgorithms=+diffie-hellman-group1-sha1" 
        "-oConnectTimeout=5"
    )

# apply fan patches if fan speed in higher than this
fan_warn="60"
#
# Unless the HDD temp is this value or higher.
# If it is, reset the ilo so that fan speed rises to cool the system
HDD_warn="59"
#
# But if the fan speed is already this high, then do not reset
HDD_do_not_reset_if_speed_greated_than="70"
#

declare -A ilo_data

EV="0"

opt_cron=""
opt_force=""
opt_reset=""
opt_print=""
opt_report_only=""

reset_done=""
fans_done=""

main()
{
    local val
    local scale


    process_opts "$@"

    get_values
    sleep 2

    if [ -n "$opt_print" ]
    then
        for key in "${!ilo_data[@]}"; do
            echo "$key = ${ilo_data[$key]}"
        done
        exit 0
    fi


    ##########
    #
    # Check HDD Temperature
    #
    info "$(get_val "/system1/sensor12" DeviceID -= CurrentReading RateUnits -: -HealthState HealthState -: -OperationalStatus OperationalStatus)"
    DeviceID="$(get_val "/system1/sensor12" DeviceID)"
    temperature="$(get_val "/system1/sensor12" CurrentReading)"
    scale="$(get_val "/system1/sensor12" RateUnits)"
    HealthState="$(get_val "/system1/sensor12" HealthState)"
    OperationalStatus="$(get_val "/system1/sensor12" OperationalStatus)"

    if [ "$HealthState" != "Ok" ]
    then
        warn "$DeviceID HealthState is $HealthState"
    fi

    if [ "$OperationalStatus" != "Ok" ]
    then
        warn "$DeviceID OperationalStatus is $OperationalStatus"
    fi

    if [ "$temperature" -ge "$HDD_warn" ]
    then
         warn "$DeviceID temperature greater than $((HDD_warn - 1)) ${scale}."
    fi
    #
    ##########


    ##########
    #
    # check fan speed and status
    #
    fan_speed_max="0"
    for fan in 1 2 3 4 5 6 7 8
    do
        speed="$(get_val "/system1/fan1" 0 DesiredSpeed)"
        scale="$(get_val "/system1/fan1" 1 DesiredSpeed)"
        HealthState="$(get_val "/system1/fan1" HealthState)"
        OperationalStatus="$(get_val "/system1/fan1" OperationalStatus)"

        if [ "$speed" -gt "$fan_speed_max" ]
        then
            fan_speed_max="$speed"
        fi

        if [ -n "$speed" ]
        then
            info "$(get_val "/system1/fan$fan" DeviceID -= DesiredSpeed -: -HealthState HealthState -: -OperationalStatus OperationalStatus)"
            if [ "$speed" -ge "$fan_warn" ]
            then
                warn "Fan$fan speed greater than $((fan_warn - 1)) ${scale}."
            fi
        else
            warn "Unable to get fan $fan speed"
        fi
        
        if [ "$HealthState" != "Ok" ]
        then
            warn "Fan$fan HealthState is $HealthState"
        fi

        if [ "$OperationalStatus" != "Ok" ]
        then
            warn "Fan$fan OperationalStatus is $OperationalStatus"
        fi
    done
    #
    ##########

    ##########
    #
    # Check reset Option
    #
    if [ -n "$opt_reset" ]
    then
        cmd_reset
        opt_report_only="opt_reset"
    fi
    #
    ##########

    ##########
    #
    # Check force Option
    #
    if [ -n "$opt_force" ]
    then
        cmd_set_fan_speed
        opt_report_only="opt_force"
    fi
    #
    ##########

    ##########
    #
    # Do HDD Temperature and fan speed
    #
    if [ "$temperature" -ge "$HDD_warn" ]
    then
        if [ "${fan_speed_max}" -gt "$HDD_do_not_reset_if_speed_greated_than" ]
        then
            warn "Fan speed is ${fan_speed_max}, which is greater than ${HDD_do_not_reset_if_speed_greated_than}, so not reseting"
        else
            cmd_reset
        fi

    elif [ -n "$warn_msg" ]
    then
        cmd_set_fan_speed
    fi
    #
    ##########

    if [ -n "$warn_msg" ] || [ -z "$opt_cron" ]
    then
        echo "$info_msg"
        echo "$warn_msg"
    fi

    return $EV
}


cmd_set_fan_speed()
{
    if [ "$opt_report_only" == "opt_reset" ]
    then
        warn "we have alreaqdy reset, not setting fan speeds."

    elif [ -n "$fans_done=" ]
    then
        warn "fans done already, not resetting ilo."

    elif [ -n "$reset_done" ]
    then
        warn "reset done already, not setting fan speed."
    else
        warn "Setting fan speeds."
        ilo_cmd 'fan pid 11 sp 6000'
        ilo_cmd 'fan pid 31 sp 5300'
        ilo_cmd 'fan pid 40 sp 4700'
        ilo_cmd 'fan pid 42 lo 10000'
        ilo_cmd 'fan pid 46 sp 4400'
        ilo_cmd 'fan pid 49 sp 6000'
        ilo_cmd 'fan pid 50 sp 3800'
        fans_done="yes"
    fi
}

cmd_reset()
{
    local wait_time="300"

    if [ -n "$opt_report_only" ]
    then
        warn "report_only is set, not resetting ilo."

    elif [ -n "$reset_done" ]
    then
        warn "reset done already, not resetting ilo."
    else
        warn "reset command passed from command line, reseting"
        ilo_cmd 'cd /map1' 'reset'
        warn "Wait $wait_time seconds after reseting"
        reset_done="yes"
        sleep $wait_time
    fi
}

process_opts()
{
    for opt in "$@"
    do
        case "$opt" in
            cron)   opt_cron="$opt";;
            force)  
                    opt_force="$opt"
                    warn "force option passed, setting fan speed."
                    ;;
            reset)
                    opt_reset="$opt"
                    ;;
            print)  opt_print="$opt";;
            help)
                usage
                echo "Usage: $(basename "$0") [cron|force|print|help]"
                exit 0
                ;;
            report-only) opt_report_only="$opt";;
            *)
                echo "Erron: Unknown command $opt$"
                echo
                usage
                exit 1
                ;;
        esac
    done
}

usage()
{
    echo "Usage: $(basename "$0") [cron|force|print|help]"
    echo
    echo "Where command is:"
    echo "  cron        - Only print on error"
    echo "  force       - Force setting fan speed"
    echo "  print       - Printg all ilo4 values"
    echo "  reset       - Reset ilo4"
    echo "  report-only - Do not reset or set fan speed"
    echo "  help        - Print this helpo message"
}

info_msg=""
info()
{
    info_msg="${info_msg}
$@"
}

warn_msg=""
warn()
{
    EV=$((EV + 1))
    warn_msg="${warn_msg}
Warning: $@"
}


get_val()
{
    [ $# -lt 2 ] && return ""

    # Enable extended globbing
    shopt -s extglob

    local base="$1"
    shift

    local index="@"
    local first=""

    for name in "$@"
    do
        case "$name" in
            ("@")
                index="@"
                ;;
            (-*)
                echo -n "${first}${name##-}"
                first=" "
                ;;
            (*)
                if [ -z "${name//[0-9]/}" ]
                then
                    index="$name"
                else
                    val="${ilo_data[$base/$name]}"

                    read -ra val <<< "${ilo_data[$base/$name]}"

                    if [ "$index" == "@" ]
                    then
                        echo -n "${first}${val[@]}"
                    else
                        echo -n "${first}${val[$index]}"
                    fi
                    first=" "
                    index="@"
                fi
                ;;
            esac
    done
    [ -n "$first" ] && echo
}

ilo_cmd()
{
    local str

    (
        while [ $# != 0 ]
        do
            #str="$(/usr/bin/ssh "${ssh_opts[@]}" $host "$1")"
            #str="$( echo "$str" | /usr/bin/grep -v -e '^\s*$' )"
            #EV=$((EV + $?))

            echo "$1"
            shift
            sleep 3
        done
        echo "exit"
    ) | /usr/bin/ssh "${ssh_opts[@]}" $host 

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

