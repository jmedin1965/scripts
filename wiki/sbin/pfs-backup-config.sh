#!/bin/sh

opt_no_unmount="0"
opt_mount_only="0"

main()
{
	path="$PATH"
	export PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin

        mount="/mnt"
        script_root="`realpath "$0"`"
        script_name="`basename "$0"`"
	backup_dir="/root/backup"

        cron_f="/etc/cron.d/$script_name"

	hostname="`/bin/hostname -s | /usr/bin/tr '[:upper:]' '[:lower:]'`"

	for arg in "$@"
	do
		case "$arg" in
		-*)
			case "$arg" in
			--no-unmount)   opt_no_unmount="1";;
			--no-umount)    opt_no_unmount="1";;
			*)
				usage "$arg: unknown option"
				;;
			esac
			;;
		*);;
		esac
	done

        while [ -n "$1" ]
        do
		case "$1" in
		-*);;
		*)
			case "$1" in
				backup)		backup;;
				mount)		mount;;
				cron)		inst_cron;;
				check-keys)	check_keys;;
				format)
					if [ $# -gt 1 ]
					then
						format "$2"
						shift
					else
						usage "--format needs and option, dev to be formater."
					fi
					;;
				*)
					usage "$1: unknown command"
					;;
			esac
			;;
		esac
                shift
        done
}

backup()
{
        inst_pkg vim
        inst_pkg qemu-guest-agent
        inst_pkg git
	inst_pkg pfSense-pkg-Backup
	inst_pkg rsync

	mount

	dest="$mount"
	dest="/root/backup/test"
	php_backup_script="/usr/local/www/packages/backup/backup.php"

        copy "/conf/config.xml"
        copy "/conf/backup"

	/usr/local/bin/php -f $php_backup_script | (
		while read status data
		do
			case "$status" in
			created:)
				echo created $data
				[ -d "$mount/backup" ] || mkdir "$mount/backup"
				cp "$data" "$mount/backup"
				
				# now copy to backup shares01
				echo hostname=$hostname
				SSH_AUTH_SOCK=""
				/usr/bin/scp "$data" "$hostname@shares01:"
				;;
			error:)
				echo "got an error: $data"
				;;
			*)
				echo "got unknown: $status: $data"
				;;
			esac
		done
	)

        #copy_check /etc/ssh/ssh_host_*

        if [ "$opt_no_unmount" == 1 ]
        then
                msg not unmounting $mount
        else
                msg unmounting $mount
                /sbin/umount "$mount"
        fi

	PATH="$path"
}

usage()
{
	(
	if [ $# != 0 ]
	then
		echo
		while [ $# != 0 ]
		do
			echo "$1"
			shift
		done
	fi

	echo "Usage: $script_name options... commands..."
	echo
	echo "options"
	echo "  --no-unmount - do not unmount $mount."
	echo "  --no-umount  - do not unmount $mount."
	echo "  --format dev - format dev."
	echo "                 NOTE: This dev will be completely cleared."
	echo "commands"
	echo "  backup     - perform a backup, and install cron"
	echo "  mount      - just mount and exit."
	echo "  check-keys - check host ssh keys and compare with backup file"
	echo "  cron       - add cron to do regular backups"
	echo
	) > /dev/stderr
	exit 1
}

msg()
{
        echo "`/bin/date`" "$@"
}

format()
{
        msg "attempt to format $1"
        if [ -z "$1" ]
	then
                msg "  $1: need to specify a device to format"

	elif [ ! -c "$1" ]
        then
                msg "  $1: device does exist"
        else
		dev="`/usr/bin/basename "$1"`"

		# REF: https://forums.freebsd.org/threads/gpart-cheatsheet-wiping-drives-partitioning-formating.45411/

		# WIPE THE PLATTER
		/sbin/gpart destroy -F $dev

		# PLACE A BLANK PARTITION ON IT
		/sbin/gpart create -s mbr $dev

		# FILL THE MSDOS PARTITION
		/sbin/gpart add -t \!12 $dev

		# FORMAT IT MSDOS STYLE (fat32)
                /sbin/newfs_msdos -F16 "${1}s1"

                msg "  mounting ${1}s1 on $mount"

                /sbin/mount -t msdosfs "${1}s1" $mount

                if [ $? == 0 ]
                then
                        msg "  format worked and mount suceeded"
                else
                        msg "  format failed"
                        exit 1
                fi

	fi
}

format_old()
{
        msg "attempt to format $1"
        if [ -n "$1" -a -b "$1" ]
        then
                msg "  $1 does exist"
        else
                msg "  $1: need to specify a device to format"

                /bin/dd if=/dev/zero of="$1" count=10

                (
                        echo n
                        echo y
                        echo 11
                        echo
                        echo
                        echo n
                        echo y
                        echo n
                        echo n
                        echo n
                        echo n
                        echo y

                ) | /sbin/fdisk -u "$1"

                /sbin/fdisk "$1"

                /sbin/newfs_msdos -F16 "${1}s1"

                msg "  mounting ${1}s1 on $mount"

                /sbin/mount -t msdosfs "${1}s1" $mount

                if [ $? == 0 ]
                then
                        msg "  format worked and mount suceeded"
                else
                        msg "  format failed"
                        exit 1
                fi
        fi
}

inst_pkg()
{
        if [ -z "$1" ]
        then
                echo Usage: inst_pkg package

        elif [ `/usr/sbin/pkg info | /usr/bin/grep -c "^$1-"` == 0 ]
        then
                echo not installed $1
                /usr/sbin/pkg install -y "$1"
        else
                echo $1: is already installed
        fi
}

inst_cron()
{
	msg "adding cron"

	(
	echo "#"
	echo "# added by $script_root"
	echo "# WARNING: Do not edit this file, your changes will be lost."
	echo "#"
	echo 
	echo "SHELL=/bin/sh"
	echo "PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin"
	echo ""
	echo "*/10 * * * * root $script_root"
	) > "$cron_f"
}

copy()
{
        local d

	local cmd="/usr/local/bin/rsync -av --delete --exclude $backup_dir/"
	local cmd="/usr/local/bin/rsync -rt -v --delete"

        while [ -n "$1" ]
        do
                if [ -d "$1" ]
                then
                        d="$mount/$1"
                else
                        d="$mount/`/usr/bin/dirname "$1"`"
                fi

                if [ ! -d "$d" ]
                then
                        /bin/mkdir -p "$d"
                fi

                if [ -d "$1" ]
		then
			$cmd "$1/" "$mount$1/"
			echo $cmd "$1/" "$mount$1/"
		else
			$cmd "$1" "$mount$1"
			echo $cmd "$1" "$mount$1"
		fi

                shift
        done
}

copy_check()
{
        local d
        local i
        local bak=""

        while [ -n "$1" ]
        do
                if [ -d "$1" ]
                then
                        msg "$1: skipped, not a file"

                elif [ ! -e "$mount/$1" ]
                then
                        copy "$1"
                else
                        d="`/usr/bin/dirname "$1"`"
                        msg "$1: checking"
                        msg "  d=$d"
                        if [ "`/sbin/md5sum < "$1"`" == "`/sbin/md5sum < "$mount/$1"`" ]
                        then
                                msg "  both same, skipping backup"
                        else
                                msg "  backup orig and restore"
                                #find a folder to make a backup
                                if [ -z "$bak" ]
                                then
                                        i="0"
                                        bak="$mount/$d.backup.$i"
                                        while [ -d "$bak" ]
                                        do
                                                i="`/bin/expr $i + 1`"
                                                bak="$mount/$d.backup.$i"
                                        done
                                        /bin/mkdir "$bak"
                                fi
                                msg "  found bak=$bak"
                                msg "  restore $mount/$1 to $1"
                                /bin/cp -vr "$1" "$bak" && /bin/cp -vr "$mount/$1" "$1"
                        fi
                fi

                shift
        done
}

# will find the first msdosfs patrition and mount it on $mount
mount()
{
        local name
        local type
        local a b c

        if [ "`/sbin/mount | /usr/bin/fgrep -ce " $mount "`" != 0 ]
        then
                msg already mounted on $mount
                return 1
        fi

        /sbin/gpart list | /usr/bin/fgrep -e " Name: " -e " type: " | (
        while read a b c
        do
                if [ "$b" == Name: ]
                then
                        name="$c"
                        type=""

                elif [ "$a" == "type:" ] && [ "$b" == fat32 -o "$b" == fat32lba  ]
                then
                        type="$b"
                        msg /sbin/mount -t msdosfs "/dev/$name" "$mount"
                        /sbin/mount -t msdosfs "/dev/$name" "$mount"
                        return $?
                fi
        done
        return 1
        )

        if [ $? != 0 ]
        then
                msg "error: failed to mount $mount, exiting"
                exit 1
        fi

        return 0
}

main "$@"

