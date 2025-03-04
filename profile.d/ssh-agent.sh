
export AUTH_SOCK=~/.ssh/ssh-agent.sock
export AUTH_SOCK_LINK=~/.ssh/ssh-agent-link.sock
export AUTH_SOCK_D=~/.ssh/ssh-agent.sock.d
export SSH_AGENT="ssh-agent"
WIN_SSH_AGENT="/c/Program Files/OpenSSH-Win64/ssh.exe"
WIN_SSH_KEY=~/.ssh/id_rsa.pub
WIN_SSH_AUTHORIZED_KEYS_F=~/.ssh/authorized_keys

DEBUG="1"
msg()
{
    if [ "$DEBUG" -gt 0 ]
    then
        echo "msg:" "$@"
    fi
}

# did this for FreeBSD/PFsense
run_cmd()
{
    local c=""

    if [ -x "/bin/$1" ]
    then
        c="/bin/$1"

    elif [ -x "/usr/bin/$1" ]
    then
        c="/usr/bin/$1"
    else
        return 1
    fi

    shift
    "$c" "$@"
}

# a function to trap CTRL_C since ssh-add times out or waits forever
ctrl_c() {
    echo "** Trapped CTRL-C"
    echo "msg: trap done"
}
# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

if [ "$1" == logout ]
then
	msg "Loggout: SSH_AUTH_SOCK_ORIG=$SSH_AUTH_SOCK_ORIG"
	if [ -n "$SSH_AUTH_SOCK_ORIG" ]
	then
		msg "remove SSH_AUTH_SOCK that this session was using $SSH_AUTH_SOCK_ORIG"
		msg /bin/rm -f "$SSH_AUTH_SOCK_ORIG"
        export SSH_AUTH_SOCK=""
        for SSH_AUTH_SOCK_ORIG in `/bin/ls -c --reverse "$AUTH_SOCK_D"/*`
		do
			if [ -S "$SSH_AUTH_SOCK_ORIG" ]
			then
                if [ -z "$SSH_AUTH_SOCK" ]
                then
                    export SSH_AUTH_SOCK="$SSH_AUTH_SOCK_ORIG"
                    msg "testing: $SSH_AUTH_SOCK"
                    ssh-add -l 2>/dev/null >/dev/null   # test if local socket is active
                    if [ $? -ge 2 ] # if not active
                    then
                        msg " loop: /bin/rm -f \"$SSH_AUTH_SOCK_ORIG\""
                        /bin/rm -f "$SSH_AUTH_SOCK_ORIG"
                    else
                        msg " loop: ln -sf \"$SSH_AUTH_SOCK_ORIG\" \"$AUTH_SOCK_LINK\""
                        [ -e "$AUTH_SOCK_LINK" ] && /bin/rm -f "$AUTH_SOCK_LINK"
                        /bin/ln -sf "$SSH_AUTH_SOCK_ORIG" "$AUTH_SOCK_LINK"
                    fi
                fi
			else
				msg " loop: /bin/rm -f \"$SSH_AUTH_SOCK_ORIG\""
				/bin/rm -f "$SSH_AUTH_SOCK_ORIG"
			fi
		done
	fi
    msg done
	exit 0
fi

export SSH_AUTH_SOCK_ORIG=""

# Cygwin ssh-agent socket
if [ "`run_cmd uname -o`" == "Cygwin" ]
then
    AUTH_SOCK=~/.ssh/ssh-agent-pageant.sock
    SSH_AGENT="/usr/bin/ssh-pageant"
    msg "we are using Cygwin."
fi


msg "SUDO_USER=$SUDO_USER"
# WSL2, hack to use openssh to create the ssh-agent tunnel
if [[ "`run_cmd uname -r`" =~ .*WSL2 ]] 
then
    msg "we are using WSL2"
    export AUTH_SOCK=~/.ssh/ssh-agent-link.sock

    if [ -n "$SUDO_USER" ]
    then
        msg "we have SUDO'd from $SUDO_USER"

    elif [ -n "$SSH_AUTH_SOCK" ]
    then
        msg "we have been passed a socket, using this socket."

    elif [ -x "$WIN_SSH_AGENT" ]
    then
        export SSH_AUTH_SOCK="$AUTH_SOCK"
        ssh-add -l 2>/dev/null >/dev/null   # test if socket is active
        if [ $? -ge 2 ]
        then
            if ! /usr/bin/fgrep -q "`/usr/bin/cat "$WIN_SSH_KEY"`" "$WIN_SSH_AUTHORIZED_KEYS_F"
            then
                msg "adding key to auth keys file"
                /usr/bin/cat "$WIN_SSH_KEY" >> "$WIN_SSH_AUTHORIZED_KEYS_F" 
            fi

            msg "about to start ssh-agent tunel"
            "$WIN_SSH_AGENT" -o IdentitiesOnly=yes -A -p 2222 ${USER}@`/usr/bin/hostname -I` -t -t bash -c \
                ": ; ln -sf \"\$SSH_AUTH_SOCK\" $AUTH_SOCK ; while :; do sleep 1d ; done"&
                #": ; ln -sf \"\$SSH_AUTH_SOCK\" $AUTH_SOCK ; sleep 2d ; echo done"&
                #': ; ln -sf "$SSH_AUTH_SOCK" ~/.ssh/ssh-agent-link.sock ; sleep infinity ; echo done'&
            msg "done start ssh-agent tunel"
            sleep 2
        else
            msg "agent already active, nothing to be done."
        fi
    else
        msg "err: $WIN_SSH_AGENT: prog does not exist, please install it."
    fi
fi

# if we have been pased an SSH_AUTH_SOCK then
if [ -n "$SSH_AUTH_SOCK" ]
then
    msg "yes, we have SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
    [ -d "$AUTH_SOCK_D" ] || ( /bin/mkdir "$AUTH_SOCK_D"; /bin/chmod 0700 "$AUTH_SOCK_D" )
    msg "SSH_AUTH_SOCK was set to: $SSH_AUTH_SOCK"
    if [ "$SSH_AUTH_SOCK" != "$AUTH_SOCK" ] # if SSH_AUTH_SOCK is not pointing to the local one then
    then
        msg "SSH_AUTH_SOCK:$SSH_AUTH_SOCK != AUTH_SOCK:$AUTH_SOCK"
        # check if the one passed is active, if it is, use this one
        ssh-add -l 2>/dev/null >/dev/null   # test if local socket is active
        if [ $? -ge 2 ] # if not active
        then
            msg "$SSH_AUTH_SOCK is not active, use $AUTH_SOCK instead."
            export SSH_AUTH_SOCK="$AUTH_SOCK"
        else
            msg "$SSH_AUTH_SOCK is active, use it."

            if [ "$SSH_AUTH_SOCK" == "$AUTH_SOCK_LINK" ]
            then
                msg "SSH_AUTH_SOCK == AUTH_SOCK_LINK. We must be uning tmux so do nothing"
                unset SSH_AUTH_SOCK_ORIG
            else
                export SSH_AUTH_SOCK_ORIG="$AUTH_SOCK_D/`run_cmd basename "$SSH_AUTH_SOCK"`"
                msg "ln -sf $SSH_AUTH_SOCK $SSH_AUTH_SOCK_ORIG"
                [ -e "$SSH_AUTH_SOCK_ORIG" ] && /bin/rm -f "$SSH_AUTH_SOCK_ORIG"
                ln -sf "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK_ORIG"

                msg ln -sf "$SSH_AUTH_SOCK_ORIG" "$AUTH_SOCK_LINK"
                [ -e "$AUTH_SOCK_LINK" ] && /bin/rm -f "$AUTH_SOCK_LINK"
                ln -sf "$SSH_AUTH_SOCK_ORIG" "$AUTH_SOCK_LINK"
                
                export SSH_AUTH_SOCK="$AUTH_SOCK_LINK"

                msg SSH_AUTH_SOCK=$SSH_AUTH_SOCK
                msg SSH_AUTH_SOCK_ORIG=$SSH_AUTH_SOCK_ORIG
            fi
        fi
    fi

elif [ -n "$SUDO_USER" ] # if we sudo'd, try to use old users socket
then
    SUDO_USER_HOME="`/usr/bin/getent passwd $SUDO_USER | /usr/bin/cut -f 6 -d:`"
    SUDO_AUTH_SOCK=`echo $AUTH_SOCK | /usr/bin/sed "s,^$HOME,$SUDO_USER_HOME,g"`
    SUDO_AUTH_SOCK_LINK=`echo $AUTH_SOCK_LINK | /usr/bin/sed "s,^$HOME,$SUDO_USER_HOME,g"`

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
    msg "using SSH_AUTH_SOCK from user $SUDO_USER"
    msg SSH_AUTH_SOCK=$SSH_AUTH_SOCK
    msg SSH_AUTH_SOCK_ORIG=$SSH_AUTH_SOCK_ORIG
    msg SUDO_USER=$SUDO_USER
    msg SUDO_USER_HOME=$SUDO_USER_HOME
    msg SUDO_AUTH_SOCK=$SUDO_AUTH_SOCK
    msg SUDO_AUTH_SOCK_LINK=$SUDO_AUTH_SOCK_LINK
    msg
    
else
    export SSH_AUTH_SOCK="$AUTH_SOCK"   # change to use local socket
    msg "SSH_AUTH_SOCK not set, setting to: $SSH_AUTH_SOCK"
fi

# ok, now we should be pointing to the right socket file
# lets check if it is active
msg "checking SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
ssh-add -l 2>/dev/null >/dev/null   # test if socket is active
if [ $? -ge 2 ]
then
    msg "agent not active, activating agent now."
    # not active, lets start ssh-agent then
    eval `$SSH_AGENT -a "$SSH_AUTH_SOCK"` || /bin/true
    msg "$SSH_AGENT: started on: $SSH_AUTH_SOCK"
else
    msg "agent already active, nothing to be done."
fi

unset AUTH_SOCK
unset AUTH_SOCK_LINK
unset UTH_SOCK_D
unset SSH_AGENT

if [ -e "/etc/profile.d/ssh-agent.sh" ]
then
    if [ ! -e ~/.bash_logout ] || [ "`run_cmd fgrep -c "/bin/bash /etc/profile.d/ssh-agent.sh logout" ~/.bash_logout`" == 0 ]
    then
        echo "/bin/bash /etc/profile.d/ssh-agent.sh logout" >> ~/.bash_logout
        /bin/chmod 0600 ~/.bash_logout
    fi
fi

echo
ssh-add -l
echo

