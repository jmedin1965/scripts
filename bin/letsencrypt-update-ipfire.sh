
if [ "$1" == "-d" -o "$1" == "--gebug" ]
then
	opts="--test-cert"
fi

letsencrypt-auto $opts \
	--apache \
	-d dsl-jmsh.dtdns.net \
	-d jmsh-home.dtdns.net \
	-d oxleymassage.dtdns.net \
	-d www.dsl-jmsh.dtdns.net \
	-d www.jmsh-home.dtdns.net \
	-d www.oxleymassage.dtdns.net \
	-d ipfire.dsl-jmsh.dtdns.net \
	-d ipfire.jmsh-home.dtdns.net \
	-d ipfire.oxleymassage.dtdns.net \
	
