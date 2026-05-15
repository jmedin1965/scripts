#!/bin/bash

DEBUG="1"
msg()
{
    if [ "$DEBUG" -gt 0 ]
    then
            echo "msg:" "$@"
    fi
}

msg "starting"

export AUTH_SOCK=~/.ssh/ssh-agent.sock
WIN_SSH_AGENT="/c/Program Files/OpenSSH-Win64/ssh.exe"
WIN_SSH_KEY=~/.ssh/id_rsa.pub
WIN_SSH_AUTHORIZED_KEYS_F=~/.ssh/authorized_keys
WAIT="1d"
#WAIT="60"

if [ "$1" == do-ssh ]
then
    msg "stating ssh tunnel loop"
    msg "0 = $0"

    if [ -n "$SSH_AUTH_SOCK" ]
    then
        msg "We have SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
        # test if we have an active socket
        ssh-add -l 2>/dev/null >/dev/null   # test if socket is active
        if [ $? -ge 2 ]
        then
            msg "SSH_AUTH_SOCK is not active"
        else
            # REF: https://github.com/benpye/wsl-ssh-pageant/issues/33
            msg "SSH_AUTH_SOCK is active"
            msg "SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
            msg "AUTH_SOCK=$AUTH_SOCK"
            msg ln -sf "$SSH_AUTH_SOCK" "$AUTH_SOCK"
            ln -sf "$SSH_AUTH_SOCK" "$AUTH_SOCK"
            sleep $WAIT
            #ln -sf "$SSH_AUTH_SOCK\" $AUTH_SOCK ; while :; do sleep 1d ; done"
        fi
    else
        msg "We have no SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
    fi
else
    msg "start ssh service"
    if [ ! -f /etc/systemd/system/ssh_agent.service ]
    then
        msg "/etc/systemd/system/ssh_agent.service: service file does not exist, creating"
        cat << END > /etc/systemd/system/ssh_agent.service
[Unit]
Description=SSH Agent
After=ssh.service
ConditionPathExists=$WIN_SSH_AGENT

[Service]
User=1000
ExecStart=$(realpath "$0")
KillMode=process
Restart=on-failure
Type=simple

[Install]
WantedBy=multi-user.target
END
        msg "starting ssh_agent service"
        msg "check with: systemctl is-active ssh_agent"
        systemctl enable ssh_agent
        systemctl start ssh_agent
    else
        msg "USER=$(whoami)"
        export SSH_AUTH_SOCK="$AUTH_SOCK"
        while :
        do
            msg "check windows ssh keys"
            i="0"
            while [ $i -lt 20 ]
            do
                ((i++))
                msg "check windows ssh keys, attempt $i"
                if [ -e "$WIN_SSH_KEY" ]
                then
                    if ! /usr/bin/fgrep -q "`/usr/bin/cat "$WIN_SSH_KEY"`" "$WIN_SSH_AUTHORIZED_KEYS_F"
                    then
                        msg "adding key to auth keys file"
                        /usr/bin/cat "$WIN_SSH_KEY" >> "$WIN_SSH_AUTHORIZED_KEYS_F"
                    fi
                    i="99999"
                    msg "check windows ssh keys, done"
                else
                    msg "sleep 5"
                    sleep 5
                fi
            done

            msg "find local host IP address hostIP"
            hostIP=""
            for i in `/usr/bin/hostname -I`
            do
                case "$i" in
                    172.*)  hostIP="$i";;
                esac
            done

            # REF: https://github.com/benpye/wsl-ssh-pageant/issues/33
            msg "got local host ip address of $hostIP"
            msg "about to start ssh-agent tunel"
            "$WIN_SSH_AGENT" -o IdentitiesOnly=yes -A -p 2222 ${USER}@$hostIP -t -t bash -c \"\"$0\" do-ssh\"
            msg "tunnel ended, sleeping"
            sleep 10
                #": ; ln -sf \"\$SSH_AUTH_SOCK\" $AUTH_SOCK ; while :; do sleep 1d ; done"
            msg "done sleeping"
        done
    fi
fi

