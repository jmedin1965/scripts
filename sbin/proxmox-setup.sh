#!/bin/bash

proxmox_packages="tmux htop iotop nload bmon ifupdown2 ethtool liblz4-tool sysstat command-not-found csync2"
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
                monit) # use MONIT format for info messages
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
                    (
                      echo "$(/usr/bin/basename "$0"): unrecognized option \"$1\""
                      echo "Options:"
                      echo "  daily        - do daily tasks only"
                      echo "  rc-local     - install rc-local scripts"
                      echo "  subscription - check and remove subscription message"
                      echo "  monit - use MONIT format for info messages"
                    ) > /dev/stderr
                    exit 1
                    ;;
            esac
            shift
        done
    else
        do_all
        EV="$?"
    fi

    exit "$EV"
}

do_all()
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

    info "Install extra packages: $extra_packages"
	if [ "$ID" == debian ]
	then
    	apt install -y $extra_packages
    elif [ "$ID" == centos ]
    then
    	yum install -y $extra_packages
	fi
    echo

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
        /sbin/update-command-not-found

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

        # PCI PassThrough
        #
        # REF: https://pve.proxmox.com/wiki/PCI(e)_Passthrough
        echo "
vfio
vfio_iommu_type1
vfio_pci
vfio_virqfd
" > /etc/modules-load.d/iommu.conf

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

    removeSubscriptionMessage
    install_rc_local
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

    [ ! -d /etc/rc.local.d ] && mkdir /etc/rc.local.d
}

#
# Remove subscription message
#
# This has changed again
# REF: https://johnscs.com/remove-proxmox51-subscription-notice/
#
removeSubscriptionMessage()
{
    if [ -e /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ]
    then
        info "check and fix subscription message."
        if dpkg -V proxmox-widget-toolkit | grep -q '/proxmoxlib\.js$'
        then
            info "/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js: file is changed, fixing not needed."
        else
            info "/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js: file needs fixing."
            sed -Ezi.bak \
                "s/(Ext.Msg.show\(\{\s+title: gettext\('No valid sub)/void\(\{ \/\/\1/g" \
                /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js && \
                systemctl restart pveproxy.service
            /bin/true
        fi
    fi

    if [ ! -e /etc/apt/apt.conf.d/99no-nag-script.conf ]
    then
        info "Installing 99no-nag-script.conf as a DPkg::Post-Invoke script"
        echo "DPkg::Post-Invoke { \"$0 subscription\"; };" > /etc/apt/apt.conf.d/99no-nag-script.conf
    fi
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

main "$@"

