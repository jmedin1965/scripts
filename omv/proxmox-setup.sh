#!/bin/bash

proxmox_packages="tmux htop iotop nload bmon ifupdown2 ethtool liblz4-tool sysstat"
proxmox_gateway_pachages="ifupdown2 ethtool"
extra_packages="vim ethtool"

main()
{
    local EV="0"

    if [ $# != 0 ]
    then
        while [ $# != 0 ]
        do
            case "$1" in
                monit)
                    ISTTY="MONIT"
                    ;;
                daily)
                    removeSubscriptionMessage
                    ;;
                rc-local)
                    install_rc_local
                    ;;
                subscription)
                    removeSubscriptionMessage
                    EV="$?"
                    ;;
                *)
                    echo "$(/usr/bin/basename "$0"): unrecognized option \"$1\"" > /dev/stderr
                    echo "Options:" > /dev/stderr
                    echo "  daily        - do daily tasks only" > /dev/stderr
                    echo "  rc-local     - install rc-local scripts" > /dev/stderr
                    echo "  subscription - check and remove subscription message" > /dev/stderr
                    echo "  monit - use MONIT format for info messages" > /dev/stderr
                    exit 1
                    ;;
            esac
            shift
        done
        exit "$EV"
    fi

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

    info "please enjoy 5 seconds to think about things."
    sleep 5
    echo

    #
    # Looks like after upgrading to debian 11 the console resolution is too high for
    # my screen
    #
    # REF: https://unix.stackexchange.com/questions/17027/how-to-set-the-resolution-in-text-consoles-troubleshoot-when-any-vga-fail
    if [ "$manufacturere" == "Cisco Systems Inc" ]
    then
        info "set console resolution to 640x480"
        changed="false"
        for exp in GRUB_GFXMODE=640x480 GRUB_GFXPAYLOAD_LINUX=keep
        do
            if /usr/bin/grep -q "^${exp}$" /etc/default/grub
            then
                info "\"$exp\" already set"

            elif /usr/bin/grep -q "^${exp%=*}=" /etc/default/grub
            then
                changed="true"
                info "\"${exp%=*}=\" exists, but with wrong value, fixing"
                /usr/bin/sed -i -e "s/^${exp%=*}=.*/$exp/g" /etc/default/grub
            else
                changed="true"
                info "\"$exp\" does not exist, adding"
                echo "$exp" >> /etc/default/grub
            fi
        done
        if [ "$changed" != "false" ]
        then
            info "grub config changed, restarting grub"
            echo "FRAMEBUFFER=y" | /usr/bin/tee /etc/initramfs-tools/conf.d/splash
            /usr/sbin/update-initramfs -u
            /usr/sbin/update-grub
        fi
    fi

    # fix locale
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

    # Virtual machine, need to add others like vmware
    info "manufacturere=$manufacturere, check if we are a virtual machine, install agent if we are."
    if [ "$manufacturere" == QEMU ]
	then
        info "install qemu-guest-agent qemu-utils"
		if [ "$ID" == debian ]
		then
 			apt install -y qemu-guest-agent
    		echo
        elif [ "$ID" == centos ]
        then
            yum install -y qemu-guest-agent
		fi
	fi

    # extra packages based on OS
    info "Install extra packages based on os: $ID: $extra_packages"
	if [ "$ID" == debian ]
	then
    	apt install -y $extra_packages
    elif [ "$ID" == centos ]
    then
    	yum install -y $extra_packages
	fi
	if [ "$ID" == debian -o "$ID" == ubuntu ]
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
        apt install -y $proxmox_gateway_pachages
    fi

    # Proxmox
    if [ -e /usr/bin/pveversion ]
    then
        # REF: https://forum.proxmox.com/threads/how-to-stop-warnings-kvm-vcpu0-ignored-rdmsr.28552/
        info "set ignored rdmsr and ignored wrmsr to remove syslog warnings"
        echo "options kvm report_ignored_msrs=0" > /etc/modprobe.d/kvm.conf

        info updating lxd templates - pveam update
        pveam update
        echo

        apt install -y $proxmox_packages

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

        info limit zfs memory limit
        mem="$( set -- $(/usr/bin/free --giga | /usr/bin/fgrep Mem:); echo $2 )"
        limit_g="8"
        if [ "$mem" -gt 31 ]
        then
            limit_g="16"
        elif [ "$mem" -gt 15 ]
        then
            info limit zfs memory limit
            limit_g="8"
        fi
        info "  limit set to ${limit_g}G"
        limit=$(( limit_g * 1024 * 1024 * 1024 ))
        info "  limit set to ${limit}"
        cat > /etc/modprobe.d/zfs.conf <<-END
			#
			# REF: https://pve.proxmox.com/wiki/ZFS_on_Linux#_limit_zfs_memory_usage
			#
			# expr $limit_g \* 1024 \* 1024 \* 1024
			options zfs zfs_arc_max=$limit
			END
        /usr/sbin/update-initramfs -u
        echo
    fi

    ## add monit from backports
    ##
    ## REF: https://backports.debian.org/Instructions/
    ##
	#if [ "$ID" == debian ]
	#then
    #	info "adding debian backports for $codename"
    #	echo "deb http://deb.debian.org/debian ${codename}-backports main" > /etc/apt/sources.list.d/backports.list
    #	info "installing monit from backports"
    #	apt update
    #	apt -t ${codename}-backports install monit
    #	echo
	#fi
    # No need as Monit is now in stardart source

    #echo dist-upgrade
    #apt dist-upgrade -y

    removeSubscriptionMessage
}

install_rc_local()
{
    if [ ! -e /etc/systemd/system/rc-local.service ]
    then
        cp /usr/local/scripts/etc/systemd/system/rc-local.service /etc/systemd/system/rc-local.service

    fi

    if [ ! -e /etc/rc.local ]
    then
        cp /usr/local/scripts/etc/rc.local /etc/rc.local
        chmod +x /etc/rc.local
        systemctl enable rc-local
    fi
    
    if [ ! -e /etc/logrotate.d/rc.local ]
    then
        cp /usr/local/scripts/etc/logrotate.d/rc.local /etc/logrotate.d/rc.local
    fi

    if [ ! -d /etc/rc.local.d ]
    then
        mkdir /etc/rc.local.d
    fi
}

#
# Remove subscription message
#
removeSubscriptionMessage()
{
    local EV="0"

    #local ok_str="const subscription = false;"
    local ok_str="void({ //"

    if [ -e /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ]
    then
        info "check proxmox subscrion message..."

        if [ "$(grep -c "$ok_str" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js)" -gt 0 ]
        then
            info "  subscrion message already removed."
        else
            info "  subscrion message exists, will try to remove..."
            #sed -i.bak -z "s/${err_str}/${ok_str}/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

            sed -Ezi.bak "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

            EV="1"

            if [ "$(grep -c "$ok_str" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js)" -gt 0 ]
            then
                info "  subscrion message removed, restarting GUI..."
                systemctl restart pveproxy.service
            else
                info "  failed to remove subscrion message!"
            fi
        fi
    fi

    return "$EV"
}

ISTTY="$(/usr/bin/tty -s && echo TRUE)"
log()
{
    if [ "$ISTTY" == "MONIT" ]
    then
	    echo "$@"
    else
	    local date="$(/bin/date +%d'-'%m'-'%y' '%H':'%M':'%S)" 
	    echo "${date}:" "$@"
    fi
}

info()
{
	[ "$ISTTY" == "TRUE" -o "$ISTTY" == "MONIT" ] && log "INFO:" "$@"
}

monit()
{
	echo "INFO:" "$@"
}

warning()
{
	log "WARNING:" "$@"
}

error()
{
	log "ERROR:" "$@" > /dev/stderr
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

