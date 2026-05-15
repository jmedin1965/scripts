#!/bin/bash

#
# REF: https://superuser.com/questions/919895/how-to-get-a-list-of-connected-nbd-devices-on-ubuntu
#

modprobe nbd

nbd=""
for dev in /sys/class/block/nbd[0-9]*
do
	# don't user device 0
	if [ "$(<$dev/size)" == 0 -a "$dev" != /sys/class/block/nbd0 ]
	then
		nbd="$(basename "$dev")"
		break
	fi
done

mnt_point="/root/mnt"
mnt_point="/mnt"

if [ -n "$nbd" ]
then
	echo "using dev $nbd"

	qemu-nbd -r -c /dev/$nbd "$1"
	cat /proc/partitions | fgrep ${nbd} | while read major minor size part
	do
		echo part=$part
		blkid="$(blkid /dev/$part)"
		case "$blkid" in
		*' TYPE="ext2" '*)
			echo $part is exe2
			mkdir -p ${mnt_point}/$part
			mount -o ro /dev/$part ${mnt_point}/$part
			;;
		*' TYPE="ext3" '*)
			echo $part is exe3
			mkdir -p ${mnt_point}/$part
			mount -o ro,noload /dev/$part ${mnt_point}/$part
			;;
		*' TYPE="ext4" '*)
			echo $part is exe4
			mkdir -p ${mnt_point}/$part
			mount -o ro,noload /dev/$part ${mnt_point}/$part
			;;
		*)
			echo unknown: $blkid
			;;
		esac
	done

	exit 0
else
	echo "no free device found"
fi

		if [ -n "$part" ]
		then
			echo part=$part
			mkdir -p /mnt/$part
			echo "try: mount -o ro,noload /dev/$part /mnt/$part"
			mount -o ro,noload /dev/$part /mnt/$part
		else
			echo part=$nbd
			mkdir -p /mnt/$part
			echo "try: mount -o ro,noload /dev/$part /mnt/$part"
			mount -o ro,noload /dev/$part /mnt/$part
		fi

