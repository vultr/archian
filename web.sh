#!/bin/bash

# Desktop Installaltion Script
# Version: 2.0
# Author: Eric Benner

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