#!/bin/bash
#

/usr/bin/tty -s
tty="$?"
log_f="/var/log/volumio-cron.log"
unpause_grace="3600" # if paused, cron will not unpause for this many seconds
pause_file="/var/run/volumio_paused"

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

play()
{
  local skip="1"  # 0=true >0=false
  local age

  if ! is_playing
  then

    if [ "$tty" != 0 ]
    then
      log "check paused duration"
      if [ -e "$pause_file" ]
      then
        log "pause file exists"
        age="$(( $(date +%s) - $(stat -c %Y "$pause_file") ))"
        log "paused file exists, with age $age seconds"
        if [ "$age" -lt "$unpause_grace" ]
        then
          log "check $unpause_grace, not old enough, skip play"
          skip="0"
        fi
      else
        log "create pause file"
        touch "$pause_file"
        skip="0"  # 0=true
      fi
    fi

    if [ "$skip" != 0 ]
    then
      log "do play"
      /usr/bin/mpc play 2>&1 >> "$log_f"
      rm -f "$pause_file"
    else
      log "skip do play"
    fi

  else
    log "already playing"
  fi
}

pause()
{
  if is_playing
  then
    log "do pause"
    /usr/bin/mpc pause 2>&1 >> "$log_f"
  else
    log "not playing"
  fi
}

log "tty=$tty"

case "$1" in
  OFF|off|pause|PAUSE)
    pause
    ;;
  ON|on|play|PLAY)
    play
    ;;
  *)
    is_playing
    ;;
esac

log

