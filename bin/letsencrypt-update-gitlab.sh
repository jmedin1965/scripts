
if [ "$1" == "-d" -o "$1" == "--gebug" ]
then
	opts="--test-cert"
fi

letsencrypt-auto certonly $opts \
	--webroot -w /home/git/gitlab/public \
	-d gitlab.jmsh-home.dtdns.net \
	-d gitlab.dsl-jmsh.dtdns.net \
	-d gitlab.oxleymassage.dtdns.net
	
