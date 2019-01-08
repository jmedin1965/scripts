# Add /opt/puppetlabs/bin to the path for sh compatible users

if ! echo $PATH | grep -q /usr/local/bin ; then
  export PATH=/usr/local/sbin:/usr/local/bin:$PATH
fi

git_repo_local=""
[ -d /opt/git-repo/local/bin ] && git_repo_local="/opt/git-repo/local"
[ -d /mnt/autofs/nfs/git-repo/local/bin ] && git_repo_local="/mnt/autofs/nfs/git-repo/local"
[ -d /usr/local/scripts/bin ] && git_repo_local="/usr/local/scripts"
if [ -n "$git_repo_local" ] && ! echo $PATH | grep -q "$git_repo_local" ; then
  export PATH="$git_repo_local/sbin:$git_repo_local/bin:$PATH"
fi
unset git_repo_local
