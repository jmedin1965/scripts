#!/usr/bin/env bash

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

root="$(dirname "$(realpath "$0")")"
name="$(basename "$0")"
pwd="$(pwd)"
patch=""

# check if we are already in the patch directory
if [ "$(basename "$(dirname "$pwd")")" == System_Patches ]
then
	# we are in the patch directory, extract name for directory name
	patch="$(basename "$pwd")"
fi


if [ $# -lt 1 -a -z "$patch" ]
then
	echo "Usage: $name <patch name> <files...>" > /dev/stderr
else
	if [ -z "$patch" ]
	then
		patch="$(basename "$1")"
		shift
	fi

	copied="f"

	while [ $# != 0 ]
	do
		if [ -f "$1" ]
		then
			file="$(realpath "$1")"
			dir="$(dirname "$(realpath "$1")")"

			echo "processing: $file"

			for d in "$root/$patch/a/src" "$root/$patch/b/src"
			do
				[ -d "$d$dir" ] || mkdir -p "$d$dir"
				if [ ! -e "$d$file" ]
				then
					cp "$1" "$d$file"
					echo "  $d$file: copied."
					copied="t"
				fi
			done

		else
			echo "  $1: file does not exist" > /dev/stderr
		fi

		shift
	done

	if [ "$copied" == f ]
	then
		cd "$root/$patch"
		diff -ur -N "a" "b" > ../$patch.patch
		echo "$patch.patch: patch file created"
	fi

fi
