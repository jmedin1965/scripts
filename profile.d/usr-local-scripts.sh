#!/bin/sh

# Add /usr/local/scripts to path

git_repo_local="/usr/local/scripts"

# make sure  /usr/local/{bin,sbin} is there too
#if ! echo $PATH | /bin/grep -q /usr/local/bin ; then
#  export PATH=/usr/local/sbin:/usr/local/bin:$PATH
#fi

# add to path
if [ -n "$git_repo_local" ] && ! echo "$PATH" | grep -q "$git_repo_local" ; then
  export PATH="${git_repo_local}/sbin:${git_repo_local}/bin:$PATH"
fi

# set vim as default editor it it exists
[ -x /usr/local/bin/vim ] && export EDITOR="/usr/local/bin/vim"
[ -x /usr/bin/vim ]       && export EDITOR="/usr/bin/vim"

# set nodesj to user local ca certificate store
export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt

# do cleanup
unset git_repo_local

