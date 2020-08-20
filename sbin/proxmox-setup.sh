#!/bin/bash

main()
{
    info "remove subscription apt repos"
    rm -f /etc/apt/sources.list.d/pmg-enterprise.list
    rm -f /etc/apt/sources.list.d/pve-enterprise.list
    echo

    [ -e /etc/os-release ] && . /etc/os-release

    codename="$VERSION_CODENAME"
    manufacturere="$(/usr/sbin/dmidecode -s system-manufacturer)"
    info "System codename = $codename"
    info "System manufacturere = $manufacturere"
    echo

    if [ -e /etc/locale.gen ]
    then
        info "set locate"
        sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g' /etc/locale.gen 
        sed -i -e 's/# en_AU ISO-8859-1/en_AU ISO-8859-1/g' /etc/locale.gen 
        sed -i -e 's/# en_AU.UTF-8 UTF-8/en_AU.UTF-8 UTF-8/g' /etc/locale.gen 
        /usr/sbin/locale-gen
        /usr/sbin/update-locale LANG=en_AU.UTF-8
        echo
    fi

    info "set timezone to Australia/Sydney"
    if [ -e /usr/share/zoneinfo/Australia/Sydney ]
    then
        ln -fs /usr/share/zoneinfo/Australia/Sydney /etc/localtime
        if [ -e /etc/timezone ]
        then
            echo "Australia/Sydney" > /etc/timezone
            chmod 644 /etc/timezone
        fi
    fi
    echo

    if [ -e "/usr/share/perl5/PVE/Storage/CIFSPlugin.pm" ]
    then
        info "CIFS craps out so change the time out from 2 to 5 in"
        info "/usr/share/perl5/PVE/Storage/CIFSPlugin.pm "
        sed -i -e 's/timeout => 2/timeout => 5/g' /usr/share/perl5/PVE/Storage/CIFSPlugin.pm
        echo
    fi

    if [ -e /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ]
    then
        if [ "$(fgrep -c "data.status !== 'Active'" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js)" == 0 ]
        then
            info "subscrion message already removed"
        else
            info "remove the subscrion message"
            sed -i.bak \
                "s/data.status !== 'Active'/false/g" \
                /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && \
                systemctl restart pveproxy.service
        fi
        echo
    fi

    # set swappiness
    swappiness="$(</proc/sys/vm/swappiness)"
    info "setting swappines from $swappiness to 30"
    sysctl vm.swappiness=30
    echo "vm.swappiness = 30" > /etc/sysctl.d/vm_swappiness.conf

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

	if [ "$ID" == debian ]
	then
    	info "apt update and upgrade"
    	apt update
    	apt -y upgrade
    	echo
    elif [ "$ID" == centos ]
    then
    	info "yum update"
        yum -y update
	fi

    info "manufacturere=$manufacturere, check if we are a virtual machine, install agent if we are."
    if [ "$manufacturere" == QEMU ]
	then
        info "install qemu-guest-agent"
		if [ "$ID" == debian ]
		then
 			apt install -y qemu-guest-agent
    		echo
        elif [ "$ID" == centos ]
        then
            yum install -y qemu-guest-agent
		fi
	fi

    extra_packages="vim ethtool"
    info "Install extra packages: $extra_packages"
	if [ "$ID" == debian ]
	then
    	apt install -y $extra_packages
    elif [ "$ID" == centos ]
    then
    	yum install -y $extra_packages
	fi
    echo

    info fix the mouse feature annoyance in vim
	mkdir -p /etc/vim
	vimrc > /etc/vim/vimrc.local 

    info "add ll alias and uncomment LS_OPTIONS and eval"
    sed -i -e 's/# export LS_OPTIONS/export LS_OPTIONS/g' ~/.bashrc
    sed -i -e 's/# eval/eval/g' ~/.bashrc
    sed -i -e 's/# alias ll/alias ll/g' ~/.bashrc

    # Proxmox Mail Gateway
    if [ -e /usr/bin/pmgversion ]
    then
        apt install -y ifupdown2 ethtool
    fi

    # Proxmox
    if [ -e /usr/bin/pveversion ]
    then
        info updating lxd templates - pveam update
        pveam update
        echo

        apt install -y tmux htop iotop ifupdown2 ethtool liblz4-tool sysstat

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
        echo
    fi

    #
    # REF: https://backports.debian.org/Instructions/
    #
	if [ "$ID" == debian ]
	then
    	info "adding debian backports for $codename"
    	echo "deb http://deb.debian.org/debian ${codename}-backports main" > /etc/apt/sources.list.d/backports.list
    	info "installing monit from backports"
    	apt update
    	apt -t ${codename}-backports install monit
    	echo
	fi

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

vimrc()
{
    mkdir -p ~/.vim/undodir
    touch /root/.vimrc
    cat <<-END
	" Uncomment the next line to make Vim more Vi-compatible
	" NOTE: debian.vim sets 'nocompatible'.  Setting 'compatible' changes numerous
	" options, so any other options should be set AFTER setting 'compatible'.
	"set compatible

	" Vim5 and later versions support syntax highlighting. Uncommenting the next
	" line enables syntax highlighting by default.
	if has("syntax")
	  syntax on
	endif

	" If using a dark background within the editing area and syntax highlighting
	" turn on this option as well
	set background=dark

	" Uncomment the following to have Vim jump to the last position when
	" reopening a file
	if has("autocmd")
	  au BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
	endif

	" Uncomment the following to have Vim load indentation rules and plugins
	" according to the detected filetype.
	if has("autocmd")
	  filetype plugin indent on
	endif

	" The following are commented out as they cause vim to behave a lot
	" differently from regular Vi. They are highly recommended though.
	"set showcmd        " Show (partial) command in status line.
	"set showmatch      " Show matching brackets.
	"set ignorecase     " Do case insensitive matching
	"set smartcase      " Do smart case matching
	"set incsearch      " Incremental search
	"set autowrite      " Automatically save before commands like :next and :make
	"set hidden         " Hide buffers when they are abandoned
	"set mouse=a        " Enable mouse usage (all modes)

	autocmd Filetype * setlocal tabstop=4 shiftwidth=4 softtabstop=4 expandtab

	" Greg vim fixes TM
	set mouse-=a
	au BufReadPost * if line("\") > 1 && line(\"") <= line("$") | exe "normal! g\\\`\"" | endif
	set undodir=~/.vim/undodir
	set undofile
	set ai
	set ic
	syntax on

END
}

main "$@"

