#!/bin/bash
#
# REF: https://snikt.net/blog/2014/04/07/how-to-convert-an-kvm-image-into-a-lxc-container/
#

to="/rpool/data/subvol-110-disk-0"
from="nbd1"
dryrun="t"
dryrun="f"


cp -a ${to}/etc/fstab .
cp -a ${to}/etc/network/interfaces .

cd "$from" || ( echo  cd failed, exiting; exit 1)

for f in *
do
	case "$f" in
	boot) echo '***' skipping: $f;;
	dev) echo '***' skipping: $f;;
	dev) echo '***' skipping: $f;;
	proc) echo '***' skipping: $f;;
	sys) echo '***' skipping: $f;;
	initrd.img.old) echo '***' skipping: $f;;
	lost+found) echo '***' skipping: $f;;
	vmlinuz.old) echo '***' skipping: $f;;
	*) 
		echo process $f
		if [ "$dryrun" == f ]
		then
			rm -rf "${to}/$f"
			cp -a "$f" "${to}/$f"
		fi
		;;

	esac
done

cp -a etc/fstab etc/network/interfaces "${to}/root"

cd ..

cp -a fstab      ${to}/etc/fstab
cp -a interfaces ${to}/etc/network/interfaces

cat > ${to}/apt-fix.sh << END
apt-get remove --purge acpid acpi
update-rc.d -f hwclock.sh remove
update-rc.d -f mountall.sh remove
update-rc.d -f checkfs.sh remove
update-rc.d -f udev remove
apt-get remove --purge grub-common grub-gfxpayload-lists grub-pc grub-pc-bin grub2-common
apt-get remove --purge docker-ce docker-ce-cli
apt-get remove --purge isc-dhcp-client isc-dhcp-common
apt-get remove --purge dns-root-data dnsmasq dnsmasq-base 
apt-get remove --purge open-vm-tools
apt-get remove --purge dhcpcd5
END
chmod 755 ${to}/apt-fix.sh

