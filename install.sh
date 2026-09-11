# Add /usr/local/scripts to path

export PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

install_sh_sourced="t" # used so we don't source this script twice

git_repo_local="/usr/local/scripts"
git_repo="https://jmedin1965@github.com/jmedin1965/scripts.git"
git_pushurl="git@github.com:jmedin1965/scripts.git"

server_config="$git_repo_local/server-config"

prog="$(basename "$0")"
prog_full="$(readlink -f "$0")"

info_indent="0"

main()
{
  # clone the repo if it does not exist, else git pull
  if [ -d "${git_repo_local}/.git" ]
  then
      cd "${git_repo_local}"
      R="`bash -c 'echo $RANDOM'`"
      if tty > /dev/null 2>&1
      then
          R="0"
          git pull
      else
          R="$(expr $R % 240)"
          info "sleeping for $R seconds"
          sleep "$R"
          git pull  > /dev/null 2>&1
      fi
  else
      git clone "$git_repo" "$git_repo_local"
      cd "$git_repo_local"
  fi
  git remote set-url --push origin "$git_pushurl"

  # add to path
  if [ -e "$git_repo_local/profile.d/usr-local-scripts.sh" ]
  then
      # usr-local-scripts.sh unsets git_repo_local, so we save it here
      t="$git_repo_local"
      . "$git_repo_local/profile.d/usr-local-scripts.sh"
      git_repo_local="$t"
  fi

  profile_d     "$git_repo_local/profile.d"
  cron_d        "$git_repo_local/cron.d"
  vimrc         "$git_repo_local/etc/vim/vimrc.local"
  logrotate_d   "$git_repo_local/logrotate.d"
  systemd       "$git_repo_local/systemd"
  sshd_config_d "$git_repo_local/sshd_config.d"

  # do platform specific stuff
  ID=""
  VERSION=""
  HOSTNAME="$(hostname -s)"
  HOSTDOMAIN="$(hostname -d)"
  [ -e /etc/os-release ] && . /etc/os-release
  [ -e /etc/version -a ! -d /etc/version ] && ID=`cat /etc/platform`
  [ -e /etc/version -a ! -d /etc/version ] && VERSION=`cat /etc/version`
  [ -e /etc/alpine-release ] && VERSION=`cat /etc/alpine-release`
  if [ -z "$ID" ]
  then
      ID="`uname -o`"
      VERSION="`echo $ID | sed "s,[^-]*-,,"`"
      VERSION_ID="$VERSION"
      ID="`echo $ID | sed "s,-.*,,"`"
  fi
  ID="`echo $ID | tr '[:upper:]' '[:lower:]'`"

  if /usr/bin/tty > /dev/null 2>&1
  then
      info
      info "ID=$ID"
      info "VERSION=$VERSION"
      info "VERSION_ID=$VERSION_ID"
      info "HOSTNAME=$HOSTNAME"
      info "HOSTDOMAIN=$HOSTDOMAIN"
      info
  fi

  info "do server scripts"
  which apt-get > /dev/null 2>&1 && do_scripts "$server_config/apt-get"
  [ -n "$ID" ] && do_scripts "$server_config/os/$ID"
  [ -n "$VERSION_ID" ] && do_scripts "$server_config/os/$ID$VERSION_ID"
  if [ -n "$HOSTNAME" ]
  then
    for d in "$server_config/hostname-like/"*
    do
      if [ -d "$d" ]
      then
        case "$HOSTNAME" in
          "$(basename "$d")"*)
            do_scripts "$d"
            ;;
        esac
      fi
    done
    do_scripts "$server_config/hostname/$HOSTNAME"
  fi

  # do cleanup
  unset git_repo git_repo_local prog R server_config
}

info()
{
  if [ $# == 0 ]
  then
    echo
  else
    echo "$(date +"%Y-%m-%d %H:%M:%S"): $@"
  fi
}

do_scripts()
{
  if [ -n "$1" ] && [ -d "$1" ]
  then
    info "  process $1"

    profile_d     "$1/profile.d"
    cron_d        "$1/cron.d"
    vimrc         "$1/etc/vim/vimrc.local"
    logrotate_d   "$1/logrotate.d"
    sshd_config_d "$1/sshd_config.d"

    if [ -x "$1/install.sh" ]
    then
      info "    running: install.sh"
      "$1/install.sh" "$@"
    fi

    # do this after install because some packages may be needed
    systemd     "$1/systemd"
  fi
}

# add to /etc/logrotate.d
logrotate_d()
{
  info "$1: check logrotate.d files"

  for f in "$1/"*
  do
      if [ -e "$f" ]
      then
        ln -fs "$f"  "/etc/logrotate.d"
        info "  update: $?: $f"
      fi
  done

  unset f
}


# add to /etc/profile.d
profile_d()
{
  info "$1: check profile.d files"

  for f in "$1/"*
  do
      if [ -e "$f" ]
      then
        ln -fs "$f"  "/etc/profile.d"
        info "  update: $?: $f"
      fi
  done

  unset f
}

# add to /etc/cron.d/
cron_d()
{
  info "$1: check cron.d files"

  cron_d=""
  [ -d "/etc/fcron.d" ] && cron_d="/etc/fcron.d"
  [ -d "/etc/cron.d" ]  && cron_d="/etc/cron.d"
  if [ -n "${cron_d}" ]
  then
      for f in "$1/"*
      do
          if [ -e "$f" ]
          then
            ln -fs "$f" "${cron_d}"
            info "  update: $?: $f"
          fi
      done
  fi

  unset cron_d f
}

systemd()
{
  info "$1: check systemd"

  if [ -e "$1" ]
  then
    for f in "$1/"*
    do
      if [ -e "$f" ]
      then
        info "  process: $f"
        ln -sf "$f" /etc/systemd/system && systemctl daemon-reload
        f="$(basename "$f")"
        case "$f" in
          *@.service)
            info "not enabling @.service template"
            ;;
          *)
            systemctl enable $f
            systemctl is-active $f || systemctl start $f
            ;;
        esac
      fi
    done
  fi

  info "  check systemd done"
  unset f
}

sshd_config_d()
{
  info "$1: check sshd_conf.d"

  if [ -d "$1" ]
  then
    for f in "$1/"*
    do
      if [ -e "$f" ]
      then
        f="$(readlink -f "$f")"
        destfile="/etc/ssh/sshd_config.d/$(basename "$f")"

        info "  check: $f"

        if [ ! -h "$destfile" ] || [ "$(readlink -f "$destfile")" != "$f" ]
        then
          ln -fs "$f" "$destfile"
          info "  $?: update link"
          service sshd restart
        else
          info "  existing file is ok"
        fi
      fi
    done
  fi

  info "  check sshd_conf.d done"
  unset vim_dir vimlocal
}

vimrc()
{
  info "$1: check virmc.local"

  if [ -e "$1" ]
  then
    # fix for pfsense
    vim_dir=""
    vimdest=""
    [ -d /usr/local/etc/vim ] && vim_dir="/usr/local/etc/vim"
    [ -d /etc/vim ]           && vim_dir="/etc/vim"
   
    if [ -n "$vim_dir" ]
    then
      info "  we have vimdir: $vim_dir"
      vimdest="${vim_dir}/vimrc.local"

    elif [ -e /etc/vimrc ] # Cigwin doesn't have a vim folder, or at least on mobaexterm
    then
      vimdest="/etc/vimrc.local"
    fi
    
    if [ -n "$vimdest" ]
    then
      info "  we have vimdest: $vimdest"

      # do vim fixes
      #
      # if file exists and is a real file or if it's a link and not pointing to the scripts version
      if [ -e "$vimdest" -a ! -h "$vimdest" ] || [ -h "$vimdest" -a "$(readlink -f "$vimdest")" != "$1" ]
      then
        info "  remove old vim file: $vimdest"
        rm -f "$vimdest"
      else
        info "  not removing old vimrc.local file"
      fi

      if [ ! -e "$vimdest" ]
      then
        ln -s "$1" "$vimdest"
        info "  $?: update link"
      else
        info "  existing vimrc.local file is ok"
      fi
    else
      info "  unable to determine location of vimrc.local file"
    fi
  else
    info "  no vimrc.local file"
  fi

  info "  check vimrc.local done"
  unset vim_dir vimlocal
}

if [ "$prog" == "install.sh" ]
then
  tty > /dev/null 2>&1 || exec > /dev/null
  main "$@"
fi

