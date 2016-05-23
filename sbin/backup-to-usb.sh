
if [ "$(/bin/mount | /bin/fgrep -c " /mnt/Seagate ")" -gt 0 ]
then
	for d in datastore2 groups
	do
		echo dir:$d >> /var/log/rsync-backup-to-usb.log
		/usr/bin/rsync	\
			-a						\
			-AX						\
			--log-file=/var/log/rsync-backup-to-usb.log	\
			/mnt/vg01/$d/ 					\
			/mnt/Seagate/$d/
	done
fi

