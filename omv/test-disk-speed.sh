
if [ $# == 0 ]
then
	set tempfile
fi

while [ $# != 0 ]
do
	echo '***' testing on file $1
	sync; dd if=/dev/zero "of=$1" bs=1M count=1024; sync
    rm "$1"
	echo
	shift
done
exit 0

#sync; dd if=/dev/zero of=../tempfile bs=1M count=1024; sync
