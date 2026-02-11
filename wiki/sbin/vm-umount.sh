#!/bin/bash

vm_id="104"
vm_name="root"


#/dev/rpool/data/vm-103-disk-1
#umount  ${vm_name}/sys/
#umount  ${vm_name}/proc/
#umount  ${vm_name}/dev/
umount  ${vm_name}/var/updatecache
umount  ${vm_name}/mnt
umount  ${vm_name}/var/log
umount  ${vm_name}/boot/efi
umount  ${vm_name}/boot
umount  ${vm_name}
