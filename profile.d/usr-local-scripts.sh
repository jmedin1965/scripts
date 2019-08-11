#!/bin/bash

# Add /usr/local/scripts to path

git_repo_local="/usr/local/scripts"

# make sure  /usr/local/{bin,sbin} is there too
#if ! echo $PATH | /bin/grep -q /usr/local/bin ; then
#  export PATH=/usr/local/sbin:/usr/local/bin:$PATH
#fi

# add to path
if [ -n "$git_repo_local" ] && ! echo "$PATH" | /bin/grep -q "$git_repo_local" ; then
  export PATH="${git_repo_local}/sbin:${git_repo_local}/bin:$PATH"
fi

# do cleanup
unset git_repo_local

