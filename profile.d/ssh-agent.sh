
path="$PATH"
PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

DEBUG="1"
msg()
{
    if [ "$DEBUG" -gt 0 ]
    then
        echo "msg:" "$@"
    fi
}


# a function to trap CTRL_C since ssh-add times out or waits forever
ctrl_c() {
    echo "** Trapped CTRL-C"
    echo "msg: trap done"
}
# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

export AUTH_SOCK=~/.ssh/ssh-agent.sock                  # the local ssh agent socket
export AUTH_SOCK_LINK=~/.ssh/ssh-agent-link.sock        # a link we use to point to a valid auth sock in the AUTH_SOCK_D
export AUTH_SOCK_D=~/.ssh/ssh-agent.sock.d              # a directory containing links to auth sockets
export SSH_AGENT="ssh-agent"                            # the linux ssh-agent

# WSL2 and bitwarden-agent
WSL2="false"
if [ "`uname -r | tail -c 5`" == WSL2 ]
then
	WSL2="true"
	export BW_SSH_AUTH_SOCK=~/.ssh/bitwarden-ssh-agent.sock
	export BW_SSH_AUTH_SOCK=~/.var/app/com.bitwarden.desktop/data/.bitwarden-ssh-agent.sock
fi


if [ "$1" == logout ]
then
	msg " Loggout: SSH_AUTH_SOCK_ORIG=$SSH_AUTH_SOCK_ORIG"
	if [ -n "$BW_SSH_AUTH_SOCK" ]
    then
		msg "  we are using bitwarder-agent socket, do not remove"

	elif [ -n "$SSH_AUTH_SOCK_ORIG" ]
	then
		msg "  remove SSH_AUTH_SOCK that this session was using $SSH_AUTH_SOCK_ORIG"
		msg "  /bin/rm -f $SSH_AUTH_SOCK_ORIG"
        export SSH_AUTH_SOCK=""
        for SSH_AUTH_SOCK_ORIG in `/bin/ls -c -r "$AUTH_SOCK_D"/*`
		do
			if [ -S "$SSH_AUTH_SOCK_ORIG" ]
			then
                msg
                if [ -z "$SSH_AUTH_SOCK" ]
                then
                    export SSH_AUTH_SOCK="$SSH_AUTH_SOCK_ORIG"
                    msg "   testing: $SSH_AUTH_SOCK"
                    ssh-add -l 2>/dev/null >/dev/null   # test if local socket is active
                    if [ $? -ge 2 ] # if not active
                    then
                        msg "     loop: /bin/rm -f \"$SSH_AUTH_SOCK_ORIG\""
                        /bin/rm -f "$SSH_AUTH_SOCK_ORIG"
                    else
                        msg "     loop: ln -sf \"$SSH_AUTH_SOCK_ORIG\" \"$AUTH_SOCK_LINK\""
                        [ -e "$AUTH_SOCK_LINK" ] && /bin/rm -f "$AUTH_SOCK_LINK"
                        /bin/ln -sf "$SSH_AUTH_SOCK_ORIG" "$AUTH_SOCK_LINK"
                    fi
                fi
			else
				msg "   loop: /bin/rm -f \"$SSH_AUTH_SOCK_ORIG\""
				/bin/rm -f "$SSH_AUTH_SOCK_ORIG"
			fi
		done
	fi
    msg " done $?"
    sleep 1
	exit 0
fi

export SSH_AUTH_SOCK_ORIG=""

# Cygwin ssh-agent socket
if [ "`uname -o`" == "Cygwin" ]
then
    msg
    msg " we are using Cygwin."
    AUTH_SOCK=~/.ssh/ssh-agent-pageant.sock
    SSH_AGENT="/usr/bin/ssh-pageant"
fi

msg
msg "SUDO_USER=$SUDO_USER"
msg "USER=$USER"
msg "SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
# WSL2, much easier now with bitwarder ssh-agent
if [ "$WSL2" == true ]
then
    msg
    msg " we are using WSL2"
    export SSH_AUTH_SOCK="$BW_SSH_AUTH_SOCK"
    msg " BW_SSH_AUTH_SOCK=$BW_SSH_AUTH_SOCK"
    msg " SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
    #/usr/local/sbin/ssh-agent-pipe-from-windows.sh
    #if [ -z "$SUDO_USER" ]
    #then
    #    if [ "$(flatpak ps | fgrep com.bitwarden.desktop -c)" == 0 ]
    #    then
    #        msg "starting Bitwarden Desktop Client"
    #        wslg.exe -d Ubuntu-24.04 --cd "~" -- /usr/bin/flatpak run --branch=stable --arch=x86_64 --command=bitwarden --file-forwarding com.bitwarden.desktop @@u &
    #    fi
    #fi
fi

if [ -n "$SUDO_USER" ] # if we sudo'd, try to use old users socket
then
    msg
    msg " we have sudo'd from user $SUDO_USER"
    SUDO_USER_HOME="`/usr/bin/getent passwd $SUDO_USER | /usr/bin/cut -f 6 -d:`"
    SUDO_AUTH_SOCK=`echo $AUTH_SOCK | /usr/bin/sed "s,^$HOME,$SUDO_USER_HOME,g"`
    SUDO_AUTH_SOCK_LINK=`echo $AUTH_SOCK_LINK | /usr/bin/sed "s,^$HOME,$SUDO_USER_HOME,g"`

    msg " SUDO_USER_HOME=$SUDO_USER_HOME"
    msg " SUDO_AUTH_SOCK=$SUDO_AUTH_SOCK"
    msg " SUDO_AUTH_SOCK_LINK=$SUDO_AUTH_SOCK_LINK"

    if [ -e "$SUDO_AUTH_SOCK" ]
    then
        export SSH_AUTH_SOCK="$SUDO_AUTH_SOCK"
        msg "checking if socket for user $SUDO_USER is active"
        msg "SSH_AUTH_SOCK=$SUDO_AUTH_SOCK"
        ssh-add -l 2>/dev/null >/dev/null
        if [ $? -ge 2 ]
        then
            msg "no, $SSH_AUTH_SOCK is not active"
            unset SSH_AUTH_SOCK
        else
            msg "yes, $SSH_AUTH_SOCK is active"
        fi
    fi

    if [ -e "$SUDO_AUTH_SOCK_LINK" ]
    then
        msg
        export SSH_AUTH_SOCK="$SUDO_AUTH_SOCK_LINK"
        msg "checking if socket for user $SUDO_USER is active"
        msg "SSH_AUTH_SOCK=$SUDO_AUTH_SOCK_LINK"
        ssh-add -l 2>/dev/null >/dev/null
        if [ $? -ge 2 ]
        then
            msg "no, $SSH_AUTH_SOCK is not active"
            unset SSH_AUTH_SOCK
        else
            msg "yes, $SSH_AUTH_SOCK is active"
        fi
    fi

    msg
    msg " using SSH_AUTH_SOCK from user $SUDO_USER"
    msg " SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
    msg " SSH_AUTH_SOCK_ORIG=$SSH_AUTH_SOCK_ORIG"
    msg " SUDO_USER=$SUDO_USER"
    msg " SUDO_USER_HOME=$SUDO_USER_HOME"
    msg " SUDO_AUTH_SOCK=$SUDO_AUTH_SOCK"
    msg " SUDO_AUTH_SOCK_LINK=$SUDO_AUTH_SOCK_LINK"

elif [ -n "$SSH_AUTH_SOCK" ] # if we have been pased an SSH_AUTH_SOCK then
then
    msg
    msg " yes, we have SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
    [ -d "$AUTH_SOCK_D" ] || ( /bin/mkdir "$AUTH_SOCK_D"; /bin/chmod 0700 "$AUTH_SOCK_D" )
    msg " SSH_AUTH_SOCK was set to:  $SSH_AUTH_SOCK"

    # SSH_AUTH_SOCK is not pointing to the local one if we are running on WSL2
    if [ "$SSH_AUTH_SOCK" != "$AUTH_SOCK" ] # if SSH_AUTH_SOCK is not pointing to the local one then
    then
        msg
        msg "  SSH_AUTH_SOCK:$SSH_AUTH_SOCK != AUTH_SOCK:$AUTH_SOCK"
        # check if the one passed is active, if it is, use this one
        msg "  SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
        if [ "$WSL2" != true ]
        then
            ssh-add -l 2>/dev/null >/dev/null   # test if local socket is active
        fi
        if [ $? -ge 2 ] && [ "$WSL2" != true ]  # if not active
        then
            msg
            msg "   $SSH_AUTH_SOCK is not active, use $AUTH_SOCK instead."
            export SSH_AUTH_SOCK="$AUTH_SOCK"
        else
            msg
            if [ "$WSL2" == true ]
            then
                msg "    $SSH_AUTH_SOCK : we are WSL2 so no need to check."
            else
                msg "    $SSH_AUTH_SOCK is active, use it."
            fi

            msg
            if [ "$SSH_AUTH_SOCK" == "$AUTH_SOCK_LINK" ]
            then
                msg "    SSH_AUTH_SOCK == AUTH_SOCK_LINK. We must be using tmux so do nothing"
                unset SSH_AUTH_SOCK_ORIG
            else
                export SSH_AUTH_SOCK_ORIG="$AUTH_SOCK_D/SOCK_`basename "$SSH_AUTH_SOCK"`"
                msg "    ln -sf $SSH_AUTH_SOCK $SSH_AUTH_SOCK_ORIG"
                [ -e "$SSH_AUTH_SOCK_ORIG" ] && /bin/rm -f "$SSH_AUTH_SOCK_ORIG"
                ln -sf "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK_ORIG"

                msg "    ln -sf $SSH_AUTH_SOCK_ORIG $AUTH_SOCK_LINK"
                [ -e "$AUTH_SOCK_LINK" ] && /bin/rm -f "$AUTH_SOCK_LINK"
                ln -sf "$SSH_AUTH_SOCK_ORIG" "$AUTH_SOCK_LINK"
                
                export SSH_AUTH_SOCK="$AUTH_SOCK_LINK"

                msg "    SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
                msg "    SSH_AUTH_SOCK_ORIG=$SSH_AUTH_SOCK_ORIG"
            fi
        fi
    fi
else
    msg
    export SSH_AUTH_SOCK="$AUTH_SOCK"   # change to use local socket
    msg " SSH_AUTH_SOCK not set, setting to: $SSH_AUTH_SOCK"
fi

msg
if [ "$WSL2" == "false" ]
then
    # ok, now we should be pointing to the right socket file
    # lets check if it is active
    msg " checking SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
    msg
    ssh-add -l 2>/dev/null >/dev/null   # test if socket is active
    if [ $? -ge 2 ]
    then
        msg "  agent not active, activating agent now."
        # not active, lets start ssh-agent then
        eval `$SSH_AGENT -a "$SSH_AUTH_SOCK"` || /bin/true
        msg "$SSH_AGENT: started on: $SSH_AUTH_SOCK"
    else
        msg "  agent already active, nothing to be done."
    fi
else
    msg " We are running on WSL2, just use local socket always"
fi

unset AUTH_SOCK
unset AUTH_SOCK_LINK
unset AUTH_SOCK_D
unset SSH_AGENT

SCRIPT=""
# add logout function to logout script
[ -e "/usr/local/scripts/profile.d/ssh-agent.sh" ] && SCRIPT="/usr/local/scripts/profile.d/ssh-agent.sh"
[ -e "/etc/profile.d/ssh-agent.sh" ] && SCRIPT="/etc/profile.d/ssh-agent.sh"
if [ -e "$SCRIPT" ]
then
    if [ ! -e ~/.bash_logout ] || [ "`fgrep -c "/bin/bash $SCRIPT logout" ~/.bash_logout`" == 0 ]
    then
        echo "/bin/bash SCRIPT logout" >> ~/.bash_logout
        /bin/chmod 0600 ~/.bash_logout
    fi
fi

echo
if [ "$WSL2" == "false" ]
then
    ssh-add -l
    echo
fi

PATH="$path"
unset SCRIPT
unset path

