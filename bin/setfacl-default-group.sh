#!/bin/bash

#
# using acl, set group inheritance so all files and dirs have group and user permissions
# are copied from the parent dir
#

if [ $# == 0 ]
then
    echo "Usage: $(/usr/bin/basename "$0") <file|dir>..."
else
    /bin/chmod g+s "$@"
    /usr/bin/setfacl --default --modify user::rwx,group::rwx,other::r-x "$@"
fi
