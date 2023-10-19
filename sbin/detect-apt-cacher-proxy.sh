#!/bin/bash
#
# REF: https://help.ubuntu.com/community/Apt-Cacher%20NG
#
# detect-apt-cacher-proxy.sh - Returns a HTTP proxy which is available for use

# Author: Lekensteyn <lekensteyn@gmail.com>

# Supported since APT 0.7.25.3ubuntu1 (Lucid) and 0.7.26~exp1 (Debian Squeeze)
# Unsupported: Ubuntu Karmic and before, Debian Lenny and before

# Put this file in /etc/apt/detect-http-proxy and create and add the below
# configuration in /etc/apt/apt.conf.d/30detectproxy
#    Acquire::http::ProxyAutoDetect "/etc/apt/detect-http-proxy";

# APT calls this script for each host that should be connected to. Therefore
# you may see the proxy messages multiple times (LP 814130). If you find this
# annoying and wish to disable these messages, set show_proxy_messages to 0
show_proxy_messages=1

# on or more proxies can be specified. Note that each will introduce a routing
# delay and therefore its recommended to put the proxy which is most likely to
# be available on the top. If no proxy is available, a direct connection will
# be used

main() {
    local domain=".$(/usr/bin/hostname -d)"
    local try_proxies=(
        apt-cacher$domain:3142
        apt-cacher01$domain:3142
        apt-cacher02$domain:3142
        apt-cacher03$domain:3142
    )
    local dp_f="/etc/apt/apt.conf.d/30detectproxy"
    local profile_f="/etc/profile.d/detect-apt-cacher-proxy.sh"
    local github_f="https://raw.githubusercontent.com/jmedin1965/scripts/master/sbin/detect-apt-cacher-proxy.sh"
    local good_proxy="DIRECT"
    local nc="/usr/bin/nc"

    for proxy in "${try_proxies[@]}"
    do
        # if the host machine / proxy is reachable...
        print_msg "try ${proxy}"

        if ( [ -e "$nc" ] && "$nc" -z ${proxy/:/ } ) || /usr/bin/ping -c 1 -t 1 ${proxy%%:*}
	then
            proxy=http://$proxy
            print_msg "Found a good proxy: $proxy"
            good_proxy="$proxy"
            check_detectproxy
            break
        fi
    done
    print_msg "Using proxy: $good_proxy"

    echo "$good_proxy"
    if [ "$good_proxy" != DIRECT ]
    then
        export proxy_http="$good_proxy"
        export proxy_https="$good_proxy"
        export ALL_PROXY="$good_proxy"
        if [ ! -x "$nc" ]
        then
            print_msg "Attempt to install $nc"
            /usr/bin/apt install -y netcat-openbsd
        fi 
    fi
}

check_detectproxy()
{
    local p="$(/usr/bin/realpath "$0" )"

    if [ ! -h "$profile_f" -a "$p" != "$profile_f" ]
    then
        print_msg "install proxy detection into /etc/profile.d"
        /usr/bin/ln -fs "$p" "$profile_f"
    fi
    /usr/bin/chmod 755 "$profile_f"

    [ -e "$dp_f" ] && return

    print_msg "$dp_f: creating file to use auto-detected proxy"
        echo "# Fail immediately if a file could not be retrieved. Comment if you have a bad
# Internet connection
Acquire::Retries 0;
#
# # It should be an absolute path to the program, no arguments are allowed. stdout contains the proxy
# # server, stderr is shown (in stderr) but ignored by APT
Acquire::http::ProxyAutoDetect \"$profile_f\";
" > "$dp_f"

}

print_msg() {
    # \x0d clears the line so [Working] is hidden
    [ "$show_proxy_messages" = 1 ] && printf '\x0d%s\n' "$1" >&2
}

main "$@"
