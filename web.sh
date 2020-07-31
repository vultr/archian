#!/bin/bash

# Desktop Installaltion Script
# Version: 2.0
# Author: Eric Benner

set -eo pipefail

# Install git
pacman -Syyu --noconfirm
pacman -S git --noconfirm

# Clone
git clone https://github.com/eb3095/archian

# Check for installation script
FILE=./archian.json
if [ -f "$FILE" ]; then
    mv ./archian.json archian/
fi

# Start
cd archian
chmod +x bin/*
./bin/archian.sh