#!/bin/bash

# Desktop Installaltion Script
# Version: 2.0
# Author: Eric Benner

set -eo pipefail

# Fix issue with space
mount -t ramfs -o size=64mb ramfs /tmp
mount -t ramfs -o size=64mb ramfs /home

# Go to new root
cd /root

# Fix mirrors
/bin/rm -f /etc/pacman.d/mirrorlist
curl -o '/etc/pacman.d/mirrorlist' 'https://www.archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on'
sed -i -e 's/#Server/Server/g' /etc/pacman.d/mirrorlist
pacman -Sy pacman-mirrorlist --noconfirm

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

# Move user scripts
if [ -f "archian-boot.sh" ]; then
    mv archian-boot.sh archian/rootfs/boot.sh
    chmod +x archian/rootfs/boot.sh
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
