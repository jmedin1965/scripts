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

# Unless the HDD temp is this value or higher.
# If it is, reset the ilo so that fan speed rises to cool the system
HDD_warn="59"

# Scale fan speed depending on HDD temperature
# Turn server off if temperatire is above HDD_max
HDD_normal="55"
HDD_max="59"
FAN_normal="50 "
FAN_max="255"

declare -A ilo_data
EV="0"

reset_done=""
fans_done=""

declare -A state
declare -A state_old
[ -e '/var/log/check-ilo.state.log' ] && source /var/log/check-ilo.state.log

main()
{
    process_opts "$@"

    if ! /bin/tty -s  || [ -n "${state[opt_cron]}" ]
    then
        exec 2>&1 > /var/log/check-ilo.out.log
    fi

    ##########
    #
    # Check system power status
    #
    ilo_cmd 'power'
    state[server_power]="$( set -- $ilo_cmd_str; echo ${!#})"
    info "Server power state : ${state[server_power]}"
    #
    ##########

    if [ "${state[server_power]}" != "Off" ]
    then
        check_ilo "$@"
    else
        warn "Server is off, not checking ilo."
        EV="$((EV++))"

        check_power_on
    fi

    declare -p state     | /bin/sed 's/^declare -A state=/declare -A state_old=/' > /var/log/check-ilo.state.log 

    if ( [ -n "$warn_msg" -o "$EV" != 0 ] && [ -n "${state[opt_cron]}" ] ) || [ -n "${state[opt_mail]}" ]
    then
		if compare_associative_arrays state state_old
		then
            do_email="F"
            info "old state is same as new state, not emailing."

        elif [ "${state[server_power]}" != "${state_old[server_power]}" ]
        then
            do_email="T"
            warn "server power state changed."

        # check if mail file is older that 2 hours
        elif [ ! -e /var/log/check-ilo.mail.log ] || [ $(( "$(/bin/date +%s)" - "$(/bin/stat -c "%Y" /var/log/check-ilo.mail.log)")) -gt "$((2 * 60 * 60))" ]
        then
            do_email="T"
            warn "Mail file is older than 2 hours."
        else
            do_email="F"
            warn "Mail file is not older than 2 hours."
        fi

        #warn '$((' "$(/bin/date +%s)" - "$(/bin/stat -c "%Y" /var/log/check-ilo.mail.log)" '))' '-gt' "$((2 * 60 * 60))"
        #warn "$(( "$(/bin/date +%s)" - "$(/bin/stat -c "%Y" /var/log/check-ilo.mail.log)"))" '-gt' "$((2 * 60 * 60))"

        if [ "$do_email" == "T" ] 
        then
            warn "Sending mail."
			(
				echo -e "$info_msg"
				echo -e "$warn_msg"
			) | /bin/tee /var/log/check-ilo.mail.log | /usr/local/bin/send_alert
		fi
    fi

    # only print if we have a tty and we did not get cron option
    # with cron, we do not display output, we need to use the mail option
    if /bin/tty -s && [ -z "${state[opt_cron]}" ]
    then
        echo "$info_msg"
        echo "$warn_msg"
    fi

    echo "$info_msg" > /var/log/check-ilo.log
    echo "$warn_msg" >> /var/log/check-ilo.log


    return $EV
}


compare_associative_arrays() {
    local declare1 declare2
    # Get the declaration strings and replace variable names with a placeholder
    declare1=$(declare -p "$1" 2>/dev/null)
    declare1="${declare1#*=}"
    declare2=$(declare -p "$2" 2>/dev/null)
    declare2="${declare2#*=}"

    # Compare the modified declaration strings
    if [[ "$declare1" == "$declare2" ]]; then
		return 0 # both same
        #echo "$1 and $2 are identical"
    else
		return 1 # both different
        #echo "$1 and $2 are different"
    fi
}


check_power_on()
{
	# Get the current hour in 24-hour format without a leading zero (%k)
	# Use %H for a leading zero if preferred, but ensure comparison uses (( )) for numerical evaluation
	local current_hour=$(date +"%k")

	# Define the start and end hours
	local start_hour=20 # 8:00 PM
	local end_hour=24   # Midnight is the end of the 24th hour (or start of 0th hour of next day)

	# Perform the numerical comparison
	if (( current_hour >= start_hour && current_hour < end_hour )); then
		warn "Turning server on"
    	ilo_cmd 'power on'
	fi
}

check_ilo()
{
    local val
    local scale

    get_values
    sleep 2

    if [ -n "${state[opt_print]}" ]
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
    state[HDD_temp]="$temperature"
    HDDscale="$(get_val "/system1/sensor12" RateUnits)"
    state[HDDScale]="$HDDscale"
    HealthState="$(get_val "/system1/sensor12" HealthState)"
    state[HDDHealth]="$HealthState"
    OperationalStatus="$(get_val "/system1/sensor12" OperationalStatus)"
    state[HDDOperationalStatus]="$OperationalStatus"

    if [ "$HealthState" != "Ok" ]
    then
        warn "$DeviceID HealthState is $HealthState"
        EV="$((EV++))"
    fi

    if [ "$OperationalStatus" != "Ok" ]
    then
        warn "$DeviceID OperationalStatus is $OperationalStatus"
        EV="$((EV++))"
    fi

    if [ "$temperature" -ge "$HDD_warn" ]
    then
        warn "$DeviceID temperature greater than $((HDD_warn - 1)) ${HDDscale}."
        EV="$((EV++))"
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
    	state[Fan${fan}HealthState]="$HealthState"
        OperationalStatus="$(get_val "/system1/fan1" OperationalStatus)"
    	state[Fan${fan}OperationalStatus]="$OperationalStatus"

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
                EV="$((EV++))"
            fi
        else
            warn "Unable to get fan $fan speed"
            EV="$((EV++))"
        fi
        
        if [ "$HealthState" != "Ok" ]
        then
            warn "Fan$fan HealthState is $HealthState"
            EV="$((EV++))"
        fi

        if [ "$OperationalStatus" != "Ok" ]
        then
            warn "Fan$fan OperationalStatus is $OperationalStatus"
            EV="$((EV++))"
        fi
    done
    #
    ##########

    ##########
    #
    # Check reset Option
    #
    if [ -n "${state[opt_reset]}" ]
    then
        cmd_reset
        state[opt_report_only]="opt_reset"
    fi
    #
    ##########

    ##########
    #
    # Check force Option
    #
    if [ -n "${state[opt_force]}" ]
    then
        cmd_set_fan_speed
        state[opt_report_only]="opt_force"
    fi
    #
    ##########


    ##########
    #
    # Do HDD Temperature and fan speed
    #
    if [ "$temperature" -gt "$HDD_max" ]
    then
        ilo_cmd 'power off'
        warn "HDD Temp is critical at $temperature ${scale}, shutting down server."
    	state[action]="Power off"
        EV="$((EV++))"

    elif [ "$temperature" -gt "$HDD_normal" ]
    then
        factor="$(( ( FAN_max - FAN_normal ) / ( HDD_max - HDD_normal - 1 ) ))"
        speed=$(( ( ( temperature - HDD_normal ) * factor ) + FAN_normal ))
    	state[FanFactor]="$factor"
    	state[FanSpeed]="$speed"
    	state[action]="Temp high, Set Fan Speed $speed"

        warn "HDD Temp is high at $temperature ${HDDscale}, set min fan speed to $speed."
        cmd_set_fan_speed_min $speed
        EV="$((EV++))"
        echo
    else
        if [ "$fan_speed_max" -gt "$fan_warn" ]
        then
            warn "HDD Temp is normal at $temperature $HDDscale}, set min fan speed to $FAN_normal."
    		state[action]="Temp normal, Set Fan Speed $FAN_normal"
            cmd_set_fan_speed_min $FAN_normal
            cmd_set_fan_speed
        fi
    fi
}


cmd_set_fan_speed()
{
    if [ "${state[opt_report_only]}" == "opt_reset" ]
    then
        warn "we have already reset, not setting fan speeds."

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

cmd_set_fan_speed_min()
{
    local speed="$1"

    if [ "$speed" == "" ] || [[ ! "$speed" =~ ^[0-9]+$ ]]
    then
        warn "Need a number between 0 and 255 to set min fan speed."

    elif [ -n "${state[opt_report_only]}" ]
    then
        warn "Report Only, not setting min speed."

    else
        [ "$speed" -gt 255 ] && speed="255"
        for i in 0 1 2 3 4 5 6 7
        do
            ilo_cmd "fan p $i min $speed"
        done
    fi
}

cmd_reset()
{
    local wait_time="300"

    if [ -n "${state[opt_report_only]}" ]
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
            cron)   state[opt_cron]="$opt";;
            force)  
                    state[opt_force]="$opt"
                    warn "force option passed, setting fan speed."
                    ;;
            reset)
                    state[opt_reset]="$opt"
                    ;;
            print)  state[opt_print]="$opt";;
            help)
                usage
                echo "Usage: $(basename "$0") [cron|force|print|help]"
                exit 0
                ;;
            report-only) state[opt_report_only]="$opt";;
            mail) state[opt_mail]="$opt";;
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
    echo "  mail        - Force sending status via email"
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
    [ -n "$first" ] && echo -e '\n'
}

ilo_cmd()
{
    local str

    ilo_cmd_str=""

    if [ $# == 1 ]
    then
            # capture the last non blank line in str
            str="$(/usr/bin/ssh "${ssh_opts[@]}" $host "$1" | 
                /bin/dos2unix |
                /bin/grep -v '^\s*$' |
                /bin/tail -n 1
                )"
            ilo_cmd_str="$str"

            EV=$((EV + $?))
    else
    (
        while [ $# != 0 ]
        do

            echo "$1"
            shift
            sleep 3
        done
        echo "exit"
    ) | /usr/bin/ssh "${ssh_opts[@]}" $host | /bin/dos2unix
    fi
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
    str="$(/usr/bin/ssh "${ssh_opts[@]}" $host "show -a" | /bin/dos2unix)"
    EV=$((EV + $?))

    #remove CR
    #str="$(echo "$str" | /usr/bin/sed 's/\r$//')"
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

