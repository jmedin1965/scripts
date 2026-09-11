#!/bin/bash

timedatectl set-timezone Australia/Sydney

apt update
apt-upgrade
apt install nfs-kernel-server fuse unzip sudo -y

if [ ! -x /usr/local/bin/yq ]
then
  wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq &&\
    chmod +x /usr/local/bin/yq
fi

if [ -e /usr/bin/rclone ]
then
    /usr/bin/rclone selfupdate
else
    curl https://rclone.org/install.sh | bash
fi

