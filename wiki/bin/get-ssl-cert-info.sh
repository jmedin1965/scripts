
[ $# == 0 ] && echo "Usage: $(/bin/basename "$0" cert...)" && exit 1

while [ $# != 0 ]
do
	if [ ! -e "$1" ]
	then
		echo "$1: cert not found"
	else
		/usr/bin/openssl x509 -in "$1" -text
	fi
	shift
done
