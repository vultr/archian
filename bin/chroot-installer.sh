#!/bin/bash

# Desktop Installaltion Script
# Version: 2.0
# Author: Eric Benner

# Assign arguments
drive=$1
os=$2

# Set base dir
cd /root/archian

# Imports
. lib/common.sh



#
# Installer
#

# Install ABSOLUTE essentials
pacman -Sy wget git unzip zip base-devel grub efibootmgr dosfstools os-prober mtools sudo nano dialog --noconfirm

# Setup
setClock
configureLocale
configureHosts
buildInitramfs

# Set User details
setRootPassword
addUser

# Finish system setup
configureSudo
installGrub $drive
configureRepo

# Copy files
/bin/cp -rf rootfs/* /

# Setup package installer
setupInstaller

# Install Base Packages
install "Common" "common"

case $os in
    [1]* ) desktopSetup;;
    [2]* ) serverSetup;;
    [3]* ) blackArchSetup;;
esac

# Enable/Disable services
systemctl enable ufw
systemctl enable sshd
systemctl enable NetworkManager
systemctl enable archboot
timedatectl set-ntp true

# Dispose of installer user
removeInstaller

# Cleanup
cleanup