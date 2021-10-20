#!/bin/bash

if [ "$1" == '--help' -o "$1" == '-h' ]
then
	echo "Usage: $(basename "$0") vm_id full_disk_path disk_size"
	exit 0
fi

if [ $# -gt 0 ]
then
	vm_id="$1"
else
	echo -n "Enter vm ip number : "
	read vm_id
fi

echo

if [ $# -gt 1 ]
then
	full_disk_path="$2"
else
	full_disk_path="/rpool/data/subvol-${vm_id}-"
fi

for disk in "${full_disk_path}"*
do
	echo "${disk}:  $(zfs get refquota ${disk} | fgrep refquota)"
done

echo

if [ $# -gt 1 ]
then
	disk_num="$2"
else
	echo -n "Enter full path to disk : "
	read full_disk_path
fi

if [ $# -gt 2 ]
then
	disk_size="$3"
else
	echo -n "Enter disk_size : "
	read disk_size
fi

case "$full_disk_path" in
/*)	full_disk_path=${full_disk_path#/};;
esac

echo
echo Changing:
echo
echo "full_disk_path = $full_disk_path"
echo "disk_size      = $disk_size"
echo

echo
#zfs get all rpool/data/vm-109-disk-0 rpool/data/vm-109-disk-1 rpool/data/vm-109-disk-2 | fgrep volsize

echo -n "Press ENTER to continue: "
read ans

zfs set "refquota=$disk_size" "$full_disk_path"


