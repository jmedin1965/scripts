#!/bin/bash

apt-get update
apt-get install -y vim git curl x11vnc novnc websockify tmux logrotate fortune-mod fortunes cron

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

