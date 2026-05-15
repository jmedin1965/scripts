#!/bin/bash

mysql="/bin/cat"
mysql="/usr/bin/mysql -u root"

main()
{
    case "$0" in
        *create*)
            msg "create user"
            create "$@" | $mysql
            ;;
        *drop*)
            msg "drop user"
            drop "$@" | $mysql
            ;;
    esac
}

create()
{
    pw="12efG94JSfesV"
    h="localhost"
    user="bareos"

    # create ~/.my.cnf if it doesn't exist
    if [ $# == 0 ]
    then

        # does the db user already exist ? get count of db users matching this name
        count="$($mysql -se "SELECT Count(User) FROM mysql.user WHERE User='$user'")" 

        if [ ! -e ~/.my.cnf ]
        then
            msg ~/.my.cnf "does not exist, creating"

            if [ "$count" -gt 0 ]
            then
                msg "$user: db user exists but the .my.cnf file does not. we"
                msg "       are in trouble because we do not know the password."
                msg "       Best if you fix this file manually with the correct"
                msg "       password"
            fi

            pw=$(/usr/bin/tr -dc A-Za-z0-9 </dev/urandom | /usr/bin/head -c 13 ; echo '')
            echo "[client]

    user=$user
    password=$pw" > ~/.my.cnf

        else
            msg ~/.my.cnf "already exists, not creating"
        fi

        # read user and password from .my.cnf file
        read_my_cnf

        if [ "$count" -gt 0 ]
        then
            msg "$user: db user already exists, not creating"
        else
            msg "$user: creating db user."
            create_user
        fi
    fi

    for user in "$@"
    do
        create_user
    done
}

create_user()
{
    echo "CREATE USER '$user'@'$h' IDENTIFIED BY '$pw';"
    echo "SELECT User FROM mysql.user;"
    echo "GRANT ALL PRIVILEGES ON *.* TO '$user'@'$h' IDENTIFIED BY '$pw';"
    echo "FLUSH PRIVILEGES;"
    echo "SHOW GRANTS FOR '$user'@'$h';"
}

msg()
{
    echo "msg: $@" > /dev/stderr
}

read_my_cnf()
{
    user="$(/bin/grep '^user=' ~/.my.cnf)"
    user="${user##user=}"
    pw="$(/bin/grep '^password=' ~/.my.cnf)"
    pw="${pw##password=}"
}

drop_user()
{
    local u="$1"

    echo "DROP USER '$u';"
    echo "SELECT User FROM mysql.user;"
    echo "FLUSH PRIVILEGES;"
}

drop()
{
    for user in "$@"
    do
        drop_user "$user"
    done

    if [ $# == 0 ]
    then
        read_my_cnf
        drop_user "$user"
    fi
}

main "$@"
