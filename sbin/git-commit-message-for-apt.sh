#!/bin/bash

export packages="$(/bin/cat)"

cd /

echo "git add -A" >> /tmp/log-1.txt
/usr/bin/git add -A >> /tmp/log-1.txt
echo >> /tmp/log-1.txt
echo "Packages:" >> /tmp/log-1.txt
echo "$packages" >> /tmp/log-1.txt


(
	echo
	echo "====== $(/bin/date) : aptitude packages updates ======"
	echo "$packages"

) | /usr/bin/git commit -F -

echo "exit code $?" >> /tmp/log-1.txt

exit 0
