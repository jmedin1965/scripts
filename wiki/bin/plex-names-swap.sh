#!/bin/bash

if [ $# -lt 2 ]
then
	echo "Usage: $(basename "$0") <pattern1> <pattern2>"
	exit 1
fi

yesno()
{
	echo -n "$1 y/n [n]: "
	read ans
	case "$ans" in
		[yY])	return 0;;
		[nN])	return 1;;
	esac
	return 1
}

swap()
{
	local dryrun="f"
	[ "$1" == "-n" ] || [ "$1" == "--dry-run" ] && dryrun="t" && shift

	[ $# == 2 ] || return 1

	local p="StmpEtmp"

	swapped=()
	local i="0"
	echo "pattern 1 to tmp"
	for f in "$1"*
	do
		echo "  $f"
		echo "    to $p${f#$1}"
		[ "$dryrun" == "f" ] && mv "$f" "$p${f#$1}"
		swapped[$i]="$p${f#$1}"
		((i++))
	done

	echo "pattern 2 to pattern 1"
	for f in "$2"*
	do
		echo "  $f"
		echo "    to $1${f#$2}"
		[ "$dryrun" == "f" ] && mv "$f" "$1${f#$2}"
	done

	echo "tmp pattern 2"
	for f in "${swapped[@]}"
	do
		echo "  $f"
		echo "    to $2${f#$1}"
		[ "$dryrun" == "f" ] && mv "$f" "$2${f#$1}"
	done
}

swap --dry-run "$1" "$2"
yesno "go ahead and rename" && swap "$1" "$2"

