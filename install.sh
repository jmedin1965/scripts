# Add /usr/local/scripts to path

git_repo_local="/usr/local/scripts"
git_repo="https://jmedin1965@github.com/jmedin1965/scripts.git"

# fix for ipfire
readlink="/bin/readlink"
[ -e /usr/bin/readlink ] && readlink="/usr/bin/readlink"

# clone the repo if it does not exist, else git pull
if [ -d "${git_repo_local}/.git" ]
then
    cd "${git_repo_local}"
    R="$RANDOM"
    /bin/tty -s && R="0"
    /usr/bin/tty --quiet || /bin/sleep $(( $R % 240 ))
    /usr/bin/git pull  > /dev/null
else
    /usr/bin/git clone "$git_repo" "$git_repo_local"
fi

# add to path
if [ -e "$git_repo_local/profile.d/usr-local-scripts.sh" ]
then
    # usr-local-scripts.sh unsets git_repo_local, so we save it here
    t="$git_repo_local"
    . "$git_repo_local/profile.d/usr-local-scripts.sh"
    git_repo_local="$t"
fi

# add to /etc/profile.d
for t in "$git_repo_local/profile.d/"*
do
    /bin/ln -fs "$t"  /etc/profile.d/$(/usr/bin/basename "$t")
done

# add to /etc/cron.d/
cron_d=""
[ -d "/etc/fcron.d" ] && cron_d="/etc/fcron.d"
[ -d "/etc/cron.d" ]  && cron_d="/etc/cron.d"
if [ -n "${cron_d}" ]
then
    # cleanup old 2024/02/02
    /bin/rm -f "/etc/fcron.daily/usr-local-scripts.sh"
    /bin/rm -f "/etc/cron.daily/usr-local-scripts.sh"

    for t in "$git_repo_local/cron.d/"*
    do
        [ -e "$t" ] && /bin/ln -fs "$t" "${cron_d}/$(/bin/basename "$t")"
    done
fi

vimlocal="/etc/vim/vimrc.local"
# fix for ipfire, needs further fixing
if [ -d /etc/vim ]
then
    # do vim fixes
    #
    # if file exists and is a real file or if it's a link and not pointing to the scripts version
    if [ -e "$vimlocal" -a ! -h "$vimlocal" ] || [ -h "$vimlocal" -a "$($readlink -f "$vimlocal")" != "$git_repo_local$vimlocal" ]
    then
        /bin/rm -f "$vimlocal"
    fi
    if [ ! -e "$vimlocal" ]
    then
        /bin/ln -s "$git_repo_local$vimlocal" "$vimlocal"
    fi
fi

# do cleanup
unset git_repo git_repo_local cron_d t

