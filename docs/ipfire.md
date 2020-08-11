
# Ipfire firewall and router

## ipfire /var/ipfire/failover/vrrp.notify.sh permissions

keepalived complains about elevated rights for this script. Need to give it rights to create;

/var/ipfire/red/active
/var/run/keepalived.state

as the web user, which is nobody

