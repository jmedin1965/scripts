#!/bin/bash

main()
{
    [ $# == 0 ] && error "Usage: $(/usr/bin/basename "$0") <client>..."

    for client in "$@"
    do
        echo process: $client
        cmd "$client" /opt/puppetlabs/bin/puppet resource service puppet ensure=stopped
        ssldir=$(cmd "$client" /opt/puppetlabs/bin/puppet config print ssldir --section agent)
        certname=$(cmd "$client" /opt/puppetlabs/bin/puppet config print certname --section agent)
        echo ssldir=\"$ssldir\"
        echo certname=\"$certname\"
        [ -n "$ssldir" ] || error "Unable to get SSL directory"
        [ -n "$certname" ] && /opt/puppetlabs/bin/puppetserver ca clean --certname "$certname"
        cmd "$client" /bin/rm -rf "$ssldir"
        cmd "$client" /opt/puppetlabs/bin/puppet resource service puppet ensure=running
        for i in {1..10}
        do
            sleep 5
            [ "$(/opt/puppetlabs/bin/puppetserver ca list | /bin/fgrep -c -n "$certname")" -gt 0 ] && break
        done
        /opt/puppetlabs/bin/puppetserver ca sign --certname "$certname"
        cmd "$client" /opt/puppetlabs/bin/puppet agent --test

    done
}

cmd()
{
    local c="$1"
    shift
    /usr/bin/ssh -l root "$c" "$@" || error "$c: $@" 
}

error()
{
    echo "Error: $@" > /dev/stderr
    exit 1
}

read_ini()
{
	local file="$1"
	local sec="$2"
	local key="$3"

	local cur_sec=""

	while read line
	do
		case "$line" in
			"["*"]")
				cur_sec="${line#[}"
				cur_sec="${cur_sec%]}"
				;;
			*"="*)
				if [ "$sec" == "$cur_sec" ]
				then
					k="${line%% =*}"
					k="${k// /}"
					d="${line#*= }"
					[ "$k" == "$key" ] && echo "$d" && return 0
				fi
				;;
		esac
	done <<< "$(<$file)"

}

main "$@"
exit $?

read_ini /etc/puppetlabs/puppet/puppet.conf agent certname

exit 0

echo clearing puppet agent cert

puppet resource service puppet ensure=stopped

certs_dir=$(puppet config print ssldir --section agent)

echo certs dir = $certs_dir

ls $certs_dir

if [ -n "$certs_dir" -a -d "$certs_dir" ]
then
	echo deleting old certs
	find "$certs_dir" -name *.pem -exec rm {} \;
fi

puppet resource service puppet ensure=running
puppet agent -t

echo now sign the cert on the master
echo you may have to clean out the old one; puppet cert clean \<cert name\>
