
cd /
git add /etc/letsencrypt/*  2>&1 /dev/null
git commit -m "letsencript auto commit" 2>&1 /dev/null
[ "$(git diff /etc/hosts | wc -l)" == 0 ] && git add /etc/hosts
/usr/bin/git status > /tmp/git-check.txt 2>&1
#echo "$(/bin/fgrep -c "nothing to commit, working directory clean" /tmp/git-check.txt)"
if [ "$(/bin/fgrep -c "nothing to commit, working directory clean" /tmp/git-check.txt)" == 0 ]
then
	if [ -x /usr/bin/mail ]
	then
		/usr/bin/mail \
			-s "git comit detected changes in $(/bin/hostname)" \
			root < /tmp/git-check.txt
		
	elif [ -x /usr/local/bin/sendEmail ]
	then
		/usr/local/bin/sendEmail \
			-f root@ipfire.jmsh-home.dtdns.net \
			-t jmedin@joy.com \
			-s smtp.dodo.com \
			-u "git comit detected changes in $(/bin/hostname)" \
			-o message-file=/tmp/git-check.txt
	fi
fi
