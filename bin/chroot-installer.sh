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
Name=*

[Network]
DHCP=yes
EOF

# Enable/Disable services
systemctl enable ufw
systemctl enable sshd
systemctl enable NetworkManager
systemctl enable archboot
systemctl enable systemd-resolved
timedatectl set-ntp true

# Run user script if it exists
if [ -f "bin/archian-post.sh" ]; then
    bin/archian-post.sh > /var/log/archpost.log 2>&1
fi

# Dispose of installer user
removeInstaller

# Vultr specific dns (these get weird when we change them later)
mkdir -p /etc/resolvconf/resolv.conf.d
touch /etc/resolvconf/resolv.conf.d/base

if [ "$(is_vultr)" == "1" ]; then
  cat << EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=108.61.10.10 2001:19f0:300:1704::6
FallbackDNS=8.8.8.8 2001:4860:4860::8888
ReadEtcHosts=yes
EOF
  cat << EOF > /etc/resolv.conf
nameserver 108.61.10.10
nameserver 8.8.8.8
nameserver 2001:19f0:300:1704::6
nameserver 2001:4860:4860::8888
EOF
else
  cat << EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=8.8.8.8 2001:4860:4860::8888
FallbackDNS=8.8.4.4 2001:4860:4860::8844
ReadEtcHosts=yes
EOF
  cat << EOF > /etc/resolv.conf
nameserver 8.8.8.8
nameserver 8.8.4.4
nameserver 2001:4860:4860::8888
nameserver 2001:4860:4860::8844
EOF
fi
chmod -R +x /etc/dhcp

# Cleanup
cleanup
