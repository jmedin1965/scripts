# Add /usr/local/scripts to path

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

git_repo_local="/usr/local/scripts"
git_repo="https://jmedin1965@github.com/jmedin1965/scripts.git"

# clone the repo if it does not exist, else git pull
if [ -d "${git_repo_local}/.git" ]
then
    cd "${git_repo_local}"
    R="`bash -c 'echo $RANDOM'`"
    tty -s && R="0"
    tty -s || sleep `expr $R % 240`
    git pull  > /dev/null
else
    git clone "$git_repo" "$git_repo_local"
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
    ln -fs "$t"  "/etc/profile.d/`basename "$t"`"
done

# add to /etc/cron.d/
cron_d=""
[ -d "/etc/fcron.d" ] && cron_d="/etc/fcron.d"
[ -d "/etc/cron.d" ]  && cron_d="/etc/cron.d"
if [ -n "${cron_d}" ]
then
    # cleanup old 2024/02/02
    rm -f "/etc/fcron.daily/usr-local-scripts.sh"
    rm -f "/etc/cron.daily/usr-local-scripts.sh"

    for t in "$git_repo_local/cron.d/"*
    do
        [ -e "$t" ] && ln -fs "$t" "${cron_d}/`basename "$t"`"
    done
fi

# fix for pfsense
vim_dir=""
[ -d /usr/local/etc/vim ] && vim_dir="/usr/local/etc/vim"
[ -d /etc/vim ]           && vim_dir="/etc/vim"

# fix for ipfire, needs further fixing
if [ -n "$vim_dir" ]
then
    vimlocal="${vim_dir}/vimrc.local"
    # do vim fixes
    #
    # if file exists and is a real file or if it's a link and not pointing to the scripts version
    if [ -e "$vimlocal" -a ! -h "$vimlocal" ] || [ -h "$vimlocal" -a "`readlink -f "$vimlocal"`" != "$git_repo_local$vimlocal" ]
    then
        rm -f "$vimlocal"
    fi
    if [ ! -e "$vimlocal" ]
    then
        ln -s "$git_repo_local$vimlocal" "$vimlocal"
    fi
fi

# do platform specific stuff
ID=""
VERSION=""
[ -e /etc/os-release ] && source /etc/os-release
[ -e /etc/version ] && ID=`cat /etc/platform`
[ -e /etc/version ] && VERSION=`cat /etc/version`

if /usr/bin/tty -s
then
    echo
    echo "ID=$ID"
    echo "VERSION=$VERSION"
fi

# do cleanup
unset git_repo git_repo_local cron_d t vim_dir vimlocal

