
AUTH_SOCK=~/.ssh/ssh-agent.sock
AUTH_SOCK_LINK=~/.ssh/ssh-agent-link.sock
AUTH_SOCK_D=~/.ssh/ssh-agent.sock.d
SSH_AGENT="ssh-agent"

run_cmd()
{
    local c=""

    if [ -x "/bin/$1" ]
    then
        c="/bin/$1"

    elseif [ -x "/usr/bin/$1" ]
    then
        c="/usr/bin/$1"
    else
        return 1
    fi

    shift
    "$c" "$@"
}

if [ "$1" == logout ]
then
	echo "Loggout: SSH_AUTH_SOCK_ORIG=$SSH_AUTH_SOCK_ORIG"
	if [ -n "$SSH_AUTH_SOCK_ORIG" ]
	then
		echo "remove SSH_AUTH_SOCK that this session was using $SSH_AUTH_SOCK_ORIG"
		echo /bin/rm -f "$SSH_AUTH_SOCK_ORIG"
        SSH_AUTH_SOCK=""
        for SSH_AUTH_SOCK_ORIG in $(/bin/ls -c --reverse "$AUTH_SOCK_D"/*)
		do
			if [ -S "$SSH_AUTH_SOCK_ORIG" ]
			then
                if [ -z "$SSH_AUTH_SOCK" ]
                then
                    SSH_AUTH_SOCK="$SSH_AUTH_SOCK_ORIG"
                    echo "testing: $SSH_AUTH_SOCK"
                    ssh-add -l 2>/dev/null >/dev/null   # test if local socket is active
                    if [ $? -ge 2 ] # if not active
                    then
                        echo " loop: /bin/rm -f \"$SSH_AUTH_SOCK_ORIG\""
                        /bin/rm -f "$SSH_AUTH_SOCK_ORIG"
                    else
                        echo " loop: ln -sf \"$SSH_AUTH_SOCK_ORIG\" \"$AUTH_SOCK_LINK\""
                        /bin/ln -sf "$SSH_AUTH_SOCK_ORIG" "$AUTH_SOCK_LINK"
                    fi
                fi
			else
				echo " loop: /bin/rm -f \"$SSH_AUTH_SOCK_ORIG\""
				/bin/rm -f "$SSH_AUTH_SOCK_ORIG"
			fi
		done
	fi
    echo done
	exit 0
fi

export SSH_AUTH_SOCK_ORIG=""

# Cygwin ssh-agent socket
if [ "`run_cmd uname -o`" == "Cygwin" ]
then
    AUTH_SOCK=~/.ssh/ssh-agent-pageant.sock
    SSH_AGENT="/usr/bin/ssh-pageant"
    echo "msg: we are using Cygwin."
fi

# if we have been pased an SSH_AUTH_SOCK then
if [ -n "$SSH_AUTH_SOCK" ]
then
    [ -d "$AUTH_SOCK_D" ] || ( /bin/mkdir "$AUTH_SOCK_D"; /bin/chmod 0700 "$AUTH_SOCK_D" )
    echo "msg: SSH_AUTH_SOCK was set to: $SSH_AUTH_SOCK"
    if [ "$SSH_AUTH_SOCK" != "$AUTH_SOCK" ] # if SSH_AUTH_SOCK is not pointing to the local one then
    then
        echo "msg: SSH_AUTH_SOCK:$SSH_AUTH_SOCK != AUTH_SOCK:$AUTH_SOCK"
        # check if the one passed is active, if it is, use this one
        ssh-add -l 2>/dev/null >/dev/null   # test if local socket is active
        if [ $? -ge 2 ] # if not active
        then
            echo "msg: $SSH_AUTH_SOCK is not active, use $AUTH_SOCK instead."
            export SSH_AUTH_SOCK="$AUTH_SOCK"
        else
            echo "msg: $SSH_AUTH_SOCK is active, use it."

            SSH_AUTH_SOCK_ORIG="$AUTH_SOCK_D/`run_cmd basename "$SSH_AUTH_SOCK"`"
            echo ln -sf "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK_ORIG"
            ln -sf "$SSH_AUTH_SOCK" "$SSH_AUTH_SOCK_ORIG"

            echo ln -sf "$SSH_AUTH_SOCK_ORIG" "$AUTH_SOCK_LINK"
            ln -sf "$SSH_AUTH_SOCK_ORIG" "$AUTH_SOCK_LINK"
            
            export SSH_AUTH_SOCK="$AUTH_SOCK_LINK"

            echo SSH_AUTH_SOCK=$SSH_AUTH_SOCK
            echo SSH_AUTH_SOCK_ORIG=$SSH_AUTH_SOCK_ORIG
            export SSH_AUTH_SOCK_ORIG
        fi
    fi
else
    export SSH_AUTH_SOCK="$AUTH_SOCK"   # change to use local socket
    echo "msg: SSH_AUTH_SOCK not set, setting to: $SSH_AUTH_SOCK"
fi

# ok, now we should be pointing to the right socket file
# lets check if it is active
ssh-add -l 2>/dev/null >/dev/null   # test if socket is active
if [ $? -ge 2 ]
then
    echo "msg: agent not active, activating agent now."
    # not active, lets start ssh-agent then
    eval `$SSH_AGENT -a "$SSH_AUTH_SOCK"` || /bin/true
    echo "$SSH_AGENT: started on: $SSH_AUTH_SOCK"
else
    echo "msg: agent already active, nothing to be done."
fi

unset AUTH_SOCK
unset AUTH_SOCK_LINK
unset UTH_SOCK_D
unset SSH_AGENT

if [ -e "/etc/profile.d/ssh-agent.sh" ]
then
    if [ ! -e ~/.bash_logout ] || [ "$(/bin/fgrep -c "/bin/bash /etc/profile.d/ssh-agent.sh logout" ~/.bash_logout)" == 0 ]
    then
        echo "/bin/bash /etc/profile.d/ssh-agent.sh logout" >> ~/.bash_logout
        /bin/chmod 0600 ~/.bash_logout
    fi
fi

