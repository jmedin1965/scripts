#!/bin/bash

# REF: https://github.com/gravitational/teleport/discussions/5530
#

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

TSH=$(which tsh)
if [ -z "$TSH" -o  ! -f ${TSH} ]; then
    echo "Cannot find tsh at '${TSH}'" > /dev/tty
    exit 2
fi

if ! command -v ssh-keygen; then
    echo "Cannot find ssh-keygen" > /dev/tty
    exit 2
fi

if [[ "$1" == "" ]]; then
    echo "Usage: $(basename $0) <proxy> <username>" > /dev/tty
    exit 1
fi
PROXY=$1

if [[ "$2" == "" ]]; then
    echo "Usage: $(basename $0) <proxy> <username>" > /dev/tty
    exit 2
fi
USERNAME=$2

if [ -f ~/.tsh/keys/${PROXY}/${USERNAME} ]; then
    # the date command is different on OS X, of course
    if [[ $OSTYPE == darwin* ]]; then
        EXPIRY_TIME=$(date -j -f '%Y-%m-%dT%H:%M:%S' `ssh-keygen -Lf ~/.tsh/keys/${PROXY}/${USERNAME}-cert.pub | grep Valid | cut -d' ' -f13` +%s)
    elif [[ $OSTYPE == linux* ]]; then
        EXPIRY_TIME=$(date -d `ssh-keygen -Lf ~/.tsh/keys/${PROXY}/${USERNAME}-cert.pub | grep Valid | cut -d' ' -f13` +%s)
    else
        echo "Unsupported OS '${OSTYPE}'" > /dev/tty
        exit 2
    fi

    NOW=$(date +%s)
    if [ ${NOW} -lt ${EXPIRY_TIME} ]; then
        exit 0
    fi
fi

LOGIN_STATUS=$(${TSH} status)
if [ -z "$LOGIN_STATUS" ]
then
      echo "Please login first using tsh login ... and try again" > /dev/tty
      exit 2
else
      echo "Done login script"
fi

# ${TSH} login --proxy=${PROXY} --user=${USERNAME}
#
