#!/bin/bash

#
# resise zvol = zfs set volsize=3G
#

vm_id="104"
vm_name="root"

mkdir -p $vm_name
#/dev/rpool/data/vm-${vm_id}-disk-1
mount /dev/rpool/data/vm-${vm_id}-disk-2 ${vm_name}
mount /dev/rpool/data/vm-${vm_id}-disk-0-part1 ${vm_name}/boot
mount /dev/rpool/data/vm-${vm_id}-disk-0-part2 ${vm_name}/boot/efi

mount /dev/rpool/data/vm-${vm_id}-disk-3 ${vm_name}/var/log
mount /dev/rpool/data/vm-${vm_id}-disk-4 ${vm_name}/var/updatecache

#mount --bind /sys/  ${vm_name}/sys/
#mount --bind /proc/ ${vm_name}/proc/
#mount --bind /dev/  ${vm_name}/dev/

cd ${vm_name}

cat > ./fix.sh << END
pakfire remove apcupsd
rm -f /etc/init.d/apcupsd_shutdown
pakfire remove openvmtools
END
chmod 755 ./fix.sh

chroot . /bin/bash

