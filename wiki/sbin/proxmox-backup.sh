#!/bin/bash

debug="0"       # debub information ?
vms=""          # list of vm's to back up
storage=""      # pvesm storage for backup
mailto=""       # mail results to
sonoffs=""      # sonoffs to turn on or off, off is in reverse order
wait="15"       # how many cycles to wait
secs="60"       # seconds in each cycle
backup_host=""  # host running backup software

[ -e /usr/local/etc/proxmox-backup.conf ] && . /usr/local/etc/proxmox-backup.conf 

log()
{
    [ "$debug" -gt 0 ] && echo '***' "$@"
}

#
# Turn sonoffs on
#
for sonoff in $sonoffs
do
    log turning sonoff $sonoff on
    /usr/bin/curl http://$sonoff/cm?cmnd=Power%20On > /dev/null 2>&1
done

#
# wait for server to turn on
#
num="0"
check="not"
while [ "$num" -le "$wait" ]
do
    if [ -z "$backup_host" ] || /usr/bin/ping -c 1 -W 1 $backup_host > /dev/null 2>&1
    then
        log "got ping from $backup_host"
        check="$(set -- $(/usr/sbin/pvesm status | /bin/grep "^$storage "); [ "$2" == pbs -a "$3" == active ] && echo active)"
        log check if storage $storage is available: $check
        if [ "$check" == active ]
        then
            log "storage $storage is available"
            break
        else
            log "$num: waiting for storage $storage ..."
        fi
    else
        log "$num: waiting for host $backup_host ..."
    fi
    sleep $secs
    num="$(( num + 1))"
done

log check if storage is available = $check

#
# Do the backup only if the storage is available
#
if [ "$check" == active ]
then
    echo /usr/bin/vzdump $vms \
        --mode snapshot \
        --mailnotification always \
        --quiet 1 \
        --mailto "$mailto" \
        --storage "$storage" \
        --compress zstd
else
    echo "
vms     = $vms
storage = $storage
mailto  = $mailto

Storage is not available, so no backups have been done.

    " | /usr/bin/mail -s "backup schedule skipped" $mailto

fi

#
# turn off backup server
#
if [ -n "$backup_host" ]
then
    log "turning off $backup_host"
    /usr/bin/ssh "$backup_host"  /usr/sbin/halt 
fi

#vzdump 102 --mode snapshot --mailnotification always --quiet 1 --mailto jmedin1965@gmail.com --storage backup01 --compress zstd

