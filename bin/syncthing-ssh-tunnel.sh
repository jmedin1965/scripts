#!/bin/bash
#
port="8384"

if [ -z "$1" ]
then
    echo Usage $(basename "$0") remote-host
    exit 1
fi

echo port $port from host $1 will be available locally

/mnt/c/Program\ Files/WSL/wslg.exe -d Ubuntu-24.04 --cd "~" -- /snap/bin/chromium https://localhost:$port

ssh -L 8384:localhost:8384 -J jmedin@192.168.10.127 root@$1 -N

