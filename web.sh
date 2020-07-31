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

# Start
cd archian
chmod +x bin/*
./bin/archian.sh