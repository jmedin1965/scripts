#!/bin/bash

apt-get install -y  x11vnc novnc websockify tmux logrotate cron

if [ ! -e /etc/x11vnc.pass ]
then
  x11vnc -storepasswd /etc/x11vnc.pass
  chmod 600 /etc/x11vnc.pass
fi

if [ ! -x /usr/bin/tailscale ]
then
  curl https://tailscale.com/install.sh | sudo sh
  tty -s && tailscale up
fi

