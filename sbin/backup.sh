
backup_dir=/backups
backup_date=$(/bin/date +%F)
backup_hostname=$(/bin/hostname -s)
backup_filename=${backup_dir}/${backup_hostname}-system-tar-${backup_date}
log_filename=${backup_dir}/${backup_hostname}-system-log-${backup_date}
max_keep=5
backup_source="
/etc
/var/spool/cron	
/usr/local
/root
"

[ -d "$backup_dir" ] || mkdir -p "$backup_dir"

/bin/tar -vpczf \
	"${backup_filename}.gz" \
	$backup_source > "$log_filename" 2>&1

[ $? == 0 ] || cat "$log_filename"

/bin/gzip "$log_filename"
