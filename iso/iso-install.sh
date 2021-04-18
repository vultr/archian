#!/bin/bash

# ISO Installaltion Script
# Version: 2.0
# Author: Eric Benner

set -eo pipefail

# Fix mirrors
/bin/rm -f /etc/pacman.d/mirrorlist
curl -o '/etc/pacman.d/mirrorlist' 'https://archlinux.org/mirrorlist/?country=all&protocol=http&protocol=https&ip_version=4&ip_version=6&use_mirror_status=on'
sed -i -e 's/#Server/Server/g' /etc/pacman.d/mirrorlist
pacman -Sy pacman-mirrorlist --noconfirm

# Enter directory
cd archian

# Check for installation script
if [ -f ../archian.json ]; then
    mv ../archian.json ./
    LOGGING="true"
else
    LOGGING="false"
fi

# Move user scripts
if [ -f ../archian-boot.sh ]; then
    mv ../archian-boot.sh ./rootfs/opt/boot.sh
    chmod +x ./rootfs/opt/boot.sh
fi

if [ -f ../archian-post.sh ]; then
    mv ../archian-post.sh ./bin/archian-post.sh
    chmod +x ./bin/archian-post.sh
fi

# Start
chmod +x bin/*

if [ "$LOGGING" == "true" ]; then
    ./bin/archian.sh > arch-install.log
else
    ./bin/archian.sh
fi

