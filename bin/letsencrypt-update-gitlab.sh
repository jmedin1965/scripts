
if [ "$1" == "-d" -o "$1" == "--gebug" ]
then
	opts="--test-cert"
fi

#opts="--test-cert"
cmd="letsencrypt-auto certonly $opts --webroot -w /home/git/gitlab/public"
host="gitlab"

for domain in jmsh-home.dtdns.net dsl-jmsh.dtdns.net oxleymassage.dtdns.net
do
	cmd="$cmd -d $host.$domain"
done

$cmd
