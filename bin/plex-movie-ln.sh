#!/bin/bash

to="${@: -1}"

if [ $# -lt 2 ]
then
	echo "Usage: $(basename "$0") <files-or-dirs>... <to-dir>"
	exit 1
elif [ -e "$to" ] && [ ! -d "$to" ]
then
	echo "$to: exists and is not a directory, exiting"
	exit 1
fi

depth=""

msg()
{
	echo "$depth$*"
}

process_dir()
{
	local to="${@: -1}"
	local from

	to="${to%%/}"

	if [ ! -d "$to" ]
	then
		msg "$to: creating directory"
		mkdir "$to" || ( echo mkdir failed; exit 1)
	fi


	chown openflixr:openflixr "$to"

	while [ $# -ge 2 ]
	do
		from="${1%%/}"
		msg "copy from: $from"
		msg "copy to:   $to"

		if [ -d "$from" ]
		then
			msg "process directory: $from"
			depth="$depth  "
			process_dir "$from"/* "$to/$(basename "$from")"
			depth="${depth%%  }"
			msg "done process directory: $from"

		elif [ ! -e "$to/$(basename "$from")" ]
		then
			msg "ln \"$from\" \"$to\""
			ln "$from" "$to"
			chown openflixr:openflixr "$to/$(basename "$from")"
		fi
	

		shift
		echo
	done

}

process_dir "$@"

