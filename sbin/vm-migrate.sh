#!/bin/bash

if [ $# != 2 ]
then
	echo "Usage: $(basename "$0") vm_dir vm_id"
	exit 1
fi

vm_id="$2"
vm_dir="$1"
vm_pool="local-zfs"

echo
echo vm_id = $vm_id
echo vm_dir = $vm_dir
echo vm_pool = $vm_pool
echo

if [ -e "/etc/pve/qemu-server/${vm_id}.conf" ]
then
	echo -n "VM with id of $vm_id already exists, continue [y/n] ? "
	read ans
	case "$ans" in
	'y'|'Y')	;;
	*)	exit 0;;
	esac
else
	echo -n "Continue [y/n] ? "
	read ans
	case "$ans" in
	'y'|'Y')	;;
	*)	exit 0;;
	esac
fi

i="0"
for disk in "$vm_dir"/*-flat.vmdk
do
	d="${disk%-flat.vmdk}.vmdk"
	echo processing disk $d
	qm importdisk "$vm_id" "$d" "$vm_pool" --format raw
	#qemu-img convert -p -O raw "$disk" /dev/zvol/rpool/data/vm-103-disk-0
	echo
	((i++))
done

exit 0

