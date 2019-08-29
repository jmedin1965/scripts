#!/bin/bash

# cron.dayly script to update local scripts

git_repo_local="/usr/local/scripts"

cd ${git_repo_local}
/bin/sleep $(( $RANDOM % 120 + 1 ))
/usr/bin/git pull  > /dev/null

# do cleanup
unset git_repo_local

