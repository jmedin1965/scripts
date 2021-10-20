#!/bin/bash

fgrep " on $1 type"
exit 0

index="1"
while [ "$(grep -c " nbd$index$" /proc/partitions)" != 0 ]
do
	echo index=$index
	((index++))
done

nbd="nbd$index"

echo "using dev $nbd"
exit 0


echo using dev /dev/$nbd

modprobe nbd
q /sysmu-nbd -r -c /dev/$nbd "$1"
cat /proc/partitions | fgrep ${nbd}p | while read major minor size part
do
	echo part=$part
	mkdir -p /mnt/$part
	mount -o ro,noload /dev/$part /mnt/$part
done
