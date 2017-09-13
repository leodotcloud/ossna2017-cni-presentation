#!/bin/bash

mkdir -p /etc/cni/net.d /opt/cni/bin /var/run/netns

source ./demo_env.sh

BRIDGE_NAME=demobr0
BRIDGE_SUBNET_VAR=$(echo $(hostname)_CONTAINERS_SUBNET)
BRIDGE_SUBNET=${!BRIDGE_SUBNET_VAR}

get_bridge_ip()
{
    bridge_subnet=$1
    prefix=$(echo ${bridge_subnet} | cut -d'/' -f2)
    bridge_ip=$(echo $(echo ${bridge_subnet} | cut -d'/' -f1 | cut -d'.' -f1-3).1/${prefix})
    echo ${bridge_ip}
}

ip link show ${BRIDGE_NAME} &> /dev/null
if [ $? -ne 0 ]; then
    ip link add ${BRIDGE_NAME} type bridge
    BRIDGE_IP=$(get_bridge_ip ${BRIDGE_SUBNET})
    ip link set dev ${BRIDGE_NAME} up
    ip address add ${BRIDGE_IP} dev ${BRIDGE_NAME}
fi
