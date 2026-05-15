#!/bin/bash -l

export PATH="/usr/local/scripts/sbin:/usr/local/scripts/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"

cd /tmp

nohup "$@" >/dev/null 2>&1 &

sleep 1

