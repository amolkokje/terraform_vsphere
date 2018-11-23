#!/bin/bash

# -----------------------------------------
# GLOBAL VARS
# -----------------------------------------

RED='\e[1;31m%s\e[0m\n'
GREEN='\e[1;32m%s\e[0m\n'

ADMIN_USER="admin"
ADMIN_PASSWORD="admin"

# -----------------------------------------
# LOGGING
# -----------------------------------------

function log() {
    printf "$GREEN" "$( date '+[%F_%T]' ) ${HOSTNAME}: ${LOG_PREFIX}: $@"
}

function log_error() {
    printf "$RED" "$( date '+[%F_%T]' ) ${HOSTNAME}: ${LOG_PREFIX}: ERROR: $@"
}

function to_log() {
    while read LINE; do
        log "${LINE}"
    done
}

function run() { 
    "$@";
    if [[ $? -ne 0 ]]; then
        log_error "FAILED with RETURN_CODE=${RETURN_CODE}"
        exit ${RETURN_CODE}
    fi
    return ${RETURN_CODE}
}


# -----------------------------------------
# CHECKERS
# -----------------------------------------

is_32bit() {
    run uname -m | grep -qv 'x86_64' > /dev/null 2>&1
    return
}

is_64bit() {
    run uname -m | grep -q 'x86_64' > /dev/null 2>&1
    return
}

is_debian() {
    run grep -q 'ID=debian' /etc/os-release > /dev/null 2>&1
    return
}

is_redhat() { # Includes CentOS
    [ -f /etc/redhat-release ]
    return
}

is_suse() {
    [ -f /etc/SuSE-release ] || grep -q 'ID_LIKE="suse"' /etc/os-release > /dev/null 2>&1
    return
}

is_ubuntu() {
    run grep -q 'ID=ubuntu' /etc/os-release > /dev/null 2>&1
    return
}


# -----------------------------------------
# UTILS
# -----------------------------------------

set_hostname_domain() {
    log "Setting Hostname: $1 Domain: $2"
    if is_redhat ; then
cat << EOF > /etc/sysconfig/network
NETWORKING=yes
HOSTNAME=$1
EOF
    elif is_suse ; then
        run echo "$1" > /etc/HOSTNAME
        run sed -i 's/DHCLIENT_SET_HOSTNAME=/c\DHCLIENT_SET_HOSTNAME="no"/' /etc/sysconfig/network/dhcp
    fi

    if [ -f /etc/cloud/cloud.cfg ]; then
        run sed -i 's/preserve_hostname.*/preserve_hostname: true/' /etc/cloud/cloud.cfg
    fi

    run echo "$1" > /etc/hostname

cat << EOF > /etc/hosts
127.0.0.1   localhost
127.0.1.1   $1.$2 $1
EOF
}


# -----------------------------------------
# UTILS - USERS
# -----------------------------------------

configure_ssh() {
    log "Installing SSH server, enabling root SSH login"
    if [ -x "$(which apt-get > /dev/null 2>&1)" ]; then
        run apt-get install openssh-server -y
    fi
    run sed -i "/#\?PermitRootLogin/c\PermitRootLogin yes" /etc/ssh/sshd_config
}


create_admin_user() {
    log "Creating admin user. User:$1"
    if is_suse ; then
        run useradd -m "$1"
    elif is_debian || is_ubuntu ; then
	run adduser -q --disabled-password --gecos User "$1"
    else
        run adduser "$1"
    fi

    run grep -q "$1  ALL=(ALL:ALL) ALL" /etc/sudoers || echo "$1  ALL=(ALL:ALL) ALL" >> /etc/sudoers
}


set_user_password() {
    log "Set user password. User:$1, Password:$2"
    run echo -e "$2\n$2" | passwd "$1"
}


# -----------------------------------------
# UTILS - NETWORKING
# -----------------------------------------

enable_networking() {
    log "Configuring network: Domain: $1 DNS1: $2 DNS2: $3"
cat <<- EOF > /etc/resolv.conf
domain $1
search $1
nameserver $2
nameserver $3
EOF

    if is_redhat ; then
        interfaces=($(ls /sys/class/net/ | grep -v lo))
        for f in "${interfaces[@]}"; do
cat <<- EOF > /etc/sysconfig/network-scripts/ifcfg-$f
DEVICE=$f
BOOTPROTO=dhcp
ONBOOT=yes
EOF
        done
        run service network restart
    fi
    if is_suse ; then
        #TODO: Find way to get ID dynamically
        run yast2 lan edit id=0 bootproto=dhcp
    fi
}


# -----------------------------------------
# UTILS - FIREWALL
# -----------------------------------------

open_firewall_ssh() {
    log "Opening firewall for SSH"
    if is_suse ; then
        run yast2 firewall services add service=service:sshd zone=EXT
    fi
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
    log "ERROR: Unknown Command Line Parametr: $1"
    exit 2
    ;;
esac
done

log "Input Params: $NAME, $DOMAIN, $DNS1, $DNS2, $IP_ADDRESS"

# Required parameters - pass these only for DHCP
# For Static IP, need to pass values for all parameters

if [ -z "$NAME" ] || [ -z "$DOMAIN" ]
then
    log_error "NAME or DOMAIN not defined!"
    exit 1
fi

create_admin_user "$ADMIN_USER"
set_user_password "$ADMIN_USER" "$ADMIN_PASSWORD"

set_hostname_domain "${NAME}" "${DOMAIN}"

if [ ! -z "$DNS1" ] || [ ! -z "$DNS2" ]
then
     enable_networking "${DOMAIN}" "${DNS1}" "${DNS2}"
fi

configure_ssh

# TODO - reboot?