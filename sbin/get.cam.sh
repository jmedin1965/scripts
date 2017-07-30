#!/bin/bash

process_page()
{
	while read arg1 arg2 arg3 arg4
	do
		case "$arg1" in
		"rec_files["*)
			echo $arg1$arg2
			;;
		"rec_files_size["*)
			echo $arg1$arg2
			;;
		"var")
			case "$arg2" in
			rec_files_cnt|rec_files_total|page_maxitem|page_curr)
				echo $arg2$arg3$arg4
				;;
			esac
			;;
		esac
	done
}


get_file()
{
	file="$1"
	url="$2"
	sd_size="$3"

	size="0"
	if [ -f "$file" ]
	then
		size=$(/usr/bin/stat --printf=%s "$file")
		size=$(/usr/bin/expr $size / 1024 )
	fi

	action="skip"

	while :
	do

		echo -n "$file, size on sd: $sd_size kb, size: $size kb - "  >> $cam.log 

		if [ "$size" == "$sd_size" ]
		then
			echo "$action ${size} kb"  >> $cam.log 
			return
		else
			[ "$action" == got ] && action="retry"
			[ "$action" == skip ] && action="got"

			/usr/bin/wget --timeout=30 -O "$file" --user admin --password juan2three $url 2>/dev/null 

			size="0"
			if [ -f "$file" ]
			then
				size=$(/usr/bin/stat --printf=%s "$file")
				size=$(/usr/bin/expr $size / 1024 )
			fi
			echo "$action ${size} kb"  >> $cam.log 
		fi

		sleep 5
	done
}


clean_old_files()
{
	dir="$1"
	tzise="0"
	count="0"
	del="0"

	if [ -d "$dir" ]
	then
		ls -t $dir | while read file
		do
			file="$dir/$file"
			if [ -f "$file" ]
			then
				size=$(/usr/bin/stat --printf=%s "$file")
				tsize=$(/usr/bin/expr $tsize + $size)
				count=$(/usr/bin/expr $count + 1)
				if [ $tsize -gt 32768000000 ]
				then
					del="1"
					/bin/rm -f "$file" 

					echo clean: $file $size $tsize $count
				fi
			fi
		done
	fi
}

cd /home/mythtv/cams

(
	echo
	echo "download stating on $(/bin/date)" 
) >> $cam.log


for cam in 192.168.0.162
do
	clean_old_files "$cam/crud" >> $cam.log

	page_maxitem=1
	page_max=1
	if [ "$1" == "" ]
	then
		page_start="1"
		page_max="1"
	else
		page_start="$1"
		page_max="$1"
	fi


	for d in "$cam" "$cam/keep" "$cam/crud"
	do
		if [ ! -d "$d" ]
		then
			/bin/mkdir "$d"
		fi	
	done	

	for(( i=$page_start; i <= $page_max; i++ ))
	do
		rec_files_cnt=""
		eval $(/usr/bin/wget --timeout=30 -O - --user admin --password juan2three http://$cam/rec/rec_file.asp\?page=$i 2>/dev/null | process_page)

		while [ "$rec_files_cnt"  == "" ]
		do 
			sleep 2
			eval $(/usr/bin/wget --timeout=30 -O - --user admin --password juan2three http://$cam/rec/rec_file.asp\?page=$i 2>/dev/null | process_page)
		done

		page_max=$(/usr/bin/expr 1 + $rec_files_total / $page_maxitem)
		(
			echo
			echo date $(/bin/date)
			echo page $i
			echo
			echo rec_files_cnt=$rec_files_cnt
			echo rec_files_total=$rec_files_total
			echo page_maxitem=$page_maxitem
			echo page_curr=$page_curr
			echo page_max=$page_max
			echo page_start=$page_start
			echo
		) >> $cam.log

		for (( j=0; j < $rec_files_cnt; j++ ))
		do
			f="."
#			[ -f "$cam/crud/${rec_files[$j]}" ] && f="crud"
#			[ -f "$cam/keep/${rec_files[$j]}" ] && f="keep"

			f=$(/usr/bin/find $cam -name "${rec_files[$j]}" | /usr/bin/tail -1)
			[ -f "$f" ] || f="$cam/${rec_files[$j]}"

			get_file "$f" http://$cam/sd/${rec_files[$j]} ${rec_files_size[$j]}
		done
	done 
done

(
	echo "download finished on $(/bin/date)" 
	echo
) >> $cam.log

