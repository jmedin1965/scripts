#!/bin/bash

main()
{
    info "remove subscription apt repos"
    rm -f /etc/apt/sources.list.d/pmg-enterprise.list
    rm -f /etc/apt/sources.list.d/pve-enterprise.list
    info

    if [ ! -x /usr/bin/lsb_release ]
    then
        info "installing lsb-release"
        apt update
        apt -y install lsb-release
        info
    fi

    codename="$(set -- $(/usr/bin/lsb_release -c); echo $2)"
    manufacturere="$(/usr/sbin/dmidecode -s system-manufacturer)"

    info "This is to add all the stuff needed to build a new proxmox"
    info

    info "set locate"
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen 
    sed -i -e 's/# en_AU ISO-8859-1/en_AU ISO-8859-1/g' /etc/locale.gen 
    sed -i -e 's/# en_AU.UTF-8 UTF-8/en_AU.UTF-8 UTF-8/g' /etc/locale.gen 
    /usr/sbin/locale-gen
    /usr/sbin/update-locale LANG=en_AU.UTF-8
    info

    info "set timezone to Australia/Sydney"
    if [ -e /usr/share/zoneinfo/Australia/Sydney ]
    then
        ln -fs /usr/share/zoneinfo/Australia/Sydney /etc/localtime
        echo "Australia/Sydney" > /etc/timezone
        chmod 644 /etc/timezone
    fi

    if [ -e "/usr/share/perl5/PVE/Storage/CIFSPlugin.pm" ]
    then
        info "CIFS craps out so change the time out from 2 to 5 in"
        info "/usr/share/perl5/PVE/Storage/CIFSPlugin.pm "
        sed -i -e 's/timeout => 2/timeout => 5/g' /usr/share/perl5/PVE/Storage/CIFSPlugin.pm
        info
    fi

    if [ -e /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ]
    then
        info "remove the subscrion message"
        sed -i.bak \
            "s/data.status !== 'Active'/false/g" \
            /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && \
            systemctl restart pveproxy.service
    fi

    # set swappiness
    info "setting swappines to 10"
    sysctl vm.swappiness=10
    echo "vm.swappiness = 10" > /etc/sysctl.d/vm_swappiness.conf

    # Proxmox
    if [ -e /usr/bin/pveversion ]
    then
        echo "deb http://download.proxmox.com/debian/pve $codename pve-no-subscription" > \
            /etc/apt/sources.list.d/pve-install-repo.list
    fi

    # Proxmox Mail Gateway
    if [ -e /usr/bin/pmgversion ]
    then
        echo "deb http://download.proxmox.com/debian/pmg $codename pmg-no-subscription" > \
            /etc/apt/sources.list.d/pgm-install-repo.list
    fi

    info "update and upgrade apt"
    apt update
    apt -y upgrade

    info "manufacturere=$manufacturere, check if we are a virtual machine, install agent if we are."
    [ "$manufacturere" == QEMU ] && apt install qemu-guest-agent

    extra_packages="vim tmux htop iotop ifupdown2 ethtool liblz4-tool sysstat"
    info "Install extra packages: $extra_packages"
    apt install -y $extra_packages

    info fix the mouse feature annoyance in vim
    echo > ~/.vimrc
    echo 'set mouse-=a' >> ~/.vimrc
    echo 'au BufReadPost * if line("\'\"") > 1 && line("'\"") <= line("$") | exe "normal! g\`\"" | endif' >> ~/.vimrc
    echo "set undodir=~/.vim/undodir" >> ~/.vimrc
    echo "set undofile" >> ~/.vimrc
    echo "set ai" >> ~/.vimrc
    echo "set ic" >> ~/.vimrc
    echo "syntax on" >> ~/.vimrc
    mkdir -p ~/.vim/undodir

    info "add ll alias and uncomment LS_OPTIONS and eval"
    sed -i -e 's/# export LS_OPTIONS/export LS_OPTIONS/g' ~/.bashrc
    sed -i -e 's/# eval/eval/g' ~/.bashrc
    sed -i -e 's/# alias ll/alias ll/g' ~/.bashrc

    # Proxmox
    if [ -e /usr/bin/pveversion ]
    then
        info updating lxd templates - pveam update
        pveam update

        info checking nested virtualisation
        # REF https://forum.proxmox.com/threads/nested-virtualization.25996/
        # REF https://pve.proxmox.com/wiki/Nested_Virtualization
        echo "options kvm-amd nested=1" > /etc/modprobe.d/kvm-amd.conf
        echo "options kvm-intel nested=Y" >> /etc/modprobe.d/kvm-intel.conf
        if [ "$(/usr/bin/fgrep -e Y -e 1 -c /sys/module/kvm_intel/parameters/nested)" -gt 0 ]
        then
	        info "  nested virtualisation is already on"
        else
	        if [ "$(/usr/sbin/lsmod | /usr/bin/fgrep -c kvm_intel)" -gt 0 ]
	        then
		        info "  we have an intel CPU"
    		    modprobe -r kvm_intel
	    	    modprobe kvm_intel
	        fi
    	    if [ "$(/usr/sbin/lsmod | /usr/bin/fgrep -c kvm_amd)" -gt 0 ]
	        then
		        info "  we have an amd CPU"
		        modprobe -r kvm_amd
    		    modprobe kvm_amd
	        fi
        fi
    fi

    #
    # REF: https://backports.debian.org/Instructions/
    #
    info "adding debian backports for $codename"
    echo "deb http://deb.debian.org/debian ${codename}-backports main" > /etc/apt/sources.list.d/backports.list
    info "installing monit from backports"
    apt update
    apt -t ${codename}-backports install monit

    #echo dist-upgrade
    #apt dist-upgrade -y
}

log()
{
	local date="$(/bin/date +%d'-'%m'-'%y' '%H':'%M':'%S)" 
	echo "${date}:" "$@"
}

info()
{
	log "INFO:" "$@"
}

warning()
{
	log "WARNING:" "$@"
}

error()
{
	log "ERROR:" "$@"
}

main "$@"

