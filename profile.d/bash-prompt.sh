if [ -n "$BASHPID" ] && [ -n "$PS1" ]
then

        export PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\n\$ '
fi
