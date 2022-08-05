#!/bin/bash

# ISO Installaltion Script
# Author: Eric Benner

set -eo pipefail

# Refresh keys
pacman-key --refresh-keys

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
    ./bin/archian.sh > arch-install.log 2>&1
else
    ./bin/archian.sh
fi

