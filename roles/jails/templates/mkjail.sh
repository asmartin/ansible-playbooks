#!/bin/bash
# {{ ansible_managed }}
###############################################################################
## Author:	Andrew Martin <amartin@avidandrew.com>
## Date:	8/31/17
## Descr:	Easily create and bootstrap FreeBSD jails
## Depends:	iocage, zfs
###############################################################################
if [ $# -ne 2 ]; then
	echo "Usage: $0 name public_IP/cidr"
	exit 1
fi

zpool={{ iocage_zpool }}
release={{ iocage_freebsd_release }}
pkglist=$(mktemp)
name=$1
ip=$2
localhost_ip="127.0.$(echo ${ip} | awk -F/ '{ print $1 }' | awk -F. '{ print $3"."$4 }')"
cat << EOF > ${pkglist}
{
    "pkgs": [
    "python"
    ]
}
EOF

function on_exit() {
	rm -f ${pkglist}
}

trap on_exit exit

# create the jail
uuid=$(iocage create -r ${release} -p ${pkglist} -n "${name}" ip4_addr="{{ host_interface }}|${ip},lo0|${localhost_ip}/8")

# bootstrap
dataset=$(iocage get -a ${name} | grep jail_zfs_dataset | sed 's/\/data$//g' | awk -F: '{ print $2 }')
mountpoint=$(zfs get -H -o value mountpoint ${zpool}/${dataset})

# add public ssh key
mkdir ${mountpoint}/root/root/.ssh
cat << EOF > ${mountpoint}/root/root/.ssh/authorized_keys
{{ jail_authorized_keys_list }}
EOF

# allow key-based ssh auth to root
sed -i '' 's/#PermitRootLogin no/PermitRootLogin without-password/g' ${mountpoint}/root/etc/ssh/sshd_config

# enable sshd
echo "sshd_enable=YES" >> ${mountpoint}/root/etc/rc.conf

# set localhost ip
sed -i '' "s/127\.0\.0\.1/${localhost_ip}/g" ${mountpoint}/root/etc/hosts

# start the jail
iocage start ${name}
iocage set boot=on ${name} > /dev/null
