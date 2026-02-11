#!/bin/bash

. /usr/local/sbin/local-functions

cd /
git add /etc/letsencrypt/*  2>&1 > /dev/null
git commit -m "letsencript auto commit" 2>&1 > /dev/null
[ "$(git diff /etc/hosts | wc -l)" == 0 ] && git add /etc/hosts
/usr/bin/git status > /tmp/git-check.txt 2>&1
#echo "$(/bin/fgrep -c "nothing to commit, working directory clean" /tmp/git-check.txt)"
if [ "$(/bin/fgrep -c "nothing to commit, working directory clean" /tmp/git-check.txt)" == 0 ]
then
	mail -s "git comit detected changes in $(/bin/hostname)" $mailTo < /tmp/git-check.txt > /dev/null
fi

exit 0

