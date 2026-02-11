
type=(
	"type"
	"role"
	"name"
	"class"
	"title"
	"xid"
	"state"
	"override_redirect"
)

command=(
	"xprop _NET_WM_WINDOW_TYPE | cut -d_ -f10"
	"xprop WM_WINDOW_ROLE | cut -d\\\" -f2"
	"xprop WM_CLASS | cut -d\\\" -f2"
	"xprop WM_CLASS | cut -d\\\" -f4"
	"xprop WM_NAME | cut -d\\\" -f2"
	"xwininfo | grep \"Window id:\" | cut -d ' ' -f4"
	"echo modal, sticky, maxvert, maxhorz, shaded, skiptaskbar, skippager, hidden, fullscreen, above, below, or demandsattention"
	"this is a special attribute and is used differently by different progs"
)

clear
while :
do
	echo
	i=0
	for criterion in "${type[@]}"
	do
		echo "$i) - check \"${type[$i]}\""
		i=$(expr $i + 1)
	done

	echo "q) - quit"
	echo
	echo -n "Which criterion do you want to get ? "
	read ans

	case "$ans" in
	q*)	exit 0;;
	Q*)	exit 0;;
	esac

	clear

	echo
	echo "Tool to read windows attributes for compiz selection."
	echo
	echo "REF: http://wiki.compiz.org/WindowMatching"
	echo

	if [ -z "$ans" -o "$ans" -lt 0 -o "$ans" -ge "${#type[@]}" ]
	then	
		echo
		echo "incorrect choice, try again."
	else
		echo
		echo "Click on the windows you require and then copy the following line to the compiz plugins criterion (Windows Rules or Place Windows)"
		echo
		val=$(eval ${command[$ans]})
#		echo "${type[$ans]}=$(echo ${command[$ans]})"
#		echo "${type[$ans]}=$(${command[$ans]})"
		echo "you can use: ${type[$ans]}=${val}"
		echo "or not equal: !${type[$ans]}=${val}"
		echo "or complex match: ${type[$ans]}=${val} & (!${type[$ans]}=${val} | ${type[$ans]}=${val})"
	fi
done
