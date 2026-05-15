#!/bin/bash

cp /etc/issue /etc/issue.net save
cp /etc/motd save
cp /var/run/motd.dynamic save
cp -a /etc/update-motd.d save
