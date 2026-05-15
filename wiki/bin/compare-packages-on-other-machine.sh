

local=/tmp/installed-software-local.txt
remote=/tmp/installed-software-remote.txt

if [ $# == 0 ]
then
	echo "Usage: $(/usr/bin/basename $0) remote-machine ..."
else
	while [ $# != 0 ]
	do
		dpkg --get-selections > $local

		ssh "$1" "dpkg --get-selections" > $remote

		meld "$local" "$remote"

		echo "now do a \"dpkg --set-selections < $local\""
		echo "This will mark packages for installation. You can then use the synoptic package installer."
		shift
	done
fi

