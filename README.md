### Overview
These playbooks allow you to set up a variety of services on your network.

Services:

-    storage - an NFS fileserver (NAS) running on FreeBSD or Ubuntu:
    -    `storage.yml` - FreeBSD NFS fileserver with ZFS and jails for hosting services
    -    `storage-ubuntu.yml` - Ubuntu NFS fileserver with ZFS and LXD containers and QEMU VMs for hosting services
-    subsonic - sets up the [Subsonic](https://github.com/Libresonic/libresonic) (aka Libresonic) music and video streamer for streaming your music collection to your browser or smartphone. Note: the initial run of this service will take several minutes before the web interface is accessible while the application is extracted (even after the playbook finishes).
-    [Web Launcher](http://avidandrew.com/pages/weblauncher.html) - an elegant tool for launching your favorite webpages on a remote computer
-    wiki - configure [DokuWiki](https://www.dokuwiki.org), an easy-to-use self-hosted wiki

Building Blocks:

-    common - installs commonly-used packages, configures disk monitoring (e.g. SMART), and other general tasks
-    apache2 - configure the apache2 web server with PHP for hosting websites
-    nginx - configure the nginx web server with PHP for hosting websites
-    jails - setup FreeBSD jails using [iocage](https://github.com/iocage/iocage)
-    lxd - setup an [LXD](https://linuxcontainers.org/lxd/) container host
-    qemu - a QEMU/KVM virtual machine host with `libvirt` for managing the virtual machines. You can use [virt-manager](https://virt-manager.org/) as a graphical VM manager from your local computer
-    nfs-mount - mount an NFS share
-    virt-netcfg - configure networking on Ubuntu to support virtualization (LXD or QEMU)

#### NFS Storage

Having a central storage server for all of your files and settings is a great way to store this large amount of data and to be able to access your files from multiple locations. To setup a NAS, run either `storage.yml` (FreeBSD) or `storage-ubuntu.yml` (Ubuntu).

##### LXD/NFS Integration
The `storage-ubuntu.yml` playbook provides an easy-to-configure NFS server, which can also be used to store all of the user-specific data (e.g. settings) for other servers that you set up. To enable this, run the `storage-ubuntu.yml` playbook on a server first, and then edit `group_vars/all` and change the following variables:

-    `use_nas` - set this to `true` to instruct other playbooks to mount an NFS share from the NAS in their user-data directory
-    `nas_mount_base` - set this to the hostname of the server where you ran the "storage.yml" playbook

#### Easy Server Deployment with LXD or Jails

You can easily spin up a number of servers using [LXD](https://linuxcontainers.org/lxd) (Ubuntu) or jails on FreeBSD rather than setting up physical servers or virtual machines. This streamlines setup and does not have any special hardware requirements (e.g. does not require Vt-x). To utilize containers for creating your servers, run the `storage.yml` playbook for FreeBSD or the `storage-ubuntu.yml` playbook for Ubuntu.

### Prerequisites

Before running any of these playbooks, make sure the destination server (`$server`) meets the following requirements:

-    Running an Ubuntu-based Linux distro (14.04 or newer) or FreeBSD
-    The `openssh-server` and `python` packages are installed
-    Your public SSH key located in `~/.ssh/id_rsa.pub` has been copied into `/root/.ssh/authorized_keys` on `$server`. If you or `root` don't already have a `.ssh` directory, use `ssh-keygen -t rsa` to generate one
-    The hostname of `$server` has been added to the list in the `hosts` file in the root of your copy of this repository
-    if you set `use_nas` to `True`, then login to the server where you ran the `storage-ubuntu.yml` playbook and issue the following commands (assuming `/mnt/storage/containers` is the value for `container_path` in `group_vars/all`:

````
mkdir -p /mnt/storage/containers/$server
exportfs -r
````

### Running a playbook

To run a playbook on the server, select the corresponding `.yml` file in the root of the `ansible-playbooks` directory, e.g `lxd.yml`. Edit this file to make sure the `hosts:` line contains the hostname of the server (multiple hostnames separated by a colon, e.g `hosts: "server1:server2:server3"`). Once done, run the playbook:

````
ansible-playbook --diff -i hosts storage.yml
````

Review the description of the selected playbook in the Overview section above in case there are any additional steps (e.g. rebooting the server after running the playbook for the first time).


