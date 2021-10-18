#!/bin/bash

if [ "$1" == '--help' -o "$1" == '-h' ]
then
	echo "Usage: $(basename "$0") vm_id num_from num_to"
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

for disk in "/dev/rpool/data/vm-${vm_id}-disk-"*
do
    disk="${disk#/dev/}"
    case "$disk" in
        *-part*) ;;
        *)      zfs get volsize ${disk} | grep "^${disk}";;
    esac
done

echo

if [ $# -gt 1 ]
then
	from_disk="$2"
else
    echo -n "Enter from_disk (the part after the -disk-) : "
	read from_disk
fi

if [ $# -gt 2 ]
then
	from_disk="$3"
else
    echo -n "Enter to_disk number (if doesn't exist, then will rename) : "
	read to_disk
fi

from_disk="rpool/data/vm-${vm_id}-disk-$from_disk"
to_disk="rpool/data/vm-${vm_id}-disk-$to_disk"
rename_disk=""

if [ ! -e "/dev/$from_disk" ]
then
	echo /dev/$from_disk: disk does not exist
	exit 1
fi

if [ ! -e "/dev/$to_disk" ]
then
    rename_disk="$to_disk"
    to_disk=""
fi

echo
if [ -z "$rename_disk" ]
then
    echo Swapping disk names
else
    echo Renaming disk:
fi
echo
echo "vm_id       = $vm_id"
echo "from_disk   = $from_disk"
if [ -z "$rename_disk" ]
then
    echo "to_disk     = $to_disk"
else
    echo "rename_disk = $rename_disk"
fi

echo
#zfs get all rpool/data/vm-109-disk-0 rpool/data/vm-109-disk-1 rpool/data/vm-109-disk-2 | fgrep volsize

echo -n "Press ENTER to continue: "
read ans

if [ -z "$rename_disk" ]
then
    zfs rename "$from_disk" "${from_disk}_tmp"
    zfs rename "$to_disk" "${from_disk}"
    zfs rename "${from_disk}_tmp" "$to_disk"
else
    zfs rename "$from_disk" "${rename_disk}"
    echo
    echo "don't forget to rename disk in vm conf file"
    echo
fi


