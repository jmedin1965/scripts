
# FreeIPA with off-line CA

I've installed a standaline dogtag server to use an an off-line CA

I'm going to install FreeIPA on a proxmox LXC container and sign it's certificate with the dogtag CA
server. The lxc container will be unpriviliged.

After a CentOS 8 install from template, I had to install some extra packages;

    yum install sudo

REF https://floblanc.wordpress.com/2016/09/02/using-a-dogtag-instance-as-external-ca-for-free-ipa-installation/

## Install part 1

replace the following below with your stuff;

    --hostname=
    -n your domani
    -r your domain un upper case
    -p a super secret password
    -a a super secret password

no need for --forwarder if you have /etc/resolve.conf, as this is filled with these values

    ipa-server-install \
        --hostname=fq.host \
        --setup-dns \
        --no-ntp \
        --setup-adtrust \
        --setup-kra \
        -n domain \
        -r DOMAIN \
        --netbios-name=GLI \
        -p 'password' -a 'password' \
        --external-ca

## Install part 2

now cat /root/ipa.csr and copy

got to dogtag web, SSL End Users Services, Manual Certificate Manager Signing Certificate Enrollment.

Configure firewallste copied certificate and fill in your information

take note of request number

go back to, Agent Services, List Requests

find the certificate request and click it, and approve it

now go back and click list certificates and find it, as the approval page does not have the complete certificate

copy the base64 encoded part to /root/ipa.cert

go back to list certificates and click on the CA, which would be certificate 1

copy the base64 encoding part tp /root/dogtagca.cert

now run part 2

    /sbin/ipa-server-install --external-cert-file=/root/ipa.cert --external-cert-file=/root/dogtagca.cert

enter your super secret password

## sucess message

	The ipa-client-install command was successful

	==============================================================================
	Setup complete

	Next steps:
        1. You must make sure these network ports are open:
                TCP Ports:
                  * 80, 443: HTTP/HTTPS
                  * 389, 636: LDAP/LDAPS
                  * 88, 464: kerberos
                  * 53: bind
                UDP Ports:
                  * 88, 464: kerberos
                  * 53: bind

        2. You can now obtain a kerberos ticket using the command: 'kinit admin'
           This ticket will allow you to use the IPA tools (e.g., ipa user-add)
           and the web user interface.
        3. Kerberos requires time synchronization between clients
           and servers for correct operation. You should consider enabling chronyd.

	Be sure to back up the CA certificates stored in /root/cacert.p12
	These files are required to create replicas. The password for these
	files is the Directory Manager password
	The ipa-server-install command was successful

