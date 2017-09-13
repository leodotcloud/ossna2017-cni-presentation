#!/bin/bash
#------------------------------------------------------------------------------
#     DESCRIPTION : This script file is used to simulate a contaier runtime.
#                   The script expects two arguments:
#                       $1: operation ADD/DEL
#                       $2: container id in case operation is DEL
#
#          AUTHOR : Murali Paluru
#
#      CREATED ON : 12-Sep-2017
#------------------------------------------------------------------------------

CONTAINER_IMAGE=leodotcloud/swiss-army-knife:dev

function exec_plugin() {
	contid=$1
	netns=$2

	export CNI_CONTAINERID=$contid
	export CNI_NETNS=$netns
    export CNI_IFNAME=eth0

	network_config=$(echo ${CNI_CONFIG_PATH}/*.conf)
    name=$(jq -r '.name' <$network_config)
    plugin=$(jq -r '.type' <$network_config)

    plugin_result=$($plugin <$network_config)
    if [ $? -ne 0 ]; then
        errmsg=$(echo $plugin_result | jq -r '.msg')
        if [ -z "$errmsg" ]; then
            errmsg=$plugin_result
        fi

        echo "${name} : error executing $CNI_COMMAND: $errmsg"
        exit 1
    elif [[ ${DEBUG} -gt 0 ]]; then
        echo ${plugin_result} | jq -r .
    fi
}

add_container()
{
    echo "Adding a container"
    CONTAINER_ID=$(docker run -itd --net=none ${CONTAINER_IMAGE})
    CONTAINER_PID=$(docker inspect -f '{{ .State.Pid }}' ${CONTAINER_ID})
    CONTAINER_NETWORK_NAMESPACE=/proc/${CONTAINER_PID}/ns/net

    rm -f /var/run/netns/${CONTAINER_ID}
    ln -sv /proc/${CONTAINER_PID}/ns/net /var/run/netns/${CONTAINER_ID}

    exec_plugin ${CONTAINER_ID} ${CONTAINER_NETWORK_NAMESPACE}

    echo "Started container: ${CONTAINER_ID} successfully"
}

delete_container()
{
    echo "Deleting a container"
}



CNI_CONFIG_PATH=${CNI_CONFIG_PATH:-/etc/cni/net.d}
export CNI_PATH=${CNI_PATH:-${PATH}:/opt/cni/bin}

export PATH=$CNI_PATH:$PATH
export CNI_COMMAND=$(echo $1 | tr '[:lower:]' '[:upper:]')

if [ $# -eq 1 ] && [ "${CNI_COMMAND}" == "ADD" ]; then
    # ADD
    add_container
elif [ $# -eq 2 ] && [ "${CNI_COMMAND}" == "DEL" ]; then
    # DEL
    delete_container
else
	echo "Usage: $0 add|del CONTAINER-ID"
	echo "  Adds or deletes the container to the CNI network"
	exit 1
fi
