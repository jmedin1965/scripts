#!/bin/bash

apt list --installed ruby\* foreman\* | ( 
failed=()
while read package rest
do
    if [ -n "$rest" ]
    then
        package="${package%%/*}"
        echo
        echo process: $package
        apt-get --reinstall install $package
        [ $? != 0 ] && failed+=( "$package" )
    fi
done

echo
echo all done
echo

for f in "${failed[@]}"
do
    echo "$f - failed"
done
)
