#!/bin/bash

# Archian
# Version: 2.0
# Author: Eric Benner

# Set the time and date
timedatectl set-ntp true

# Import common
. lib/common.sh

# Install dependencies for installer
pacman -S dialog --noconfirm

if [ "$SCRIPTED" == "1" ]; then
  drive=$(getValue "drive" "archian.json")
  if [ -f "$drive" ]; then
    echo "Failed because $drive was not found"
    return 255
  fi
else
  # Disk info
  IFSB=$IFS
  IFS=$'\n'
  DISKS=($(parted -l 2>/dev/null | grep -v /dev/sr | grep 'Disk /' | awk '{print $2}' | sed -e "s/://"))
  DISKS_SIZES=($(parted -l 2>/dev/null | grep -v /dev/sr | grep 'Disk /' | awk '{print $3}'))
  DISKS_DEVICES=($(parted -l 2>/dev/null | grep -v /dev/sr | grep -v DVD |  grep -v CD | grep Model | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}'))
  IFS=$IFSB

  # Disk Selection
  for (( c=0; c<${#DISKS[@]}; c++ ))
  do
    DISK_LIST+=( "${DISKS[$c]}" )
    DISK_LIST+=( "${DISKS_SIZES[$c]} ${DISKS_DEVICES[$c]}" )
  done
  count=${#DISKS[@]}
  drive=$(dialog --backtitle "Archian" \
                  --title "Disk Manager" \
                  --menu "Select a drive to install to. WARNING: This will DELETE all data!" 15 70 $count "${DISK_LIST[@]}" \
                  3>&1 1>&2 2>&3 3>&-)
fi

# Partition drive
if [ "$EFI" = true ] ; then
  parted --script $drive mklabel gpt
  parted --script $drive mkpart primary fat32 1MiB 261MiB
  parted --script $drive set 1 esp on
  parted --script $drive mkpart primary linux-swap 261MiB 8.3GiB
  parted --script $drive mkpart primary ext4 8.3GiB 100%
  mkfs.fat -F32 "$drive"*1
else
  parted --script $drive mklabel msdos
  parted --script $drive mkpart primary linux-swap 1MiB 8GiB
  parted --script $drive mkpart primary ext4 8GiB 100%
  parted --script $drive set 2 boot on
  mkfs.ext4 -F "$drive"*1
fi

# Format drive
if [ "$EFI" = true ] ; then
  mkswap "$drive"*2
  swapon "$drive"*2
  mkfs.ext4 -F "$drive"*3
  mount "$drive"*3 /mnt
  mkdir -p /mnt/boot/efi
  mount "$drive"*1 /mnt/boot/efi
else
  mkswap "$drive"*1
  swapon "$drive"*1
  mkfs.ext4 -F "$drive"*2
  mount "$drive"*2 /mnt
fi

# Install base
pacstrap /mnt base linux linux-firmware --noconfirm

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

# Installer selection
if [ "$SCRIPTED" == "1" ]; then
  os=$(getValue "os" "archian.json")
  case $os in
    ("desktop") os=1;;
    ("server") os=2;;
    ("blackarch") os=3;;
    *) echo "Bad os selection: $os"; return 255;;
  esac
else
  os=$(dialog --backtitle "Archian" \
                  --title "OS Selection" \
                  --menu "Select an install script to use." 15 30 3 1 "Desktop" 2 "Server" 3 "Black Arch" \
                  3>&1 1>&2 2>&3 3>&-)
fi

# Build chroot installer
cp -rf ../archian /mnt/root/

# Create bootstrap
echo '#!/bin/bash' >> /mnt/root/archian/bootstrap.sh
echo "/root/archian/bin/chroot-installer.sh $drive $os" >> /mnt/root/archian/bootstrap.sh
chmod +x /mnt/root/archian/bootstrap.sh

# Chroot in and run second part
arch-chroot /mnt /root/archian/bootstrap.sh

# Move log
mv arch-install.log /mnt/var/log/
