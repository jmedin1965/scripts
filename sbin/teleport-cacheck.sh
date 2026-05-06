#!/bin/bash

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

info()
{
  echo "$(date): info: $*"
}

prog="$(basename "$0")"
log_f="/var/log/${prog%%.*}.log"

keep_cert="$(( 60 * 8 ))"
teleport_f="/etc/teleport_server.txt"
cert_f="/etc/ssh/teleport_user_ca.pub"
cert_o="/etc/ssh/teleport_user_ca.old.pub"
sshd_conf="/etc/ssh/sshd_config.d/teleport.conf"
sshd_conf_o="/etc/ssh/sshd_config.d/teleport-old.conf"

dirty="false" # do we need to reload sshd ?

# if we don't have a tty, log stdout and stderr to a file
if ! tty -s
then
  exec >> "$log_f" 2>&1
fi

# check logrotate
if [ -d "/etc/logrotate.d" ]
then
  if [ ! -e "/etc/logrotate.d/${prog##.*}" ]
  then
    info "no logrotate file found, creating one."
    echo "$log_f {
  rotate 12
  weekly
  compress
  missingok
  notifempty
}
" > "/etc/logrotate.d/${prog##.*}"
  fi
fi

# check teleport_f
# teleport_f is where we save the name and port of the teleport server
# that way, we don't need to find it the next time
teleport=""
if [ -e "$teleport_f" ]
then
  info try $teleport_f
  teleport="$(< "$teleport_f")"
  info got $teleport
  cert="$(curl --silent https://$teleport/webapi/auth/export?type=user)"
  [ $? != 0 ] && teleport=""
  info teleport = $teleport
fi

# find teleport server if we don't know what it is
if [ -z "$teleport" ]
then
  ports=("443" "444" "3080")
  # lets find the teleport server and port by checking resolv.conf and th eport list above
  for try in $(grep -e "^search" /etc/resolv.conf ) 
  do
    if [ "$try" != "search" ]
    then
      for port in "${ports[@]}"
      do
        teleport="teleport.$try:$port"
        info "try = $teleport"
        cert="$(curl --silent https://$teleport/webapi/auth/export?type=user)"
        if [ $? == 0 ]
        then
          echo "$teleport" > "$teleport_f"
          chmod 655 "$teleport_f"
          break 2
        else
          teleport=""
        fi
      done
    fi
  done
fi

info teleport = $teleport

# do this only if we know what the teleport server details are
if [ -n "$teleport" ]
then
  # grab the curent public certificate file
  cert="${cert##cert-authority }"

  # check if certificate file is the same as what we just got above
  # rotate to old and get new one if needed
  if [ -e "$cert_f" ]
  then
    if [ "$(md5sum < "$cert_f")" != "$(echo "$cert" | md5sum)" ]
    then
      info "cert not same, backing up."
      mv "$cert_f" "$cert_o"
      touch "$cert_o"
      if [ -e "$sshd_conf" ]
      then
        mv "$sshd_conf" "$sshd_conf_o"
        echo "TrustedUserCAKeys $cert_o" > "$sshd_conf_o"
      fi
      dirty="true"
    else
      info "cert same, keep."
    fi
  fi

  # check if we have an/previous certificat.
  # we keep it for keep_cert seconds as a grace period
  if [ -e "$cert_o" ]
  then
    now="$(date +%s)"
    seconds="$(stat -c %W "$cert_o")"
    seconds="$((now -seconds))"

    info file $cert_o
    info seconds = $seconds
    info keep_cert = $keep_cert

    # delete if greater that 8 hours
    if [ "$seconds" -gt "$keep_cert" ]
    then
      rm -f "$cert_o" "$sshd_conf_o"
      dirty="true"
    fi
  fi

  # grab a new public cert if we don't have one
  if [ ! -e "$cert_f" ]
  then
      info "geting new cert."
      echo $cert > "$cert_f"
      echo "TrustedUserCAKeys $cert_f" > "$sshd_conf"
      dirty="true"
  fi

  # debug, extract all 3 certificates from teleport
  if [ -n "$debug" ]
  then
    for c in openssh user host
    do
      cert="$(curl --silent https://$teleport/webapi/auth/export?type=${c})"
      info "ev = $?"
      cert="${cert##cert-authority }"
      info "$cert" > teleport_${c}_ca.pub
    done
  fi

else
  info "Unable to find the teleport server"
fi

# restart sshd if dirty
info dirty = $dirty
if [ "$dirty" == "true" ]
then
  systemctl reload ssh
  info "restarted sshd, ev = $?"
fi

