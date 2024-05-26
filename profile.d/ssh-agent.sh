
AUTH_SOCK=~/.ssh/ssh-agent.sock
SSH_AGENT="ssh-agent"
AUTH_SOCK_ORIG=""

# Cygwin ssh-agent socket
if [ "$(/bin/uname -o)" == "Cygwin" ]
then
    AUTH_SOCK=~/.ssh/ssh-agent-pageant.sock
    SSH_AGENT="/usr/bin/ssh-pageant"
    echo "msg: we are using Cygwin."
fi

# if we have been pased an SSH_AUTH_SOCK then
if [ -n "$SSH_AUTH_SOCK" ]
then
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
            echo ln -sf "$SSH_AUTH_SOCK" "$AUTH_SOCK"
            ln -sf "$SSH_AUTH_SOCK" "$AUTH_SOCK"
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

