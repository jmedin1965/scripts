#!/bin/bash

num=0
fixed=0
do=0
do=1

wait=""
declare -A wait=()
devs=()
devs_f=()

ask()
{
	echo
	echo -n "$1 [y/n] ? "
	read ans
	case "$ans" in
		y*)	return 0;;
		*)	return 1;;
	esac
}

echo rescan scsi bus
for BUS in /sys/class/scsi_host/host*/scan
do
	echo rescan $BUS
	echo "- - -" > ${BUS}
done

if ! which sg_format
then
    echo
    echo "sg_format is not installed"
    echo "apt install sg3-utils"
    exit 1
fi

if [ -z "$TMUX" ]
then
	ask "not in tmux session. are you sure you want to continue" || exit 1
fi

echo
echo clear out old log files
echo
[ -d old ] || mkdir old
mv *.log old

echo
for dev in /dev/sg*
do
	name="$(basename "$dev")"


	info="$(sg_format $dev 2>/dev/null)"
	if [ "$(echo "$info" | fgrep -c "Block size=")" -gt 0 ]
	then
		echo -n "checking $dev $name : "

		if [ "$(echo "$info" | fgrep -c "Block size=520")" -gt 0 ]
		then
			echo "needs fixeng."
			devs+=("$dev")
			((num++))

		elif [ "$(echo "$info" | fgrep -c "NETAPP")" -gt 0 ]
		then
			echo "already fixed."
			devs_f+=("$dev")
			((fixed++))

		else
			echo "is ok"
		fi
	fi
done

echo
if [ "$fixed" -gt 1 ]
then
	if ask "force fix $fixed drives"
	then
		((num+=fixed))
		devs+=(${devs_f[@]})
	fi
fi
if [ "$num" -gt 1 ]
then
	ask "fix $num drives" || exit 1
fi

echo
for dev in "${devs[@]}"
do
	name="$(basename "$dev")"
	echo processing $dev $name

	echo "  fixing block size"

	if [ "$do" == 1 ]
	then
		(
			( time sg_format -v --format --size=512 $dev ) > ${name}.log 2>&1
		)&
		wait["$!"]="${name}.log"
		echo "  do=yes $!"
	else
		(
			( time sg_format $dev ) > ${name}.log 2>&1
		)&
		wait["$!"]="${name}.log"
		echo "  do=no $!"
	fi
done

for key in "${!wait[@]}"
do
	echo
	echo "waiting for $key ${wait[$key]}"
	wait $key
	cat "${wait[$key]}"
done

echo
echo "processed $num drives"
echo

