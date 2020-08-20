
# FreeIPA with off-line CA

I've installed a standaline dogtag server to use an an off-line CA

I'm going to install FreeIPA on a proxmox LXC container and siggn it's certificate with the dogtag CA
server. The lxc container will be unpriviliged

REF https://floblanc.wordpress.com/2016/09/02/using-a-dogtag-instance-as-external-ca-for-free-ipa-installation/

## install apache and php - NOT REQUIRED!

    centOS 8 uses tomcat. If these are installed, dogtag instalation fails
    yum install http php

## Configure firewall

CentOS 8 used firewall-cmd

    firewall-cmd --permanent --zone=public --add-service=http
    firewall-cmd --permanent --zone=public --add-service=https

    # Not this one, as it's not secure, it's http
    #firewall-cmd --zone=public --add-port=8080/tcp
    # this one is https
    firewall-cmd --zone=public --add-port=8443/tcp

    firewall-cmd --reload 

## Entropy

make sure quemu-guest-client is installed. Also add VirtIO RNG to the guest hardware

    yum install qemu-guest-agent

## selinux

need to set selinux to permissive to do the install

    sudo setenforce 0
    sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config


## 389-ds-base pki-ca

    yum -y install @idm:DL1
    yum -y install 389-ds-base pki-ca

    dnf -y module install 389-directory-server:stable/default
    dscreate interactive

    systemctl enable dirsrv.target
    systemctl enable dirsrv@ca.service
    systemctl start dirsrv.target
    systemctl start dirsrv@ca.service
    systemctl status dirsrv.target
    systemctl status dirsrv@ca.service
    lsof -i -P -n | grep LISTEN

## dogtag theme

get the version ok pki that is installed

    yum list installed  | grep pki-base.noarch

during this install the version was 10.8.3 and this is the one that I found

    yum install http://rpmfind.net/linux/fedora/linux/releases/32/Everything/x86_64/os/Packages/d/dogtag-pki-server-theme-10.8.3-1.fc32.noarch.rpm

## Setup Dogtag CA

    pkispawn -s CA

    systemctl enable pki-tomcatd.target
    systemctl enable pki-tomcatd@
    systemctl start pki-tomcatd.target
    systemctl start pki-tomcatd@

now access via

    https://dogtag01.gli.lan:8443/ca
    
    ==========================================================================
                            INSTALLATION SUMMARY
    ==========================================================================

    Administrator's username:             caadmin
    Administrator's PKCS #12 file:
        /root/.dogtag/pki-tomcat/ca_admin_cert.p12

    To check the status of the subsystem:
        systemctl status pki-tomcatd@pki-tomcat.service

    To restart the subsystem:
        systemctl restart pki-tomcatd@pki-tomcat.service

    The URL for the subsystem is:
        https://dogtag01.gli.lan:8443/ca

    PKI instances will be enabled upon system boot

    ==========================================================================

## looks like I've somehow got it working to this point

This is a youtube tutorial

    https://www.youtube.com/watch?v=-Fak3EdUiOE

The instructions ara a little dated, but they can be followed. I generated the signing request using openssl
then got dogtag to sign it.

