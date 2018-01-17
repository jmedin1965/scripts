#!/bin/bash

if [ -e /opt/git-repo/local/sbin/local-functions ]
then
	. /opt/git-repo/local/sbin/local-functions
elif [ -e /usr/local/sbin/local-functions ]
then
	. /usr/local/sbin/local-functions
elif [ -e /mnt/autofs/nfs/git-repo/local/sbin/local-functions ]
then
	. /mnt/autofs/nfs/git-repo/local/sbin/local-functions
fi

prog="/usr/bin/git pull"
mailSubject="${prog##*/} for /opt-git-repo from $hostname"
mailTo="jmedin@joy.com"
doMail="false"
readlink="/usr/bin/readlink" && [ -x "/bin/readlink" ] && readlink="/bin/readlink"
stableBranchPattern='*stable*'
stableBranchPattern='*'


do_prog()
{
	local prog="$1"
	local EV

	$prog 2>&1
	EV="$?"
	echo "exited with value $EV"

	return $EV
}

check_results()
{
	[ $# != 2 ] && return
	
	local result="$1"
	local sucessMsg="$2"

	if [ "$(/bin/fgrep -c "$sucessMsg" <<< "$result")" -eq 0 ]
	then
		doMail="true"
		log "check_results did not find \"$sucessMsg\" in;"
		log "-----"
		log <<< "$result"
		log "-----"
		log "doMail=true"
	else
		log "doMail=false"
	fi
}

process_start()
{

		log "================================================"
		log "start processing $1"
}

log_init

#
# check location of /usr/bin/local
#
if [ -d "/usr/bin/local/.git" -a "$($readlink "/usr/bin/local/.git")" != "/opt/git-repo/local/.git" ]
then
	log "error: $hostname: still has .git on /usr/local/.git"
	doMail="true"
fi

pwd="$(pwd)"

#
# Process /opt/git-repo
#
count=0
for repo in /opt/git-repo/*/.git
do
	count=$((count + 1))

	if [ -d "$repo" ]
	then
		repo="$(/usr/bin/dirname "$repo")"
		process_start "repo $count - $repo"
		cd "$repo"

		branch="$(/usr/bin/git rev-parse --abbrev-ref HEAD)"
		branchList="$(/usr/bin/git branch -a)"
		
		log "--"
		log "current branch: $branch"
		log "branch list:"
		log <<< "$branchList"
		log "--"
		
		results="$(do_prog "/usr/bin/git pull")"
		echo "$results" | log
		check_results "$results" "Already up-to-date."
	fi

	#[ "$count" -ge 8 ] && exit 0
done

#
# Process gitlab
#
process_start "gitlab-ce"
if [ -f /opt/gitlab/version-manifest.txt ]
then
	results="$(do_prog "/usr/bin/apt-get install --dry-run gitlab-ce")"
	echo "$results" | log
	check_results "$results" "is already the newest version"
else
	log "gitlab-ce: not installed on this system"
fi

cd "$pwd"

log "================================================"
log "check if we need to mail: doMail=$doMail"
if [ "$doMail" == true ]
then
	mail -s "$mailSubject" $mailTo <<< "$msg"
fi

