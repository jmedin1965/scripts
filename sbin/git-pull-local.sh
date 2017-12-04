#!/bin/bash

. /usr/local/sbin/local-functions

prog="/usr/bin/git pull"
mailSubject="${prog##*/} for /opt-git-repo from $hostname"
mailTo="jmedin@joy.com"
doMail="false"
readlink="/usr/bin/readlink" && [ -x "/bin/readlink" ] && readlink="/bin/readlink"


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
for repo in /opt/git-repo/*/.git
do
	if [ -d "$repo" ]
	then
		repo="$(/usr/bin/dirname "$repo")"
		process_start "repo $repo"
		cd "$repo"
		results="$(do_prog "/usr/bin/git pull")"
		echo "$results" | log
		check_results "$results" "Already up-to-date."
	fi
done

#
# Process gitlab
#
process_start "gitlab-ce"
if [ -f /opt/gitlab/version-manifest.txt ]
then
	results="$(do_prog "/usr/bin/apt-get install --dry-run gitlab-ce")"
	echo "$results" | log
	check_results "$results" "is already the newest version."
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

