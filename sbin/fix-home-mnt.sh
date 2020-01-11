#!/bin/bash


if [ "$(mount | fgrep " /home " | fgrep -c /dev/mapper/)" -gt 0 ]
then
	umount /home
	lvremove /dev/vg00/home
	lvresize -l 100%FREE /dev/vg00/root
	resize2fs /dev/vg00/root
	cp /etc/fstab /etc/fstab.old
	fgrep -v  /home  /etc/fstab.old > /etc/fstab
fi

