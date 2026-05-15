#!/bin/bash
#

main()
{
	map_root="$HOME/mnt"
	pwd_files="$HOME/mnt/.pwd"
	rc_file="$HOME/.$(/usr/bin/basename "$0")rc"

	[ -d "$map_root" ] || /bin/mkdir -p "$map_root"
	[ -d "$pwd_files" ] || /bin/mkdir -p "$pwd_files"

	if [ -e "$rc_file" ]
	then
		/bin/cat "$rc_file" | while read name dev	
		do
			if [ -n "$name" -a "${name#\#}" == "$name" ]
			then
				map "$name" "$dev"
			fi
		done
	else
		usage
		echo "$rc_file: file does not exist" > /dev/stderr
		exit
	fi
}


is_mounted()
{
	[ "$(/bin/mount | /bin/fgrep -c "on $1 type")" -gt 0 ]
}

usage()
{
	(
		echo "Usage:"
		echo "        map drive share"
		echo "   or"
		echo "        map share"
	) > /dev/stderr

}

map()
{
	
	if [ -n "$1" -a -z "$2" ]
	then
		server="$(IFS='/';set -- $1;echo $1)"
		share="$(IFS='/';set -- $1;echo $2)"
		map_point="${map_root}/${server}/${share}"
		all=$1
		link=""

	elif [ -n "$1" -a -n "$2" ]
	then
		server="$(IFS='/';set -- $2;echo $1)"
		share="$(IFS='/';set -- $2;echo $2)"
		map_point="${map_root}/${server}/${share}"
		all=$2
		link="${map_root}/$1"
	else
		usage
		exit
	fi


	[ -f "${pwd_files}/${server}" ] && pwd="${pwd_files}/${server}"
	[ -f "${pwd_files}/${server}.${share}" ] && pwd="${pwd_files}/${server}.${share}"

	[ -d "$map_point" ] || /bin/mkdir -p "$map_point"

	local mntopts="credentials=$pwd,uid=$(/usr/bin/whoami),forceuid"

	ev=0
	if is_mounted "$map_point"
	then
		echo "$map_point: already mounted" > /dev/stderr
	else
		echo "args: server=$server, share=$share, map_point=$map_point, link=$link"
		echo "mntopts=$mntopts"

		/usr/bin/sudo \
			/bin/mount \
			"//${server}/${share}" \
			"$map_point" \
			-o \
			"$mntopts"
		ev=$?

		if [ "$ev" == 0 ] && [ -n "$link" ]
		then
			echo ln -fs "$all" "$link"
			rm "$link"
			ln -fs "$all" "$link"
		fi
	fi


	echo
}

main

