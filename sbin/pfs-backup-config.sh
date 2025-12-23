#!/bin/sh

main()
{
        mount="/mnt"
        script="/root/`basename "$0"`"
        script_name="$mount/backup-config.sh"

        script_name="backup-config.sh"
        script_root="/root/$script_name"
        script_mount="$mount/$script_name"
        script="`/bin/realpath "$0"`"

        cron_f="/etc/cron.d/$script_name"

        opt_no_unmount="0"
        opt_no_cron="0"
        opt_mount_only="0"
	hostname="`/bin/hostname -s | /usr/bin/tr '[:upper:]' '[:lower:]'`"

        while [ -n "$1" ]
        do
                case "$1" in
                --no-unmount)   opt_no_unmount="1";;
                --no-umount)    opt_no_unmount="1";;
                --no-cron)      opt_no_cron="1";;
                --mount-only)   opt_mount_only="1";;
		backup)		;; # This is the default
                --format)
                                format "$2"
                                shift
                                ;;
                *)
                                echo
                                echo "Usage: `/usr/bin/basename "$0"` options..."
                                echo
                                echo "  --no-umount  - do not unmount $mount."
                                echo "  --no-cron    - do not install cron script."
                                echo "  --mount-only - just mount and exit."
                                echo "  --format dev - format dev and do a backup to this dev. please"
                                echo "                 NOTE that this dev will be completely cleared."
                                echo
                                exit 1
                                ;;
                esac

                shift
        done

        if [ "$opt_mount_only" == "1" ]
	then
		msg "mount only and exit."
		mount
		exit 0
	fi

        # if we are running this script from the /root folder
        if [ "$script" == "$script_root" ]
        then
                msg "$script_root: running from root"
                mount
                msg copy from $script
                /bin/cp -v "$script" "$script_mount"

        # if we are running from /mnt
        elif [ "$script" == "$script_mount" ]
        then
                msg copy script $script
                /bin/cp -v "$script" "$script_root"
                exec "$script_root" "$@"
        else
                msg "running from $script, must be a test so not copying"
                mount
        fi

        inst_pkg vim
        inst_pkg qemu-guest-agent
        inst_pkg git
        inst_cron

        copy "/conf"
        copy /var/db/rrd

        if [ -e /etc/rc.conf.local ]
        then
                copy /etc/rc.conf.local

        elif [ -e "$mount/etc/rc.conf.local" ]
        then
                msg "restoring $mount/etc/rc.conf.local from backup"
                /bin/cp "$mount/etc/rc.conf.local" /etc/rc.conf.local
                /bin/chmod 640 /etc/rc.conf.local
        fi

        copy_check /etc/ssh/ssh_host_*

        if [ "$opt_no_unmount" == 1 ]
        then
                msg not unmounting $mount
        else
                msg unmounting $mount
                /sbin/umount "$mount"
        fi

	# Generate /root/backup/pfsense.bak.tgz
	/usr/local/scripts/sbin/pfs-backup.php
	
	# now copy to backup shares01
	echo hostname=$hostname
	SSH_AUTH_SOCK=""
	/usr/bin/scp /root/backup/pfsense.bak.tgz "$hostname@shares01:"
	
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

	elif [ ! -b "$1" ]
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
		/sbin/gpart add -t \!12 dev

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
        if [ "$opt_no_cron" == 1 ]
        then
                msg "--no_-cron : skip install cron"
        else
                msg "adding skip install cron"

                echo "" > "$cron_f"
                echo "SHELL=/bin/sh" >> "$cron_f"
                echo "PATH=/etc:/bin:/sbin:/usr/bin:/usr/sbin" >> "$cron_f"
                echo "" >> "$cron_f"
                echo "*/10 * * * * root $script_root" >> "$cron_f"
        fi
}

copy()
{
        local d

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

                [ -d "$1" ] && d="`/usr/bin/dirname "$d"`"

                /bin/cp -vr "$1" "$d"

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

                elif [ "$a" == "type:" -a "$b" == fat32 ]
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
