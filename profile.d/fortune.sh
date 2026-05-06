
if [ -x /usr/bin/apt -a -x /usr/local/scripts/bin/fortune ] && ( [ ! -e ~/.bashrc ] || [ "`fgrep -c "/usr/local/scripts/bin/fortune" ~/.bashrc`" == 0 ] )
then
    echo installing fortune
    echo '[[ $- == *i* ]] && echo && /usr/local/scripts/bin/fortune && echo' >> ~/.bashrc
    /bin/chmod 0640 ~/.bashrc
fi

