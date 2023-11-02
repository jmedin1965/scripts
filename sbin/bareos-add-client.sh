#!/bin/bash
#
#add a client
#REF: https://svennd.be/adding-a-linux-client-to-bareos/
#
#create backup job
#REF: https://svennd.be/create-a-backup-job-on-bareos/
#
main()
{
    check_agp

    #
    # We need arguments as a host to add the client to
    #
    if [ $# == 0 ]
    then
        err "Usage: $(basename "$0") host ..."
    else
        # for each command line arg
        while [ $# != 0 ]
        do
            # check if host is live
            if ping -W 2 -c 1 "$1" 2>&1 > /dev/null
            then
                msg "$1: yes we have ping response"

                # use a modified add_bareos_repositories.sh script to add bareos repo"
                /usr/bin/scp "$(/usr/bin/dirname "$0")/add_bareos_repositories.sh" $1:/tmp
                /usr/bin/ssh $1 -x "/bin/chmod 755 /tmp/add_bareos_repositories.sh"
                /usr/bin/ssh $1 -x /tmp/add_bareos_repositories.sh
                /usr/bin/ssh $1 -x /bin/rm /tmp/add_bareos_repositories.sh

                # install the bareos-filedaemon
                /usr/bin/ssh $1 -x "/usr/bin/apt update"
                /usr/bin/ssh $1 -x "/usr/bin/apt -y upgrade"
                /usr/bin/ssh $1 -x "/usr/bin/apt -y install bareos-filedaemon"


                # install maria DB Backup and bareos mariadbbackup plugin
                # REF: https://docs.bareos.org/TasksAndConcepts/Plugins.html#storage-daemon-plugins 
                # REF: https://docs.bareos.org/Appendix/Howtos.html
                if is_installed "$1" mariadb-server
                then
                    # copy db scripts
                    /usr/bin/scp /usr/local/scripts/sbin/bareos-create-db-user.sh  $1:/root
                    /usr/bin/ssh $1 -x "/bin/ln -fs /root/bareos-create-db-user.sh /root/bareos-drop-db-user.sh"
                    generate_restore_readme | /usr/bin/ssh $1 -x "/bin/cat > /root/restore-readme.txt" 

                    /usr/bin/ssh $1 -x "/usr/bin/apt -y install mariadb-backup bareos-filedaemon-mariabackup-python-plugin"
                    /usr/bin/ssh $1 -x "/bin/cp -f /etc/bareos/bareos-fd.d/client/myself.conf /etc/bareos/bareos-fd.d/client/myself.conf.bak"
                    /usr/bin/ssh $1 -x "/bin/sed -e 's/\(\s*\)#\s*\(Plugin Directory\s*=\)/\1\2/g' -e 's/\(\s*\)#\s*\(Plugin Names\s*=\).*/\1\2 \"python3\"/g' /etc/bareos/bareos-fd.d/client/myself.conf.bak > /etc/bareos/bareos-fd.d/client/myself.conf"
                fi

                # the client details
                name="$(/usr/bin/ssh $1 -x /usr/bin/hostname --short)-fd"
                echo name=$name
                ip="$(set -- $(/usr/bin/host $1); echo $4)"
                echo ip=$ip
                pw=$(/usr/bin/apg -a 1 -n 1 -m 16 -M SNCL)
                echo pw=$pw

                if [ -e "/etc/bareos/bareos-dir.d/client/$name.conf" ]
                then
                    msg "client file for $name exists. Has this client already been added?"
                else
                    # add client and extract client file for copying
                    exp_file=$(echo "configure add client name=$name address=$ip password=$pw" | /usr/bin/sudo -u bareos bconsole)
                    echo "$exp_file"
                    exp_file=$(echo "$exp_file" | /usr/bin/fgrep "Exported resource file") 
                    exp_file=${exp_file#*\"}
                    exp_file=${exp_file%\"*}
                    echo exp_file=$exp_file

                    # copy client file to client
                    [ -n "$exp_file" ] && /usr/bin/scp "$exp_file" $1:/etc/bareos/bareos-fd.d/director/

                    # restart bareos-fd on client host
                    /usr/bin/ssh $1 -x /usr/bin/systemctl restart bareos-fd

                    # reload bareos from bconsole
                    echo reload | /usr/bin/sudo -u bareos bconsole
                fi

                # display client info
                echo "resolve client=$name" | /usr/bin/sudo -u bareos bconsole
            else
                msg "$1: no ping response, skipping"
            fi

            shift
        done
    fi
}

msg()
{
	echo "mgs:" "$@"
}

err()
{
    msg "$@" > /dev/stderr
}

is_installed()
{
    if [ -n "$1" -a -n "$2" ] 
    then
        [ "$(/usr/bin/ssh $1 -x "/usr/bin/apt list --installed | /usr/bin/fgrep "$2" -c")" -gt 0 ] && return 0 
    else
        return 2
    fi

    return 1
}

generate_restore_readme()
{
    echo "
REF: https://docs.bareos.org/TasksAndConcepts/Plugins.html#restore-with-mariabackup-plugin

REF: https://mariadb.com/kb/en/incremental-backup-and-restore-with-mariabackup/

Turnkey manages a git repo at /etc and does a daily commit. So to restore the system;

* put back /etc/.git
* do a git status to see what has chnaged
* do a git checkout to do a restore

One problem is that there may have been changes since the last backup. This is why I also back up the whole
/etc folder. in the restore location, you can do a git status to see if there are any uncommited changes.
you can then do a;

git add -A
git commit -m "add changes since last commit to this restore"

Now you have all the changes commited to the git repo. Now you can copy the .git folder to /etc/.git and then
do a git status and a git checkout

    good luck.
"
}

#
# agp random password generator
#
check_agp()
{
    if [ ! -x /usr/bin/apg ] 
    then
        mgs "installing apg password generator"
        /usr/bin/apt install apg
    fi
}

main "$@"

