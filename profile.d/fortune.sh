
if [ -x /usr/local/scripts/bin/fortune ] && [ "`fgrep -c "/usr/local/scripts/bin/fortune" ~/.bashrc`" == 0 ]
then
    echo installing fortune
    echo "echo" >> ~/.bashrc
    echo "/usr/local/scripts/bin/fortune" >> ~/.bashrc
    echo "echo" >> ~/.bashrc
    /bin/chmod 0640 ~/.bashrc
fi

