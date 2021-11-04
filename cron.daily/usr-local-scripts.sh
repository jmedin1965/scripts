#!/bin/bash

# cron.dayly script to update local scripts

git_repo_local="/usr/local/scripts"

[ -d "${git_repo_local}/.git" ] || /usr/bin/git clone https://github.com/jmedin1965/scripts.git "$git_repo_local"
cd "${git_repo_local}"
/bin/sleep $(( $RANDOM % 120 + 1 ))
/usr/bin/git pull  > /dev/null

/bin/ln -fs /usr/local/scripts/profile.d/usr-local-scripts.sh /etc/profile.d/usr-local-scripts.sh
/bin/ln -fs /usr/local/scripts/cron.daily/usr-local-scripts.sh /etc/cron.daily/usr-local-scripts.sh

# do cleanup
unset git_repo_local

