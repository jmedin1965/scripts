#!/bin/bash

echo status ALL |sudo -u bareos bconsole | ( 

    echo "<html lang="en" xmlns="http://www.w3.org/1999/xhtml" xmlns:o="urn:schemas-microsoft-com:office:office"><head>"

    while read line
    do
	echo "<P>$line"
    done 

    echo "</head></html>"

) | mailx -a 'Content-Type: text/html' -s "Bareos Backup Report " juan.medin@global.komatsu

