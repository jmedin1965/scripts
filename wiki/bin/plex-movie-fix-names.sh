#!/bin/bash

case "$(basename "$0")" in
	*-movie-*)
		movies_dir="/mnt/movies"
		;;
	*-series-*)
		movies_dir="/mnt/series"
		;;
	*)
		echo "don't know where to copy to"
		exit 1
		;;
esac

rename()
{
	local to="$(echo "$1" | tr -dc '[:print:]')"

	to="${to// /.}"
	to="${to// /}"
	to="${to//\(/}"
	to="${to//\)/}"
	to="${to//\]/}"
	to="${to//\[/}"
	to="$(echo "$to" | sed 's/\.-//g')"
	to="$(echo "$to" | sed 's/\.-//g')"
	to="$(echo "$to" | sed 's/\.\.*/\./g')"
	echo "$to"
}

rename_type()
{
	local ext="${1##*.}"
	local file="${1%.*}"
	local dir="$(dirname "$1")"
	local name="$(basename "$dir")"

	ext="${ext,,}"

	case "$ext" in
		"avi")
			;;
		"mkv")
			;;
		"srt")
			;;
		"sfv")
			;;
		"m4v")
			;;
		*)
			echo "$1"
			return 0
			;;
	esac
	echo "$dir/$name.$ext"
	return 0
}

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


for f in "$@"
do
	f="${f%/}"
	folder_from="$f"
	folder_to="$movies_dir/$(basename "$(rename "$f")" )"


	for file in "$f"*
	do

		if [ -d "$file" ] && [ "$(readlink -f "$file")" = "$(readlink -f  "$folder_to")" ]
		then
			echo "processing rename files in: $file"
			files="$file/"
			folder_to=""
			break
		elif [ -d "$file" ]
		then
			echo "processing folder: $file"
			folder_from="$file"
			files="$file/"
			folder_to="${folder_to%/}"
			folder_to="${folder_to%.}"

			echo "  folder_from = $folder_from"

			break
		elif [ -e "$file" ]
		then
			echo "processing files: $f"
			files="$f"

			echo "  files_from  = ${folder_from}*"

			break
		else
			echo "$file: does not exist"
			exit 1
		fi
	done

	echo "  folder_to   = $folder_to"

	for file in "$files"*
	do
		subdir=""
		[ -d "$file" ] && subdir="$(basename "$file")"
		echo "    process: $file"
		if [ -z "$folder_to" ]
		then
			echo "      rename to: $(rename_type "$file")"
		else
			echo "      rename to: $folder_to/$subdir"
		fi
	done

	if yesno "process these files"
	then
		[ -d "$folder_to" ] || [ -z "$folder_to" ] || mkdir "$folder_to"
		for file in "$files"*
		do
			subdir=""
			[ -d "$file" ] && subdir="$(basename "$file")"
			if [ -z "$folder_to" ]
			then
				[ "$file" == "$(rename_type "$file")" ] || mv "$file" "$(rename_type "$file")"
			else
				mv "$file" "$folder_to/$subdir"
			fi
		done
		[ -d "$files" ] && [ -n "$folder_to" ] && rmdir "$files"
	else
		echo "    Skipping"
	fi
done

