#!/bin/bash
#

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
/usr/bin/tty -s
tty="$?"
log_f="/var/log/volumio-cron.log"
unpause_grace="3600" # if paused, cron will not unpause for this many seconds
pause_file="/tmp/volumio_paused"

main()
{
  command="${1:-status}"

  user="$(whoami)"
  log "user=$user"
  log "tty=$tty"
  log "command=$command"

  if [ "$user" != volumio ]
  then
    log "must run as volumio user, doing a sudo -u volumio"
    exec sudo -u volumio "$0" "$@"
  fi

  case "$1" in
    [Oo][fF]*|[pp][aA]*)
      command="pause"
      pause
      ;;
    [On][nN]*|[pP][lL]*)
      command="play"
      play
      ;;
    [sS]*)
      command="status"
      is_playing
      ;;
    *)
      log "$command: unknown command"
      ;;
  esac

  log
}

log()
{
  if [ $# -gt 0 ]
  then
    str="$(date +"%Y-%m-%d %H:%M:%S"): $@"
  else
    str=""
  fi

  if [ "$tty" == 0 ]
  then
    echo "$str"
  fi

  echo "$str" >> "$log_f"
}

kstop()
{
  sudo systemctl stop volumio-kiosk.service
}

kstart()
{
  sudo systemctl start volumio-kiosk.service
}

krestart()
{
  kstop
  sleep 1
  kstart
}

restart_volumio_services()
{
  log "restarting volumio services"
  volumio vrestart
  sleep 1
  krestart
  sleep 1
  update_status
}

update_status()
{
  status="$(volumio status | jq -r '.status')"
}

is_playing()
{
  update_status

  if [ -z "$status" ]
  then
    log "got no status, restarting services..."
    restart_volumio_services
  fi

  log "status=$status"

  case "$status" in
    play*)  return 0;;
    *)      return 1;;
  esac
}

pause_file_exists()
{
  local skip="1"  # default is don't skip

  if [ "$tty" != 0 ] # Only check if we don't have a tty terminal
  then
    log "No tty, check paused duration"
    if [ -e "$pause_file" ]
    then
      log "Pause file exists"
      age="$(( $(date +%s) - $(stat -c %Y "$pause_file") ))"
      log "Paused file exists, with age $age seconds"
      if [ "$age" -lt "$unpause_grace" ]
      then
        log "Check $unpause_grace, not old enough, skip play"
        skip="0"
      fi
    else
      if [ "$command" == pause ]
      then
        log "create pause file in the past as a marker so we can unpause"
        touch -d "$unpause_grace seconds ago" "$pause_file"
      else
        log "Create pause file, and skip play"
        touch "$pause_file"
        chmod 0600 "$pause_file"
        skip="0"
      fi
    fi
  else # if we do have a tty, then just delete the pause file
    if [ -e "$pause_file" ]
    then
      rm -f "$pause_file"
      log "pause file exists, clear pause file"
    fi
  fi

  return $skip
}

force_play()
{
  log "do force play"
  restart_volumio_services
  volumio play 2>&1 >> "$log_f"
  sleep 5
  update_status
}

force_pause()
{
  log "do force pause"
  restart_volumio_services
  volumio pause 2>&1 >> "$log_f"
  sleep 5
  update_status
}

play()
{

  if ! is_playing
  then
    if pause_file_exists
    then
      log "Pause file exists, skip do play"
    else
      log "do play"
      volumio play 2>&1 >> "$log_f"
      sleep 5
      is_playing || force_play
    fi
  else
    log "already playing, do nothing"
  fi

  is_playing
}

pause()
{
  if is_playing
  then
    log "do pause"
    volumio pause 2>&1 >> "$log_f"
    sleep 5
    is_playing && force_pause
    krestart
  else
    log "not playing"
  fi

  is_playing
}

main "$@"
