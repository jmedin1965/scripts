#!/bin/bash

if [ ! -d /opt/git-repo/local/.git ]; then
	echo "/opt/git-repo/local/.git: folder does not exist"
	exit 1

elif [ -d /usr/local/scripts ]; then
	echo "/usr/local/scripts/.git: folder already exist"

else
	cd /usr/local
	git clone /opt/git-repo/local scripts
fi

cd /usr/local/scripts
git pull

if [ -e /usr/local/scripts/sbin/usr-local-path.sh -a ! -e /etc/profile.d/usr-local-path.sh ]
then
	ln -s /usr/local/scripts/sbin/usr-local-path.sh /etc/profile.d/usr-local-path.sh
fi
