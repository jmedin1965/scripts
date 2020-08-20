
# Postfix configuration for a host/server

I'm using postfix to send out emails from all the vm's that need to send emails out. It's pre-installed most of the time. If not just do an

    apt install postfix

To send out emails, if the hosts domain is not real, then you need to change myorigin to a valid domain and also use the bse-mailx package instead of mailutils. If you do use mail from mailutils, then use the -r option. If you don't, the from field of your outgoing messages will be invalid, which will cause the message to be rejected.

## send options 

    mydomain = servers domain

    myhostname = fully qualified name

    myorigin = This is important if your domain 
        is not a real domain because outgoing get stamped using
        this as the from address. By default on ubuntu, this is set to a file

    mydestination = a list of command separated fully qualifies server names. All
        of these are considered to be localy handled by this server, and are delivered
        localy.

    relayhost = This is the host that will reay outgoing mail for us.

    mynetworks = space separated list of local networks





Install and a standars CT template in proxmox. No need for a valid external domain, can just use fake internal domain.

## Configure

### Relaying

    Configuration>>Mail Poxy>> Ports
    Default Relay: forenam.jmsh-home.dtdns.net - ip or name of host to receive mail from external
    Relay Port: 25 - port of above host
    Disable MX lookup (SMTP): yes - we don't want to look up MX records, just use these settings instead
    Smarthost: smtp.dodo.com.au:25 - our external relay

REF: https://electrictoolbox.com/configure-postfix-external-connections/

to get forenam.jmsh-home.dtdns.net to accept email requites;

    inet_interfaces = all
    or
    inet_interfaces = locahost ip_address

in /etc/postfix/main.cf

but this did not work. I also had to change /etc/postfix/master.cf

    127.0.0.1:smtp inet n - - - - smtpd
    to
    smtp inet n - - - - smtpd


### Relay Domains

    Configuration>>Mail Poxy>> Ports

A list of all domains tha we will receive and forward from external. Everithing else will be rejected.

### Ports

I ended up swapping input and output ports. By default, port 25 is the external port, and 26 is the internal. Since I'm forwarding from the firewall, I created a rule to forward external port 25 to port 26 on the GW.

    Configuration>>Mail Poxy>> Ports
    External SMTP Port 26
    External SMTP Port 25

### Networks

A list of networks that are considered local. We will relal from everyone on this list

### Mail Filter

#### Added Action - Has Been Scanned Notice

Just adds a message to outgoing mail. More as a test and to make sure incoming mail gets tagged.

    This e-mail has been processed and 
    scanned by ProxMox Mail Gateway

#### created filter - Add Disclaimer

Enabled disclaimer on outgoing mail Priority 60

#### created filter - Add Scanned Notice

Add Scanned Notice on incomming mail, Priority 60

# to do

# ansible

add the above settings to ansible

make sure we exclude the proxmox mail gateway and make different settings for our intermal mail receiver

