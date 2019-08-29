
hostname="$(/bin/hostname -s)"
sshkey_foreman="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDHFJho1mt7ehzVjSTscFVNVBg+bLu8gstzOI8Pe4HbxnUrRNWH+8XKWdtRwN2e7NDOZyeLbeAuzfywtMD6crAssbUCv6aXI0Aq4gtBVHHC6f/okS5Fyql+cHY4dvNofmtdVJtFVFpSiAEZg2qysDVmfsFnnBRMbFA9E2EZxRZrj9wT75Fdk82PCsNPwbE4P+gAI6ba2F4orC5QEZR6klQ5f7JK6cx5nYIBYW6ZOrrJRDv/v4w46MFgwQ+zicgj3XlRUO1R5+QjykFA8rl9gwhtMmhfCCTKnlJEUvJVQS13o+1f30aaxzUDo+KDsr5V8XxBKzHgv+TLW0ezstwIo8Tr root@foreman.jmsh-home.dtdns.net"
old_ipfire_ip="10.10.1.1"
release="$(</etc/system-release)"
release="${release// /}"
cur_branch="$( /usr/bin/git branch | /bin/grep '^* ')"
cur_branch="${cur_branch#\* }"

msg()
{
	if [ $# == 0 ]; then
		echo "---------------------------------"
	else
		echo '***' "$@"
	fi
}


#
# Print some information
#
echo
echo
msg
msg "hostname      = \"$hostname\""
msg "old_ipfire_ip = \"$old_ipfire_ip\""
msg "release       = \"$release\""
msg "cur_branch    = \"$cur_branch\""
msg

#
# Setup ssh for root
#
msg "check ssh key and authorised_keys"
[ -f /root/.ssh/id_rsa ] || /usr/bin/ssh-keygen -f /root/.ssh/id_rsa -N "" && msg "generated new ssh key"
[ ! -f /root/.ssh/authorized_keys ] || [ "$(/bin/fgrep -c "${sshkey_foreman}" /root/.ssh/authorized_keys)" == 0 ] && echo "${sshkey_foreman}" >> /root/.ssh/authorized_keys && msg "added foreman ssh key" && msg "added authorized_keys"
/bin/chmod 600 /root/.ssh/authorized_keys
msg


#
# Add default rote via original ipfire with lower metric
#
/sbin/ip route add default via 10.10.1.1 metric 200
msg "added old ipfire as default gateway"
msg

#
# Check git branch
msg "check git branch"
[ "$release" == "$cur_branch" ] || msg "Error: $cur_branch: wrong branch, please check."
/usr/bin/git status
msg

#
# This fakes that we are online
#
touch /var/ipfire/red/active
msg "fake that we are online, create /var/ipfire/red/active"
msg

#
# Timezone
#
msg "Set Timezone to Australia/Sydney"
if [ -e /usr/bin/timedatectl ]
then
	msg "using /usr/bin/timedatectl"
	/usr/bin/timedatectl set-timezone Australia/Sydney
else
	if [ -e /usr/share/zoneinfo/Australia/Sydney ]
	then
		msg "using ln -s"
		rm -f /etc/localtime
		ln -s ../usr/share/zoneinfo/Australia/Sydney /etc/localtime
	fi
fi
ls -l /etc/localtime

#
# mailname file
#
msg "check /etc/mailname"
if [ -f /etc/mailname ]
then
	mailname="$(/bin/hostname -s).jmsh-home.com"
	echo $hname > /etc/mailname
	msg "set mailname to $mailname" 
fi

