
# ProxMox Mail Gateway

Used to relay and receive email in and out. Easy to manage and configure once you get your head around it.

## install

Install as a standars CT template in proxmox. If you want to send emails out from it like reports, it will need a valid domain, as the "myorigin" in /etc/postfix/main.cf  can't be changes as far as I can tell.

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


