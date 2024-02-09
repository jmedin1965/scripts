#!/bin/bash

ask()
{
	local ret="1"

	echo
	echo -n "$1 [y/n] ? "
	read ans
	case "$ans" in
		y*) ret=0;;
	esac

	return $ret
}

get_ans()
{
	local ans="$2"

	echo -n "
$1=$2
? " > /dev/stderr

	read ans
	[ -z "$ans" ] && ans="$2"
	echo "$ans"
}

check()
{
	if [ -z "$TMUX" ]
	then
		ask "not running in tmux session, continue" || return 1
	fi
	return 0
}

batch_run_list()
{
	local i=0 n idx last

	[ -e "${0}.last" ] && last=$(< "${0}.last")

	echo
	for n in "${namel[@]}"
	do
		if [ "$n" == "$last" ]
		then
			echo "* $i)	$n"
		else
			echo "  $i)	$n"
		fi

		((i++))
	done

	echo
	echo "or just enter a name"
	echo
	echo -n "which ? "
	read idx

	if [ -z "$idx" ]
	then
		# do nothing
		name="$name"

	elif [ "$idx" -eq "$idx" ] 2>/dev/null && [ -n "${namel[$idx]}" ]
	then
		name="${namel[$idx]}"
	else
		name="$idx"
	fi

	echo "$name" > "${0}.last"
}

ans=""
TEST="pts/disk"
name="disk-lvm-1tsata"
[ -e "${0}.last" ] && name=$(< "${0}.last")
namel=(
	"disk-lvm-1t-sas"
	"disk-lvm-1tsata"
	"disk-lvm-800g-sas"
	"disk-lvm-ext02"
	"disk-zfs-1t-sas"
	"disk-zfs-1t-sata"
	"disk-zfs-800g-sas"
	"disk-zfs-ext02"
)

while [ "$ans" != q ]
do
	clear
	echo "
TEST = $TEST
TMUX = $TMUX
name = $name

b)	run batch-setup
d)	delete old test = $TEST
f)	finish incomplete test run = $name
i)      get test info
n)	change name
t)	change test
r)	batch-run $TEST \> $name
u) 	upload test results

q)	quit

"
	export TEST_RESULTS_NAME="$name"
	export TEST_RESULTS_IDENTIFIER="$name"
	export TEST_RESULTS_DESCRIPTION="$name"

	echo -n "which ? "
	read ans

	case "$ans" in
	b)	phoronix-test-suite batch-setup;;
	d)	ask "delete old test - $name" && phoronix-test-suite remove-installed-test "$name";;
	f)	phoronix-test-suite finish-run "$name";;
	i)	phoronix-test-suite info "$TEST"; echo -n "Press ENTER to continue"; read ans;;
	n)	batch_run_list;;
	r)	check && phoronix-test-suite batch-run $TEST;;
	t)	TEST="$(get_ans TEST $TEST)";;
	u)	phoronix-test-suite upload-result $TEST;;
	esac
done

echo exit

