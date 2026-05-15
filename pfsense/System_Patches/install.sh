#!/usr/bin/env bash

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

root="$(dirname "$(realpath "$0")")"
name="$(basename "$0")"
pwd="$(pwd)"
pkg=""

# check if we are already in the patch directory
if [ "$(basename "$(dirname "$pwd")")" == System_Patches ]
then
	echo "we are in the patch directory, extract name for directory name"
	if [ $# == 0 ]
	then
		pkg="$(basename "$pwd")"
		set -- "$pkg"
		cd ..
	else
		echo "can't specifi a patch to install if you are in the patch dir" > /dev/stderr
		echo "Usage: $name" > /dev/stderr
		exit 1
	fi
elif [ "$(basename "$pwd")" != System_Patches ]
then
	echo "need to be in the System_Patches dir, or in the package dir." > /dev/stderr
	echo "Usage: $name package..." > /dev/stderr
	exit 1
elif [ $# == 0 ]
then
	echo "Usage: $name package..." > /dev/stderr
	exit 1
fi

while [ $# != 0 ]
do
	pkg="$1"
	shift
	if ! cd "$pkg/b/src"
	then
		unable to cd to install files on $pkg/b/src, skipping
		continue
	fi
	echo
	echo "root  = $root"
	echo "name  = $name"
	echo "pkg   = $pkg"

	while read file
	do
		if [ -d "$file" ]
		then
			echo "   dir: $file"
		else
			if [ "$file" -ef "/$file" ]
			then
				echo "ok  file: $file"
			else
				echo "fix  file: $file"
				rm -f "/$file"
				ln "$file" "/$file"
			fi
		fi
	done <<< "$(find .)"
done

exit 0

if [ $# -lt 1 -a -z "$pkg" ]
then
	echo "Usage: $name <patch name> <files...>" > /dev/stderr
else
	if [ -z "$pkg" ]
	then
		pkg="$(basename "$1")"
		shift
	fi

echo "pkg   = $pkg"

	copied="f"

	while [ $# != 0 ]
	do
		if [ -f "$1" ]
		then
			file="$(realpath "$1")"
			dir="$(dirname "$(realpath "$1")")"

			echo "processing: $file"

#			for d in "$root/$patch/a/src" "$root/$patch/b/src"
#			do
#				[ -d "$d$dir" ] || mkdir -p "$d$dir"
#				if [ ! -e "$d$file" ]
#				then
#					cp "$1" "$d$file"
#					echo "  $d$file: copied."
#					copied="t"
#				fi
#			done

		else
			echo "  $1: file does not exist" > /dev/stderr
		fi

		shift
	done

	if [ "$copied" == f ]
	then
		cd "$root/$patch"
#		diff -ur -N "a" "b" > ../$patch.patch
		echo "$patch.patch: patch file created"
	fi

fi
