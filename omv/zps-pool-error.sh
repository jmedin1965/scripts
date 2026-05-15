#!/bin/bash

echo
echo REF: https://dannyda.com/2022/05/02/how-to-fix-openmediavault-zfs-pool-acl-privileges-error-failed-to-execute-command-export-operation-not-supported/
echo
echo "make sure"
echo "  acltype=posix"
echo "  aclmode=groupmask"
echo "  aclinherit=restricted"
echo

for set in acltype aclmode aclinherit
do
	echo check $set
	zfs get $set
	echo
done

echo -n "press enter to continue"
read ans

zfs set aclmode=groupmask rpool
zfs set acltype=posixacl zpool
zfs set aclinherit=restricted zpool
