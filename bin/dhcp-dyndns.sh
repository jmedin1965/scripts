#!/bin/bash

# /usr/local/bin/dhcp-dyndns.sh

# This script is for secure DDNS updates on Samba 4
# REF: https://wiki.samba.org/index.php/Configure_DHCP_to_update_DNS_records_with_BIND9
# Version: 0.8.9

# Uncomment the next line if using a self compiled Samba and adjust for your PREFIX
PATH="/usr/local/samba/bin:/usr/local/samba/sbin:$PATH"
BINDIR=$(samba -b | grep 'BINDIR' | grep -v 'SBINDIR' | awk '{print $NF}')
WBINFO="$BINDIR/wbinfo"

#
# msg - print a message to logger or terminal
#
istty="$(/usr/bin/tty -s && echo true || echo false)"
msg()
{
	if [ "$istty" == true ]
	then
        	echo "$(/bin/date "+%b %d %H:%M:%S"):" "$@"
	else
        	logger -t DHCP-DYNDNS  "$@"
	fi
}


debug()
{
	local debuglevel="$1"
	shift

	[ "$debuglevel" -le "$DEBUG" ] && msg "$@"
}

#
# Process command line args
#
# -d = increase debug level DEBUG
#
DEBUG="0"
for arg in "$@"
do
	case "$arg" in
	"-d"*)
		arg="$1"
		arg="${arg#-d}"
		(( DEBUG = DEBUG + 1 ))
		shift

		if [ -z "${arg//d/}" ]; then
			arg="${#arg}"
			(( DEBUG = DEBUG + arg ))
		fi
		;;
	*)	break;;
	esac
done

# DNS domain
domain=$(/bin/hostname -d)
if [ -z ${domain} ]; then
    msg "Cannot obtain domain name, is DNS set up correctly?"
    msg "Cannot continue... Exiting."
    exit 1
fi
server="$(/usr/bin/host $domain)"
server="${server#* has address }"

# Samba 4 realm
REALM=$(echo ${domain^^})

# Additional nsupdate flags (-g already applied), e.g. "-d" for debug
NSUPDFLAGS="-d"
NSUPDFLAGS=""

# krbcc ticket cache
export KRB5CCNAME="/tmp/dhcp-dyndns.cc"

# Kerberos principal
SETPRINCIPAL="dhcpduser@${REALM}"
# Kerberos keytab
# /etc/dhcpduser.keytab
# krbcc ticket cache
# /tmp/dhcp-dyndns.cc
TESTUSER="$($WBINFO -u) | grep 'dhcpduser')"
if [ -z "${TESTUSER}" ]; then
    msg "No AD dhcp user exists, need to create it first.. exiting."
    msg "you can do this by typing the following commands"
    msg "kinit Administrator@${REALM}"
    msg "samba-tool user create dhcpduser --random-password --description=\"Unprivileged user for DNS updates via ISC DHCP server\""
    msg "samba-tool user setexpiry dhcpduser --noexpiry"
    msg "samba-tool group addmembers DnsAdmins dhcpduser"
    exit 1
fi

# Check for Kerberos keytab
if [ ! -f /etc/dhcpduser.keytab ]; then
    echo "Required keytab /etc/dhcpduser.keytab not found, it needs to be created."
    echo "Use the following commands as root"
    echo "samba-tool domain exportkeytab --principal=${SETPRINCIPAL} /etc/dhcpduser.keytab"
    echo "chown XXXX:XXXX /etc/dhcpduser.keytab"
    echo "Replace 'XXXX:XXXX' with the user & group that dhcpd runs as on your distro"
    echo "chmod 400 /etc/dhcpduser.keytab"
    exit 1
fi

# Variables supplied by dhcpd.conf
action=$1
ip=$2
DHCID=$3
name=${4%%.*}
supplied_domain=${4#*.}
[ "$supplied_domain" == "$4" ] && supplied_domain="$domain"

usage()
{
echo "USAGE:"
echo "  $(basename $0) add ip-address dhcid|mac-address hostname"
echo "  $(basename $0) delete ip-address dhcid|mac-address"
}

_KERBEROS () {
# get current time as a number
test=$(date +%d'-'%m'-'%y' '%H':'%M':'%S)
# Note: there have been problems with this
# check that 'date' returns something like
# 04-09-15 09:38:14

# Check for valid kerberos ticket
#logger "${test} [dyndns] : Running check for valid kerberos ticket"
klist -c /tmp/dhcp-dyndns.cc -s
if [ "$?" != "0" ]; then
    logger "${test} [dyndns] : Getting new ticket, old one has expired"
    kinit -F -k -t /etc/dhcpduser.keytab -c /tmp/dhcp-dyndns.cc "${SETPRINCIPAL}"
    if [ "$?" != "0" ]; then
        msg "${test} [dyndns] : dhcpd kinit for dynamic DNS failed"
        exit 1;
    fi
fi

}

# Exit if no ip address or mac-address
if [ -z "${ip}" ]; then  #|| [ -z "${DHCID}" ]; then
    usage
    exit 1
fi

# Exit if no computer name supplied, unless the action is 'delete'
if [ "${name}" = "" ]; then
    if [ "${action}" = "delete" ]; then
        name=$(host -t PTR "${ip}" | awk '{print $NF}' | awk -F '.' '{print $1}')
    else
        usage
        exit 1;
    fi
fi

# Set PTR address
ptr=$(echo ${ip} | awk -F '.' '{print $4"."$3"."$2"."$1".in-addr.arpa"}')

## nsupdate ##
case "${action}" in
add)
    _KERBEROS

nsupdate -g ${NSUPDFLAGS} << UPDATE
server 127.0.0.1
realm ${REALM}
update delete ${name}.${supplied_domain} 3600 A
update add ${name}.${supplied_domain} 3600 A ${ip}
send
UPDATE
result1=$?
debug 1 "update delete ${name}.${supplied_domain} 3600 A, update add ${name}.${supplied_domain} 3600 A ${ip}, result=$result1"

nsupdate -g ${NSUPDFLAGS} << UPDATE
server 127.0.0.1
realm ${REALM}
update delete ${ptr} 3600 PTR
update add ${ptr} 3600 PTR ${name}.${supplied_domain}
send
UPDATE
result2=$?
debug 1 "update delete ${ptr} 3600 PTR, update add ${ptr} 3600 PTR ${name}.${supplied_domain}, result=$result2"
;;
delete)
     _KERBEROS

nsupdate -g ${NSUPDFLAGS} << UPDATE
server 127.0.0.1
realm ${REALM}
update delete ${name}.${supplied_domain} 3600 A
send
UPDATE
result1=$?
debug 1 "update delete ${name}.${supplied_domain} 3600 A, result=$result1"

nsupdate -g ${NSUPDFLAGS} << UPDATE
server 127.0.0.1
realm ${REALM}
update delete ${ptr} 3600 PTR
send
UPDATE
result2=$?
debug 1 "update delete ${ptr} 3600 PTR, result=$result2"
;;
*)
echo "Invalid action specified"
exit 103
;;
esac

result="${result1}${result2}"

if [ "${result}" != "00" ]; then
    msg "DHCP-DNS Update failed: ${result}"
else
    msg "DHCP-DNS Update succeeded"
fi

exit ${result}

