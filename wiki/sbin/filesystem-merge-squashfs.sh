#
# REF: http://davstott.me.uk/index.php/2013/09/05/ubuntu-13-04-on-a-usb-flash-drive-and-merging-its-persistent-storage/
#

cd /cdrom/utils/zorin-os-9-core-32-persistent-casper/ || (echo "unable to cd to working directoryi"; exit 1)

if [ ! -d usblive ]
then
	mkdir usblive
	echo '*** mkdir usblive'
fi

if [ ! -d new ]
then
	mkdir new
	echo '*** mkdir new'
fi

echo '*** move filesystem.squashfs to old '
if [ ! mv filesystem.squashfs old ] 
then
	echo '*** move failed'
	exit 1
fi

echo '*** backup casper-rw to old '
if [ ! cp casper-rw old ] 
then
	echo '*** backup failed'
	exit 1
fi

cd usblive
[ $? == 0 ] || (echo '***' failed: cd usblive; exit 1)

for d in readonly readwrite merged
do
	echo '***' mkdir $d
	[ -d "$d" ] || mkdir "$d"
	[ $? == 0 ] || (echo '***' failed: mkdir $d; exit 1)
done

echo '***' mount ../old/filesystem.squashfs readonly -o loop,ro
mount ../old/filesystem.squashfs readonly -o loop,ro
if [ $? != 0 ] 
then
	echo mount failed
	exit 1
fi

echo '***' mount ../old/casper-rw readwrite -o loop,rw
mount ../old/casper-rw readwrite -o loop,rw
if [ $? != 0 ]
then
	echo mount failed
	exit 1
fi

echo '***' mount none merged -o lowerdir=readonly,upperdir=readwrite -t overlayfs
mount none merged -o lowerdir=readonly,upperdir=readwrite -t overlayfs
if [ $? != 0 ]
then
	echo mount failed
	exit 1
fi

echo

df -h

echo

mksquashfs merged ../filesystem.squashfs
if [ $? != 0 ]
then
	echo mksquashfs failed
	exit 1
fi

umount *
mkfs.ext4 -L casper-rw ../casper-rw

