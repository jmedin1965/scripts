#!/bin/bash
#

/usr/bin/tty -s
tty="$?"
log_f="/var/log/volumio-cron.log"
unpause_grace="3600" # if paused, cron will not unpause for this many seconds
pause_file="/var/run/volumio_paused"

main()
{
  command="${1:-status}"

  log "tty=$tty"

  case "$1" in
    OFF|off|pause|PAUSE)
      command="pause"
      pause
      ;;
    ON|on|play|PLAY)
      command="play"
      play
      ;;
    status|STATUS)
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

is_playing()
{
  status="$(/usr/bin/mpc)"
  log "$status"
  status="$(echo "$status" | grep '\[.*\]')"
  status="${status##*[}"
  status="${status%%]*}"
  log "status=$status"
  case "$status" in
    playing)  return 0;;
    *)        return 1;;
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
        skip="0"
      fi
    fi
  else
    if [ -e "$pause_file" ]
    then
      rm -f "$pause_file"
      log "pause file exists, clear pause file"
    fi
  fi

  return $skip
}

play()
{
  if ! is_playing
  then
    if pause_file_exists
    then
      log "Pause file exists, skip do play"
    else
      /usr/bin/mpc play 2>&1 >> "$log_f"
      log "do play"
    fi
  else
    log "already playing, do nothing"
  fi
}

pause()
{
  if is_playing
  then
    /usr/bin/mpc pause 2>&1 >> "$log_f"
    log "do pause"
  else
    log "not playing"
  fi
}

main "$@"
