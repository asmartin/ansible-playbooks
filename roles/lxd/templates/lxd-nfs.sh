#!/bin/bash
###############################################################
## Author:	Andrew Martin <amartin@avidandrew.com>
## Date:	4/23/17
## Descr:	Configures an LXD container to allow mounting
##		NFS shares
## Depend:	lxd
###############################################################
## Author:	Andrew Martin <amartin@avidandrew.com>
if [ $# -ne 1 ]; then
	echo "$0 container"
	exit 1
fi
containername=$1

lxc stop $containername
lxc config set $containername security.privileged true
lxc config set $containername raw.apparmor 'mount,'
lxc start $containername
