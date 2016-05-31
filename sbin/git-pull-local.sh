#!/bin/bash

cd /usr/local
if [ -d .git ]
then
	echo "git exists"
	git pull
	echo ev=$?
fi

