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

	attempt="1"
	while :
	do

		log "attempt=$attempt$file, size on sd: $sd_size kb, size: $size kb - "

		if [ "$size" == "$sd_size" ] || [ "$action" == failed ]
		then
			log "attempt=$attempt: $file, $action ${size} kb" 
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

			log "$action ${size} kb"
		fi

		attempt=$((attempt + 1))
		[ "$attempt" == 30 ] && action="failed"

		sleep 5
	done
}


clean_old_files()
{
	dir="$1"
	tzise="0"
	count="0"
	del="0"

	log "clean_old_log_files starting in: $dir"

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

					log clean: $file $size $tsize $count
				fi
			fi
		done
	fi
}

log()
{
	echo "$(/bin/date "+%Y-%m-%d %R:%S"): $@" >> "$log"
}

datadir="/home/mythtv/cams"
logd="$datadir/log"
log="$logd/$(/usr/bin/basename "$0").log"

cd "$datadir"
log "download stating." 

for cam in 10.11.1.30 10.11.1.31
do
	log="$datadir/log/$cam.log"

	clean_old_files "$cam/crud"

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

	if /bin/ping -q -c 1 -w 2 $cam > /dev/null 2>&2
	then
		log "cam is reachable, so processing"

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
			log
			log date $(/bin/date)
			log page $i
			log
			log rec_files_cnt=$rec_files_cnt
			log rec_files_total=$rec_files_total
			log page_maxitem=$page_maxitem
			log page_curr=$page_curr
			log page_max=$page_max
			log page_start=$page_start
			log

			for (( j=0; j < $rec_files_cnt; j++ ))
			do
				f="."
#				[ -f "$cam/crud/${rec_files[$j]}" ] && f="crud"
#				[ -f "$cam/keep/${rec_files[$j]}" ] && f="keep"

				f=$(/usr/bin/find $cam -name "${rec_files[$j]}" | /usr/bin/tail -1)
				[ -f "$f" ] || f="$cam/${rec_files[$j]}"

				get_file "$f" http://$cam/sd/${rec_files[$j]} ${rec_files_size[$j]}
			done
		done 
	else
		log "cam is not reachable, skipping"
	fi

	log "download finished"
done

