#/bin/bash

ifs="$IFS"
IFS=" /:"
cd "$1"
if [ -d ".recycle" ]
then
	find ".recycle" | while read line
	do

	        set -- $line
	       	if [ $# == 7 ]
	       	then
	               	dir="@GMT-$2.$3.$4-$5.$6.$7"        
	               	/bin/mv "$line" "$dir"
	       	fi
	done
fi
IFS="$ifs"

