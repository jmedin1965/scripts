# Add /usr/local/scripts to path

# make sure  /usr/local/{bin,sbin} is there too
#if ! echo $PATH | /bin/grep -q /usr/local/bin ; then
#  export PATH=/usr/local/sbin:/usr/local/bin:$PATH
#fi

# clone the repo
git_repo_local="/usr/local/scripts"
if [ ! -d "${git_repo_local}/.git" ]; then
	cd /usr/local
	/usr/bin/git clone https://jmedin1965@github.com/jmedin1965/scripts.git
fi

# add to path
if [ -n "$git_repo_local" ] && ! echo "$PATH" | /bin/grep -q "$git_repo_local" ; then
  export PATH="${git_repo_local}/sbin:${git_repo_local}/bin:$PATH"
fi

# add to /etc/profile.d
[ -f /etc/profile.d/usr-local-scripts.sh ] || /bin/ln -s "${git_repo_local}/sbin/usr-local-scripts.sh" /etc/profile.d/usr-local-scripts.sh

# add to /etc/cron.daily/
[ -d "/etc/fcron.daily" ] && cron_d="/etc/fcron.daily"
[ -d "/etc/cron.daily" ]  && cron_d="/etc/cron.daily"
if [ -n "${cron_d}" -a ! -f "${cron_d}/usr-local-scripts.sh" ]; then
	echo "#!/bin/bash
cd ${git_repo_local}
/bin/sleep \$[ ( \$RANDOM % 120 )  + 1 ]s
/usr/bin/git pull  > /dev/null
" 	> "${cron_d}/usr-local-scripts.sh"
	/bin/chmod 755 "${cron_d}/usr-local-scripts.sh"
fi

# do cleanup
unset git_repo_local

