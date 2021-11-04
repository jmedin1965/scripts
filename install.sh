# Add /usr/local/scripts to path

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
/bin/ln -fs /usr/local/scripts/profile.d/usr-local-scripts.sh /etc/profile.d/usr-local-scripts.sh

# add to /etc/cron.daily/
cron_d=""
[ -d "/etc/fcron.daily" ] && cron_d="/etc/fcron.daily"
[ -d "/etc/cron.daily" ]  && cron_d="/etc/cron.daily"

[ -n "${cron_d}" ] && /bin/ln -fs /usr/local/scripts/cron.daily/usr-local-scripts.sh "${cron_d}/usr-local-scripts.sh"

# do cleanup
unset git_repo_local cron_d

