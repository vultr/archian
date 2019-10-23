#!/bin/bash

# Archian
# Version: 1.0
# Author: Eric Benner

# Set the time and date
timedatectl set-ntp true

# Check for UEFI
EFI=false
EFIVARS=/sys/firmware/efi/efivars
if [ -d "$EFIVARS" ]; then
    EFI=true
fi

# Setup directories
mkdir /archian
mkdir /archian/bin
mkdir /archian/packages
mkdir /archian/packages/desktop
mkdir /archian/packages/server
mkdir /archian/packages/blackarch
mkdir /archian/packages/de
mkdir /archian/installers

# Download script utils
wget https://raw.githubusercontent.com/eb3095/archian/master/bin/dialog -O /archian/bin/dialog
wget https://raw.githubusercontent.com/eb3095/archian/master/packages/desktop/packages.txt -O /archian/packages/desktop/packages.txt
wget https://raw.githubusercontent.com/eb3095/archian/master/packages/desktop/dev-packages.txt -O /archian/packages/desktop/dev-packages.txt
wget https://raw.githubusercontent.com/eb3095/archian/master/packages/desktop/virt-packages.txt -O /archian/packages/desktop/virt-packages.txt
wget https://raw.githubusercontent.com/eb3095/archian/master/packages/desktop/nvidia.txt -O /archian/packages/desktop/nvidia.txt
wget https://raw.githubusercontent.com/eb3095/archian/master/packages/desktop/amdgpu.txt -O /archian/packages/desktop/amdgpu.txt
wget https://raw.githubusercontent.com/eb3095/archian/master/packages/server/packages.txt -O /archian/packages/server/packages.txt
wget https://raw.githubusercontent.com/eb3095/archian/master/packages/server/virt-packages.txt -O /archian/packages/server/virt-packages.txt
wget https://raw.githubusercontent.com/eb3095/archian/master/packages/blackarch/packages.txt -O /archian/packages/blackarch/packages.txt
wget https://raw.githubusercontent.com/eb3095/archian/master/packages/de/kde.txt -O /archian/packages/de/kde.txt
wget https://raw.githubusercontent.com/eb3095/archian/master/packages/de/xfce.txt -O /archian/packages/de/xfce.txt
wget https://raw.githubusercontent.com/eb3095/archian/master/packages/de/enlightenment.txt -O /archian/packages/de/enlightenment.txt
wget https://raw.githubusercontent.com/eb3095/archian/master/packages/de/lxde.txt -O /archian/packages/de/lxde.txt
wget https://raw.githubusercontent.com/eb3095/archian/master/installers/desktop.sh -O /archian/installers/desktop.sh
wget https://raw.githubusercontent.com/eb3095/archian/master/installers/blackarch.sh -O /archian/installers/blackarch.sh
wget https://raw.githubusercontent.com/eb3095/archian/master/installers/server.sh -O /archian/installers/server.sh

# Set permissions
chmod +x /archian/bin/dialog

IFS=$'\n'
DISKS=($(parted -l | grep 'Disk /' | awk '{print $2}' | sed -e "s/://"))
DISKS_SIZES=($(parted -l | grep 'Disk /' | awk '{print $3}'))
DISKS_DEVICES=($(parted -l | grep Model | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}'))

# Disk Selection
for (( c=0; c<${#DISKS[@]}; c++ ))
do
   DISK_LIST+=( "${DISKS[$c]}" )
   DISK_LIST+=( "${DISKS_SIZES[$c]} ${DISKS_DEVICES[$c]}" )
done
count=${#DISKS[@]}
drive=$(/archian/bin/dialog --backtitle "Archian" \
                --title "Disk Manager" \
                --menu "Select a drive to install to. WARNING: This will DELETE all data!" 15 70 $count "${DISK_LIST[@]}" \
                3>&1 1>&2 2>&3 3>&-)

# Partition drive
if [ "$EFI" = true ] ; then
  parted --script $drive mklabel gpt
  parted --script $drive mkpart primary fat32 1MiB 261MiB
  parted --script $drive set 1 esp on
  parted --script $drive mkpart primary linux-swap 261MiB 8.3GiB
  parted --script $drive mkpart primary ext4 8.3GiB 100%
  mkfs.fat -F32 "$drive"1
else
  parted --script $drive mklabel msdos
  parted --script $drive mkpart primary linux-swap 1MiB 8GiB
  parted --script $drive mkpart primary ext4 8GiB 100%
  parted --script $drive set 2 boot on
  mkfs.ext4 -F "$drive"1
fi

# Format drive
if [ "$EFI" = true ] ; then
  mkswap "$drive"2
  swapon "$drive"2
  mkfs.ext4 -F "$drive"3
  mount "$drive"3 /mnt
  mkdir -p /mnt/boot/efi
  mount "$drive"1 /mnt/boot/efi
else
  mkswap "$drive"1
  swapon "$drive"1
  mkfs.ext4 -F "$drive"2
  mount "$drive"2 /mnt
fi

# Install base
pacstrap /mnt base linux linux-firmware

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Installer selection
os=$(/archian/bin/dialog --backtitle "Archian" \
                --title "OS Selection" \
                --menu "Select an install script to use." 15 30 3 1 "Desktop" 2 "Server" 3 "Black Arch" \
                3>&1 1>&2 2>&3 3>&-)

# Build chroot installer
mkdir /mnt/root/archian/
mkdir /mnt/root/archian/bin
cp /archian/bin/dialog /mnt/root/archian/bin/dialog
case $os in
  1)
    cp /archian/installers/desktop.sh /mnt/root/archian/chroot-installer.sh
    mv /archian/packages/desktop/* /mnt/root/archian/
    mv /archian/packages/de/* /mnt/root/archian/
    ;;

  2)
    cp /archian/installers/server.sh /mnt/root/archian/chroot-installer.sh
    mv /archian/packages/server/* /mnt/root/archian/
    ;;

  3)
    cp /archian/installers/blackarch.sh /mnt/root/archian/chroot-installer.sh
    mv /archian/packages/blackarch/* /mnt/root/archian/
    ;;
esac
chmod +x /mnt/root/archian/chroot-installer.sh

# Create bootstrap
echo '#!/bin/bash' >> /mnt/root/archian/bootstrap.sh
echo "/root/archian/chroot-installer.sh $drive" >> /mnt/root/archian/bootstrap.sh
chmod +x /mnt/root/archian/bootstrap.sh

# Chroot in and run second part
arch-chroot /mnt /root/archian/bootstrap.sh
