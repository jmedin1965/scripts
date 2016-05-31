
if [ "$1" == "-d" -o "$1" == "--gebug" ]
then
	opts="--test-cert"
fi

#opts="--test-cert"
cmd="letsencrypt-auto certonly $opts --webroot -w /var/www"

for host in ipfire www .
do
	if [ "$host" == '.' ]
	then
		host=""
	else
		host="$host."
	fi

	for domain in jmsh-home.dtdns.net dsl-jmsh.dtdns.net oxleymassage.dtdns.net
	do
		cmd="$cmd -d $host$domain"
	done
done

$cmd && /etc/init.d/apache2 restart

