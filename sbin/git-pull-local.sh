#!/bin/bash

cd /usr/local
[ -d .git ] || (echo "/usr/log: not a git repo"; exit 1)

prog="/usr/bin/git pull"
log=""
sucessMsg="Already up-to-date."
mailSubject="${prog##*/} for /usr/local from $(/bin/hostname)"
mailTo="root"

msg="$($prog 2>&1; echo ;echo EV = $?)"
[ -n "$log" ] && echo "$msg" >> "$log"
if [ "$(echo "$msg" | /bin/fgrep -c "$sucessMsg")" -eq 0 ]
then
	echo "$msg" | /usr/bin/mail -s "$mailSubject" $mailTo
fi

