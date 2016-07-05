#!/bin/bash

hostname="$(/bin/hostname)"
prog="/usr/bin/git pull"
log=""
sucessMsg="Already up-to-date."
mailSubject="${prog##*/} for /usr/local from $hostname"
mailTo="root"

case "$hostname" in
"ipfire")
	cd /root/local;;
*)
	cd /usr/local;;
esac

pwd="$(pwd)"

[ -d .git ] || (echo "$pwd: not a git repo"; exit 1)

msg="$($prog 2>&1; echo ;echo EV = $?)"
[ -n "$log" ] && echo "$msg" >> "$log"
if [ "$(echo "$msg" | /bin/fgrep -c "$sucessMsg")" -eq 0 ]
then
	if [ -x /usr/bin/mail ]
	then
		echo "$msg" | /usr/bin/mail -s "$mailSubject" $mailTo
		
	elif [ -x /usr/local/bin/sendEmail ]
	then
		echo "$msg" | /usr/local/bin/sendEmail \
			-f root@ipfire.jmsh-home.dtdns.net \
			-t jmedin@joy.com \
			-s smtp.dodo.com \
			-u "$mailSubject"
	fi
fi
