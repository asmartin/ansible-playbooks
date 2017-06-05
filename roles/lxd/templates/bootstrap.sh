#!/bin/bash
############################################################
## Author:	Andrew Martin <amartin@avidandrew.com>
## Date:	2/27/17
## Descr:	Bootstraps a new LXD container for ansible
## Depend:	lxd, public key in ~/.ssh/authorized_keys
############################################################
if [ "$1" == "" ]; then
	echo "Error: you must specify the container name"
	exit 1
fi
container=$1
key=$(mktemp)

function on_exit() {
	rm -f $key
}

lxc list | grep -q ${container}
if [ $? -ne 0 ]; then
	echo "Error: container '${container}' not found"
	exit 2
fi

trap on_exit EXIT

echo "{{ lxd_push_public_key }}" > ${key}

echo "bootstrapping ${container}..."
lxc file push ${key} $1/root/.ssh/authorized_keys
lxc exec $1 -- apt-get install -y python2.7
