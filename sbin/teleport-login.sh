#!/bin/bash

# REF: https://github.com/gravitational/teleport/discussions/5530
#

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

usage()
{
  echo "Usage:
  $(basename $0) <proxy> <username>
or
  $(basename $0) <username>, if TELEPORT_PROXY is set
or
  $(basename $0), if TELEPORT_PROXY is set, and current USER will be used as username
" > /dev/tty 
  exit 1
}

get_key_info()
{
    local date
    local arg1 arg2 arg3 arg4 arg5 rest
    local NOW=$(date +%s)

    EXPIRY_TIME=""
    KeyID=""
    KeyValid="false"

    while read arg1 arg2 arg3 arg4 arg5 rest
    do
        case "$arg1" in
          "Valid:") date="$arg5";;
          "Key")    [ "$arg2" == "ID:" ] && KeyID="$arg3" && KeyID=${KeyID##\"} && KeyID=${KeyID%%\"};;
        esac
    done <<< "$(ssh-keygen -Lf - 2> /dev/null)"

    if [ -n "$date" ]
    then
        # the date command is different on OS X, of course
        if [[ $OSTYPE == darwin* ]]; then
            EXPIRY_TIME=$(date -j -f '%Y-%m-%dT%H:%M:%S' "$date" +%s)
        elif [[ $OSTYPE == linux* ]]; then
            EXPIRY_TIME=$(date -d "$date" +%s)
        else
            info "Unsupported OS '${OSTYPE}'"
            exit 2
        fi

        [ "${NOW}" -lt "${EXPIRY_TIME}" ] && KeyValid="true"
    fi
}

info()
{
  echo "Info: $*" > /dev/tty
}

echo PROXY=$PROXY

# find tsh command
TSH=$(which tsh)
if [ -z "$TSH" -o  ! -f ${TSH} ]; then
    info "Cannot find tsh at '${TSH}'"
    exit 2
fi

# check ssh-keygen and ssh-add
for command in ssh-keygen ssh-add
do
  if ! command -v $command > /dev/null 2>&1
  then
      info "Cannot find $command"
      exit 2
  fi
done

PROXY="${TELEPORT_PROXY%%:*}"
USERNAME="$USER"
if [ $# == 1 ]
then
  USERNAME="$1"

elif [ $# -gt 1 ]
then
  PROXY="$2"
  USERNAME="$1"
fi

if [ -z "$PROXY" ] || [ -z "$USERNAME" ]
then
  usage
fi

echo USERNAME=$USERNAME
echo

if [ -f ~/.tsh/keys/${PROXY}/${USERNAME}-cert.pub ]
then
  EXPIRY_TIME="$(get_expiry < ~/.tsh/keys/${PROXY}/${USERNAME}-cert.pub)"
echo EXPIRY_TIME=$EXPIRY_TIME
else
    # as far as I can tell, the certificate is in ssh-agent now
    while read key
    do
        get_key_info <<< "$(echo "$key")"
echo USERNAME=\"$USERNAME\"
echo KeyID=\"$KeyID\"
echo EXPIRY_TIME=\"$EXPIRY_TIME\"
echo NOW=\"$NOW\"
echo
        if [ "$KeyValid" == "true" ] && [ "$USERNAME" == "$KeyID" ]
        then
            info "found valid cert."
            exit 0
        fi

    done <<< "$(ssh-add -L)"
fi

if LOGIN_STATUS=$(${TSH} status)
then
      info "Done login script"
else
  if [[ "$TERM" =~ ^tmux- ]]
  then
    info "in tmux"
    tmux display-popup -E "${TSH} login --proxy=${PROXY} --user=${USERNAME}"
    if [ $? == 0 ]
    then
      info "logged in OK"
    else
      info "login failed"
    fi
  else
    info "Please login first using tsh login ... and try again"
    exit 2
  fi
fi

