#!/bin/bash
# Linux VM Customization script. Currently supports Centos/Ubuntu

# -----------------------------------------
# GLOBAL VARS
# -----------------------------------------

RED='\e[1;31m%s\e[0m\n'
GREEN='\e[1;32m%s\e[0m\n'

NETMASK="255.255.255.0"

# -----------------------------------------
# LOGGING
# -----------------------------------------

function log() {
    printf "$GREEN" "$( date '+[%F_%T]' ) ${HOSTNAME}: ${LOG_PREFIX}: $@"
}

function log_error() {
    printf "$RED" "$( date '+[%F_%T]' ) ${HOSTNAME}: ${LOG_PREFIX}: ERROR: $@"
    exit 1
}

function to_log() {
    while read LINE; do
        log "${LINE}"
    done
}

function run() { 
    "$@";
    RETURN_CODE=${PIPESTATUS[0]}
    if [[ $RETURN_CODE -ne 0 ]]; then
        log_error "FAILED with RETURN_CODE=${RETURN_CODE}"
        exit ${RETURN_CODE}
    fi
    return ${RETURN_CODE}
}


function get_os_id() {
    # gets the OS id - centos/ubuntu/debian
    
    run sed 's/"//g' <<<cat /etc/os-release | grep -E ^ID= | sed -n 1'p' | rev | cut -d= -f1 | rev
}

# -----------------------------------------
# NEW UTILS
# -----------------------------------------

function restart_network() {
    # restarts the network service
    
    if [ $(get_os_id) == "centos" ] ; then
        run /etc/init.d/network restart
    elif [ $(get_os_id) == "ubuntu" ]; then
        run /etc/init.d/networking restart
    fi    
}

function set_fqdn() {
    # sets the FQDN of machine

	FQDN="$1.$2"
	log "Setting Fully Qualified Domain Name (FQDN): $FQDN"

	if [ $(get_os_id) == "centos" ] ; then
		# REFERENCE: https://support.rackspace.com/how-to/centos-hostname-change/		
		cat > /etc/sysconfig/network << EOF
NEWORKING=yes
HOSTNAME=$FQDN
EOF
    fi
        
	cat > /etc/hosts << EOF
127.0.0.1   localhost
127.0.1.1   $FQDN $1
EOF
	
	run hostname "$FQDN"		
	run echo "$FQDN" > /etc/hostname
	restart_network

	FOUND_HOSTNAME=$(run hostname)
	if [ "$FQDN" != "$FOUND_HOSTNAME" ] ; then
		log_error "Unable to set FQDN. Trying to Set: $FQDN, Found:$FOUND_HOSTNAME"
	fi
	
}


function get_active_network_device() {
	# gives the available active network device
    
	run ip addr show | awk '/inet.*brd/{print $NF}'
}


function set_dynamic_ip_address() {
    # sets basic DHCP network settings for the active interface
    
    if [ $(get_os_id) == "centos" ] ; then
        network_config="/etc/sysconfig/network-scripts/ifcfg-$1"
        log "Rewriting network config to set DHCP: $network_config"
        cat > $network_config << EOF
DEVICE=$1
BOOTPROTO=dhcp
ONBOOT=yes
EOF
    
    elif [ $(get_os_id) == "ubuntu" ] ; then
        network_config="/etc/network/interfaces"
        log "Rewriting network config to set DHCP: $network_config"
        cat > $network_config << EOF
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet dhcp
EOF

    fi
    
	restart_network
}


function get_gateway_address() {
    # calculates the gateway address based on the IP address
    
    replace_with="252"
    for x in $(IFS='.';echo $1); do replace=$x; done
    echo ${1/$replace/$replace_with}
}


function set_static_ip_address() {
    # sets the network configuration for static IP    
    # Centos: https://www.centos.org/docs/5/html/Deployment_Guide-en-US/s1-networkscripts-interfaces.html
    # Ubuntu: https://www.howtoforge.com/linux-basics-set-a-static-ip-on-ubuntu
    
	gateway=$(get_gateway_address $2)
    log "Setting Static IP address: IP=$2, DNS1=$3, DNS2=$4, NETMASK=$NETMASK, GATEWAY=$gateway"
    
    if [ $(get_os_id) == "centos" ] ; then
        network_config="/etc/sysconfig/network-scripts/ifcfg-$1"
        log "Rewriting network config to set static IP: $network_config"
        cat > $network_config << EOF
DEVICE=$1
BOOTPROTO=static
ONBOOT=yes
IPADDR=$2
NETMASK=$NETMASK
GATEWAY=$gateway
DNS1=$3
DNS2=$4
PEERDNS=yes
EOF

    elif [ $(get_os_id) == "ubuntu" ] ; then
        network_config="/etc/network/interfaces"
        log "Rewriting network config to set static IP: $network_config"
        cat > $network_config << EOF
auto lo
iface lo inet loopback
auto eth0
iface eth0 inet static
address $2
gateway $gateway
netmask $NETMASK
dns-nameservers $3 $4
EOF

    fi
    
    restart_network	
}


# -----------------------------------------
# MAIN
# -----------------------------------------

if [ "$EUID" -ne 0 ]
  then echo "This script must be run as root. Exiting."
  exit
fi

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    --dns1)
    DNS1="$2"
    shift # past argument
    shift # past value
    ;;
    --dns2)
    DNS2="$2"
    shift # past argument
    shift # past value
    ;;
    --domain)
    DOMAIN="$2"
    shift # past argument
    shift # past value
    ;;
    --hostname)
    NAME="$2"
    shift # past argument
    shift # past value
    ;;
    --ip_address)
    IP_ADDRESS="$2"
    shift # past argument
    shift # past value
    ;;
    *)    # unknown option
    log_error "Unknown Command Line Parameter: $1"
    ;;
esac
done

log "Input Params: $NAME, $DOMAIN, $DNS1, $DNS2, $IP_ADDRESS"

# Required minimum parameters
if [ -z "$NAME" ] || [ -z "$DOMAIN" ]
then
    log_error "NAME or DOMAIN not defined!"
fi

set_fqdn $NAME $DOMAIN

# if IP address and DNS servers specified, set static IP, else set DHCP
if [ ! -z "$IP_ADDRESS" ] || [ ! -z "$DNS1" ] || [ ! -z "$DNS2" ]
then    
    set_static_ip_address $(get_active_network_device) $IP_ADDRESS $DNS1 $DNS2
else
    set_dynamic_ip_address $(get_active_network_device)
fi

log "Done with VM customization"