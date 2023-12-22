#!/bin/bash

#echo "$(date): " "$@" >> /tmp/test.log

for m in {c..z}
do
    [ -d /mnt/$m ] || /bin/mkdir /mnt/$m
done

#service ssh start

