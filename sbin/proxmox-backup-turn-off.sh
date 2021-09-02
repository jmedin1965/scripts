#!/bin/bash

. /lib/lsb/init-functions

#
# Probably do this differently
#
# REF https://unix.stackexchange.com/questions/39226/how-to-run-a-script-with-systemd-right-before-shutdown
#
# so add a script to /usr/lib/systemd/system-shutdown/
# and make it react to arg1 set to halt


[ -e /usr/local/etc/proxmox-backup.conf ] && . /usr/local/etc/proxmox-backup.conf

if [ "$1" == install ]
then
    #
    # REF: https://www.golinuxcloud.com/run-script-with-systemd-before-shutdown-linux/
    #
    log_action_begin_msg "installing as a service"
    /usr/bin/cat > /etc/systemd/system/turn-off-sonoffs.service << END
[Unit]
Description=Turn Sonoffs off at Shutdown
DefaultDependencies=no
Before=shutdown.target

[Service]
Type=oneshot
ExecStart=$(/usr/bin/readlink -f "$0") off
TimeoutStartSec=120

[Install]
WantedBy=shutdown.target

END
    log_action_end_msg "$?"

    log_action_begin_msg "reload daemon"
    /usr/bin/systemctl daemon-reload
    log_action_end_msg "$?"

    log_action_begin_msg "enable service"
    /usr/bin/systemctl enable turn-off-sonoffs.service
    log_action_end_msg "$?"
elif [ "$1" == off ]
then
    # not on reboot
    # REF https://superuser.com/questions/1401813/run-a-script-on-systemd-service-only-at-shutdown-not-restart
    if ! /usr/bin/systemctl list-jobs | /usr/bin/grep -q -e "reboot.target.*start"
    then
        log_action_begin_msg "turning off sonoffs in 10 seconds: $sonoffs"
        sleep 10
        log_action_end_msg "$?"

        #
        # Sent off command to sonoffs
        #
        for sonoff in $sonoffs
        do
    	    log_action_begin_msg "ping sonnoff $sonoff"
            /usr/bin/ping -c 1 -W 1 $sonoff > /dev/null 2>&1
    	    log_action_end_msg "$?"

    	    log_action_begin_msg "turn off $sonoff"
            /usr/bin/curl http://$sonoff/cm?cmnd=Power%20Off > /dev/null 2>&1
    	    log_action_end_msg "$?"
        done
    fi
else
    echo usage: $(/usr/bin/basename "$0") 'off|install'
fi

exit 0
