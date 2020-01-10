#!/bin/bash

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
