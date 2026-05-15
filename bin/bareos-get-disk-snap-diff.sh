#!/bin/bash

# Gives a zvol and 2 snapshots, users rsync to work out what the difference is to make
# it easier to create a bareos fileset for backing up this volume or vm.
# standard directories are exclided from the scan.

vol="/dpool03/data/subvol-131-disk-0"

from=""
to=".zfs/snapshot/before-turn-on"

ls -lt "$vol/.zfs/snapshot"

# special word NOW = current state
[ "$from" == "NOW" ] && from=""
[ "$to" == "NOW" ]   && to=""

exclude=""
exclude="$exclude --exclude=/bin/**"
exclude="$exclude --exclude=/usr/bin/**"
exclude="$exclude --exclude=/var/log/**"
exclude="$exclude --exclude=/var/run/**"
exclude="$exclude --exclude=*/tmp/**"
exclude="$exclude --exclude=/proc/**/"
exclude="$exclude --exclude=/sys/**/"

if [ "$from" == "" ]
then
    from="$vol"
else
    from="$vol/$from"
fi

if [ "$to" == "" ]
then
    to="$vol"
else
    to="$vol/$to"
fi

#exclude=""

/usr/bin/rsync -va --dry-run $exclude "$from/" "$to/"
echo
echo /usr/bin/rsync -va --dry-run $exclude "$from/" "$to/"

