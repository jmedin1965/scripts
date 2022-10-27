# Add /usr/local/scripts to path

git_repo_local="/usr/local/scripts"
git_repo="https://jmedin1965@github.com/jmedin1965/scripts.git"

# clone the repo if it does not exest, else git pull
if [ -d "${git_repo_local}/.git" ]
then
    cd "${git_repo_local}"
    /usr/bin/tty --quiet || /bin/sleep $(( $RANDOM % 120 + 1 ))
    /usr/bin/git pull  > /dev/null
else
    /usr/bin/git clone "$git_repo" "$git_repo_local"
fi

# add to path
if [ -n "$git_repo_local" ] && ! echo "$PATH" | /bin/grep -q "$git_repo_local" ; then
  export PATH="${git_repo_local}/sbin:${git_repo_local}/bin:$PATH"
fi

# add to /etc/profile.d
/bin/ln -fs "$git_repo_local/profile.d/usr-local-scripts.sh"  /etc/profile.d/usr-local-scripts.sh

# add to /etc/cron.daily/
cron_d=""
[ -d "/etc/fcron.daily" ] && cron_d="/etc/fcron.daily"
[ -d "/etc/cron.daily" ]  && cron_d="/etc/cron.daily"
[ -n "${cron_d}" ] && /bin/ln -fs "$git_repo_local/install.sh" "${cron_d}/usr-local-scripts.sh"

vimlocal="/etc/vim/vimrc.local"
# do vim fixes
#
# if file exists and is a real file or if it's a link and not pointing to the scripts version
if [ -e "$vimlocal" -a ! -h "$vimlocal" ] || [ -h "$vimlocal" -a "$(/bin/readlink -f "$vimlocal")" != "$git_repo_local$vimlocal" ]
then
    /bin/rm -f "$vimlocal"
fi
if [ ! -e "$vimlocal" ]
then
    /bin/ln -s "$git_repo_local$vimlocal" "$vimlocal"
fi

# do cleanup
unset git_repo git_repo_local cron_d

