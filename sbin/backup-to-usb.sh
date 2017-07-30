
if [ "$(/bin/mount | /bin/fgrep -c " /mnt/Seagate ")" -gt 0 ]
then
	echo dir:$d >> /var/log/rsync-backup-to-usb.log
	d="datastore2"
	/usr/bin/rsync	\
		-a						\
		-AX						\
		--log-file=/var/log/rsync-backup-to-usb.log	\
		/mnt/vg01/$d/ 					\
		/mnt/Seagate/$d/

	d="groups"
	echo dir:$d >> /var/log/rsync-backup-to-usb.log
	/usr/bin/rsync	\
		-a						\
		--delete-excluded				\
		-AX						\
		--log-file=/var/log/rsync-backup-to-usb.log	\
		--exclude=/media/media/videos-chinese/		\
		/mnt/vg01/$d/ 					\
		/mnt/Seagate/$d/
fi

