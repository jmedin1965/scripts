#!/bin/bash

log()
{
	echo '***' "$@"
}

scripts="/etc/vmware-tools/scripts"

if [ -d /etc/vmware-tools/scripts ]
then
	for d in poweroff-vm-default.d  poweron-vm-default.d  resume-vm-default.d  suspend-vm-default.d
	do
		if [ ! -d "$scripts/$d" ]
		then
			log "mkdir $scripts/$d"
			/bin/mkdir "$scripts/$d"
		fi
	done


	/bin/cat << END > "$scripts/userscripts.subr"
#!/bin/bash

logbase=/var/log/vmware-userscripts
logfile=\$logbase.log

#
# Rotate any logs
#
rotate_logfile() {
    max=9
    max=\`expr \$max - 1\`
    for s in \`seq \$max -1 1\`; do
        d=\`expr \$s + 1\`
        [ -e \$logbase.\$s.log ] && mv -f \$logbase.\$s.log \$logbase.\$d.log
    done
    [ -e \$logbase.log ] && mv -f \$logbase.log \$logbase.1.log
}

rotate_logfile

# redirect stdio
exec > \$logfile 2>&1

echo
echo \`date\` \": Executing \'\$0 \$*\'\"

END

	/bin/cat << END > "$scripts/poweroff-vm-default.d/99-delay-shutdown"
#!/bin/bash

. \$(dirname "\$0")/../userscripts.subr

delay="120"

if [ "\$(/sbin/showmount -a 2>/dev/null| /usr/bin/wc -l)" == 0 ]
then
    echo "\$(date): \$(basename "\$0"): no exported shares, no need to delay shutdown."
else
    echo "\$(date): \$(basename "\$0"): start delay of \$delay seconds"
    sleep \$delay
    echo "\$(date): \$(basename "\$0"): finished delay"
fi

END
	/bin/chmod 755 "$scripts/poweroff-vm-default.d/99-delay-shutdown"
	/bin/ln -s "../poweroff-vm-default.d/99-delay-shutdown" "$scripts/suspend-vm-default.d"

else
	log "/etc/vmware-tools/scripts: dir does not exist, exiting"
fi
