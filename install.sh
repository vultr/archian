#!/bin/bash

# Manual Installaltion Script
# Author: Eric Benner

# Fix space issue
mount -t ramfs -o size=64mb ramfs /tmp
mount -t ramfs -o size=64mb ramfs /home

# Refresh keys
rm -rf /etc/pacman.d/gnupg/*.gpg
pacman-key --init
pacman-key --populate
pacman -Sy

chmod +x bin/*

# Check for installation script
if [ -f ../archian.json ]; then
    mv ../archian.json archian/
    LOGGING="true"
else
    LOGGING="false"
fi

# Move user script
if [ -f ../archian-boot.sh ]; then
    mv ../archian-boot.sh rootfs/boot.sh
    chmod +x rootfs/boot.sh
fi

if [ -f ../archian-post.sh ]; then
    mv ../archian-post.sh bin/archian-post.sh
    chmod +x bin/archian-post.sh
fi

if [ "$LOGGING" == "true" ]; then
    ./bin/archian.sh > arch-install.log
else
    ./bin/archian.sh
fi
