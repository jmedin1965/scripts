
# Ipfire firewall and router

## my local packages

How do I inject my own package into ipfire so I can install and remove it easily?
I'm going to generate a pgp key, then create a package file and then enable this key to be recognised.
The package still needs to be coped manualy though. I'm thinking a pakfire-local wrapper for pakfire

### generate gpg key

REF: https://www.golinuxcloud.com/tutorial-encrypt-decrypt-sign-file-gpg-key-linux/

set the GPG home folder
    export GNUPGHOME=/opt/pakfire/etc/.gnupg

generate the key
    gpg --gen-key

export key and secure key to store in a safe place
    gpg --list-keys
    gpg --export --armor --output public.asc <fingerprint frim --list-keys above>
    gpg gpg --export-secret-keys --armor --output secret.asc <fingerprint frim --list-keys above>

now we can sign a tar file package. have to use -r option to work with ipfire. This creates a .gpg file
    gpg -R --encrypt --sign -r "key name or fingerprint" <package file>

then we can veryfy the .gpg file just like pakfire does and we can read the fingerprint, just after the
VALIDSIG statement
    gpg --verify --status-fd 1 <package file>

### now to hack a wrapper for pakfile


    
    

## to do

### ipfire /var/ipfire/failover/vrrp.notify.sh permissions

keepalived complains about elevated rights for this script. Need to give it rights to create;

/var/ipfire/red/active
/var/run/keepalived.state

as the web user, which is nobody

