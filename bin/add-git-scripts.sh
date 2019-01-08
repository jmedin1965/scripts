#!/bin/bash

if [ ! -d /opt/git-repo/local/.git ]; then
	echo "/opt/git-repo/local/.git: folder does not exist"
	exit 1

elif [ -d /usr/local/scripts ]; then
	echo "/usr/local/scripts/.git: folder already exist"
	exit 1

else
	cd /usr/local
	git clone /opt/git-repo/local scripts
fi


