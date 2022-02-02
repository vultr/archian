#!/bin/bash

# Web Installaltion Script
# Author: Eric Benner

set -eo pipefail

# Fix issue with space
mount -t ramfs -o size=64mb ramfs /tmp
mount -t ramfs -o size=64mb ramfs /home
mount -o remount,size=400M /run/archiso/cowspace

# Go to root
cd /root

# Fix mirrors
set +eo pipefail
/bin/mv /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bk
curl -o '/etc/pacman.d/mirrorlist' 'https://archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on'
sed -i -e 's/#Server/Server/g' /etc/pacman.d/mirrorlist
pacman -Sy pacman-mirrorlist --noconfirm
if [ "$?" != "0" ]; then
    /bin/rm -f /etc/pacman.d/mirrorlist
    /bin/mv /etc/pacman.d/mirrorlist.bk /etc/pacman.d/mirrorlist
fi
set -eo pipefail

# Install git
pacman -Sy --noconfirm
pacman -S git --noconfirm

# Clone
git clone https://github.com/eb3095/archian

# Check for installation script
if [ -f "archian.json" ]; then
    mv archian.json archian/
    LOGGING="true"
else
    LOGGING="false"
fi

# Move rootfs
if [ -f ../rootfs ]; then
    cp -rf ../rootfs rootfs/
fi

# Move user scripts
if [ -f "archian-boot.sh" ]; then
    mv archian-boot.sh archian/rootfs/opt/boot.sh
    chmod +x archian/rootfs/opt/boot.sh
fi

if [ -f "archian-post.sh" ]; then
    mv archian-post.sh archian/bin/archian-post.sh
    chmod +x archian/bin/archian-post.sh
fi

# Start
cd archian
chmod +x bin/*

if [ "$LOGGING" == "true" ]; then
    ./bin/archian.sh > arch-install.log
else
    ./bin/archian.sh
fi
