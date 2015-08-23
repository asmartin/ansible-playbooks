### Overview
These playbooks allow you to set up a series of servers on your network easily,
either as separate containers or virtual machines, including:

-    [Web Launcher](http://avidandrew.com/pages/weblauncher.html) - an elegant tool for launching your favorite webpages on a remote computer
-    storage - an NFS fileserver (NAS), run the storage.yml playbook (or if running with LXC, the recommended configuration, run the `storagelxc.yml` playbook)
-    lxc - an LXC container host with the [LXC Web Panel](https://github.com/claudyus/LXC-Web-Panel)
    -    before installation, determine if this playbook is going to be run on the same host as the `storage` playbook. If so, run the `storagelxc.yml` playbook
         rather than lxc.yml
    -    after running this playbook for the first time, reboot the server to apply the necessary networking changes
-    git - sets up [Gitbucket](https://takezoe.github.io/gitbucket/), a Github clone, to create your own private or local git repository hosting. Note that the default credentials to login to the Gitbucket web interface are `root` and `root` (username and password respectively)
-    madsonic - sets up the [Madsonic](http://www.madsonic.org/) music and video streamer for streaming your music collection to your browser or smartphone

#### NFS Storage

Have a central storage server for all of your files and settings is great for storing large amounts of data and accessing your files from multiple locations. The `storage` playbook provides an easy-to-configure NFS server, which can also be used to store all of the user-specific data (e.g. settings) for other servers that you set up. To enable this, run the `storage` playbook on a server first, and then edit `group_vars/all` and change the following variables:

-    `use_nas` - set this to `true` to instruct other playbooks to mount an NFS share from the NAS in their user-data directory
-    `nas_mount_base` - set this to the hostname of the server where you ran the "storage" playbook

#### Easy Server Deployment with LXC

You can easily spin up a number of servers using [LXC](https://linuxcontainers.org/lxc/introduction/) rather than setting up physical servers or virtual machines. This streamlines setup and does not have any special hardware requirements (e.g. does not require Vt-x). To utilize containers for creating your servers, run the `lxc` playbook first. Note that it is recommended that you run the `lxc` playbook on the same server as `storage` by using the `storagelxc.yml` playbook. See `roles/lxc/defaults/main.yml` for additional information.

### Prerequisites

Before running any of these playbooks, make sure the destination server (`$server`) meets the following requirements:

-    Running an Ubuntu-based Linux distro (14.04 or newer)
-    The `openssh-server` and `python` packages are installed
-    Your public SSH key located in `~/.ssh/id_rsa.pub` has been copied into `/root/.ssh/authorized_keys` on `$server`. If you or `root` don't already have a `.ssh` directory, use `ssh-keygen -t rsa` to generate one
-    The hostname of `$server` has been added to the list in the `hosts` file in the root of your copy of the `ansible-playbooks` repository
-    if you set `use_nas` to true, then login to the server where you ran the "storage" playbook and issue the following commands (assuming `/mnt/storage/containers` is the value for `container_path` in `group_vars/all`:

````
mkdir -p /mnt/storage/containers/$server
exportfs -r
````

### Running a playbook

To run a playbook on the server, select the corresponding `.yml` file in the root of the `ansible-playbooks` directory, e.g `git.yml`. Edit this file to make sure the `hosts` line contains the hostname of the server (multiple hostnames separated by a colon, e.g `server1:server2:server3`). Once done, run the playbook:

````
ansible-playbook --diff -i hosts storagelxc.yml
````

Review the description of the selected playbook in the Overview section above in case there are any additional steps (e.g. rebooting the server after running the playbook for the first time).

