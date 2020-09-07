
# Dogtag - internal off-line CA

I tried to install this using debian, but just too difficult. No point re-inventing the wheel, so I'm
installing on a CentOS 8 system with 8G disk space and an encrypted root disk.

I did find an excelent doc on how to install an off-line CA on centOS, but it's for centOS 7. I will follow
it and see if it works with centOS 8;

REF https://github.com/rharmonson/richtech/wiki/OSVDC-Series:-Root-Certificate-Authority-(PKI)-with-Dogtag-10.3-on-CentOS-7.3.1611

## install apache and php - NOT REQUIRED!

centOS 8 uses tomcat. If these are installed, dogtag instalation fails

## Configure firewall

CentOS 8 used firewall-cmd

    firewall-cmd --permanent --zone=public --add-port=8443/tcp
    firewall-cmd --permanent --zone=public --remove-service=cockpit

    firewall-cmd --reload 
    firewall-cmd --list-all

## Entropy

make sure quemu-guest-client is installed. Also add VirtIO RNG to the guest hardware

    yum install qemu-guest-agent

Make sure you have the VirtIO RING added to vm's hardware and reboot

## selinux

need to set selinux to permissive to do the install, or probably not? I'm thinking that CentOS8 will
hopefullt set selinux up properly. yes they did.

    # no need for this
    #sudo setenforce 0
    #sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

## hosts file

make sure hosts ip address in in /etc/hosts file

    <ip address> <hostname.domain> <hostname>

## 389-ds-base pki-ca

REF: https://www.techsupportpk.com/2020/04/how-to-set-up-389-directory-server-centos-rhel-8.html

    yum -y install @idm:DL1
    yum -y install 389-ds-base pki-ca

unistall cockpit if you don't want to use it

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

if it fails and you need to remove, use
    pkidestroy -s CA

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

