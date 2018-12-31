#!/bin/bash
# Linux VM Customization script. Currently supports Centos/Ubuntu

# -----------------------------------------
# GLOBAL VARS
# -----------------------------------------

RED='\e[1;31m%s\e[0m\n'
GREEN='\e[1;32m%s\e[0m\n'

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
    if [ -f /etc/oracle-release ]; then 
        echo 'oracle'        
    elif [ -f /etc/redhat-release ]; then
        echo 'redhat'
    elif [ -f /etc/SuSE-release ]; then 
        echo 'suse'    
    else
       run sed 's/"//g' <<<cat /etc/os-release | grep -E ^ID= | sed -n 1'p' | rev | cut -d= -f1 | rev
    fi    
}

# -----------------------------------------
# NEW UTILS
# -----------------------------------------

function restart_network() {
    # restarts the network service
    
    if [[ ($(get_os_id) == "centos") || ($(get_os_id) == "redhat") || ($(get_os_id) == "oracle") ]] ; then
        run /etc/init.d/network restart &
    elif [[ ($(get_os_id) == "ubuntu") || ($(get_os_id) == "suse") ]] ; then
        run /etc/init.d/networking restart &
	#run sudo ifconfig $(get_active_network_device) down && ifconfig $(get_active_network_device) up &
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


function set_static_ip_address() {
    # sets the network configuration for static IP    
    # Centos: https://www.centos.org/docs/5/html/Deployment_Guide-en-US/s1-networkscripts-interfaces.html
    # Ubuntu: https://www.howtoforge.com/linux-basics-set-a-static-ip-on-ubuntu
    
    log "Setting Static IP address: IP=$2, DNS1=$3, DNS2=$4, NETMASK=$5, GATEWAY=$6"
    
    if [[ ($(get_os_id) == "centos") || ($(get_os_id) == "redhat") || ($(get_os_id) == "oracle") ]] ; then
        network_config="/etc/sysconfig/network-scripts/ifcfg-$1"
        log "Rewriting network config to set static IP: $network_config"
        cat > $network_config << EOF
DEVICE=$1
BOOTPROTO=static
ONBOOT=yes
IPADDR=$2
NETMASK=$5
GATEWAY=$6
DNS1=$3
DNS2=$4

PEERDNS=yes
EOF

    elif [[ ($(get_os_id) == "suse") || ($(get_os_id) == "opensuse-tumbleweed") ]] ; then
        network_config="/etc/sysconfig/network/ifcfg-$1"
        log "Rewriting network config to set static IP: $network_config"
        cat > $network_config << EOF
BOOTPROTO='static'
STARTMODE='auto'
BROADCAST=''
ETHTOOL_OPTIONS=''
IPADDR='$2'
MTU='1500'
NAME=''
NETMASK='$5'
REMOTE_IPADDR=''
ZONE=public
USERCONTROL='no'
EOF
   
    elif [[ ($(get_os_id) == "ubuntu") || ($(get_os_id) == "debian") ]] ; then
        network_config="/etc/network/interfaces"
        log "Rewriting network config to set static IP: $network_config"
        cat > $network_config << EOF
auto lo
iface lo inet loopback
auto $1
iface $1 inet static
address $2
gateway $6
netmask $5
dns-nameservers $3 $4
EOF

    fi
    
    restart_network	
}

# -----------------------------------------
# MAIN
# -----------------------------------------

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

log "Input Params: NAME=$NAME, DOMAIN=$DOMAIN, DNS1=$DNS1, DNS2=$DNS2, IPADDR=$IP_ADDRESS, NETMASK=$NETMASK, GATEWAY=$GATEWAY"

# Required minimum parameters
if [ -z "$NAME" ] || [ -z "$DOMAIN" ]
then
    log_error "NAME or DOMAIN not defined!"
fi

set_fqdn $NAME $DOMAIN

# if all parameters are specified, set static IP, else set DHCP
if [ ! -z "$IP_ADDRESS" ] || [ ! -z "$DNS1" ] || [ ! -z "$DNS2" ] || [ ! -z "$NETMASK" ] || [ ! -z "$GATEWAY" ]
then    
    set_static_ip_address $(get_active_network_device) $IP_ADDRESS $DNS1 $DNS2 $NETMASK $GATEWAY   
    log "Rebooting system..."
    sudo reboot &
else
    log "DHCP: Don't do anything!"
fi

exit 0
