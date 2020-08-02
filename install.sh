#!/bin/bash

# Desktop Installaltion Script
# Version: 2.0
# Author: Eric Benner

chmod +x bin/*

# Move user script
if [ -f "archian-boot.sh" ]; then
    mv archian-boot.sh rootfs/boot.sh
    chmod +x rootfs/boot.sh
fi

if [ -f "archian-post.sh" ]; then
    mv archian-post.sh bin/archian-post.sh
    chmod +x bin/archian-post.sh
fi

bin/archian.sh
