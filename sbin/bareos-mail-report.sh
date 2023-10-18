#!/bin/bash

main()
{
    header

    while read line
    do
	echo "<P>$line"
    done 

    footer
}

header()
{
    echo "<html lang="en" xmlns="http://www.w3.org/1999/xhtml" xmlns:o="urn:schemas-microsoft-com:office:office"><head>"
}

footer()
{
    echo "</head></html>"
}

echo "status ALL" \
    | /usr/bin/sudo -u bareos /usr/sbin/bconsole \
    | main "$@" \
    | mailx -a 'Content-Type: text/html' -s "Bareos Backup Report " juan.medin@global.komatsu
