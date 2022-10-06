#!/bin/bash

# Desktop Installaltion Script
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
pacman -Sy wget git unzip zip base-devel grub efibootmgr dosfstools lvm2 os-prober mtools sudo nano dialog pacutils --noconfirm

# Install iptables-nft, conflicts arise otherwise
yes | pacman -Sy iptables-nft

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

# Permissions
chmod +x /opt/archboot.sh

# Setup package installer
setupInstaller

# Install Base Packages
install "Common" "common"

case $os in
    [1]* ) desktopSetup;;
    [2]* ) serverSetup;;
    [3]* ) blackArchSetup;;
esac

# Configure DHCP and Resolv
cat << EOF > /etc/systemd/network/20-wired.network
[Match]
Name=e*

[Network]
DHCP=yes
EOF

# Configure resolv
mkdir -p /etc/resolvconf/resolv.conf.d
touch /etc/resolvconf/resolv.conf.d/base

echo "DNS=8.8.8.8 2001:4860:4860::8888" >> /etc/systemd/resolved.conf
echo "FallbackDNS=8.8.4.4 2001:4860:4860::8844" >> /etc/systemd/resolved.conf
echo "ReadEtcHosts=yes" >> /etc/systemd/resolved.conf
echo "nameserver 8.8.8.8" > /etc/resolv.conf
echo "nameserver 8.8.4.4" >> /etc/resolv.conf
echo "nameserver 2001:4860:4860::8888" >> /etc/resolv.conf
echo "nameserver 2001:4860:4860::8844" >> /etc/resolv.conf

# Enable/Disable services
systemctl enable ufw
systemctl enable sshd
systemctl enable NetworkManager
systemctl enable archboot
timedatectl set-ntp true

# Run user script if it exists
if [ -f "bin/archian-post.sh" ]; then
    bin/archian-post.sh > /var/log/archpost.log 2>&1
fi

# Dispose of installer user
removeInstaller

# Cleanup
cleanup
