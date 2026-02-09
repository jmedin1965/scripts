#!/bin/sh

git_repo_local="/usr/local/scripts"

# Add /usr/local /usr/local/scripts to path
for p in /usr/local $git_repo_local
do
	if ! echo $PATH | grep -q $p/bin ; then
	  export PATH=$p/sbin:$p/bin:$PATH
	fi
done

# add to path
if [ -n "$git_repo_local" ] && ! echo "$PATH" | grep -q "$git_repo_local" ; then
  export PATH="${git_repo_local}/sbin:${git_repo_local}/bin:$PATH"
fi

# set vim as default editor if it exists
[ -x /usr/local/bin/vim ] && export EDITOR="/usr/local/bin/vim"
[ -x /usr/bin/vim ]       && export EDITOR="/usr/bin/vim"

# set nodesj to user local ca certificate store
export NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt

# do cleanup
unset git_repo_local

