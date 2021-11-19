#!/bin/bash

# Archian
# Author: Eric Benner

set -eo pipefail

# Set the time and date
timedatectl set-ntp true

# Import common
. lib/common.sh

# Vultr Raid1 selection
if [ "$SCRIPTED" == "1" ] && [ "$(is_vultr)" == "1" ]; then
  systemctl disable --now sshd
  systemctl mask sshd
fi

# Install dependencies for installer
if [ ! -f /usr/bin/dialog ]; then
  pacman -S dialog unzip wget --noconfirm
fi

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
  DISKS=($(parted -s -l 2>/dev/null | grep -v /dev/sr | grep 'Disk /' | awk '{print $2}' | sed -e "s/://"))
  DISKS_SIZES=($(parted -s -l 2>/dev/null | grep -v /dev/sr | grep 'Disk /' | awk '{print $3}'))
  DISKS_DEVICES=($(parted -s -l 2>/dev/null | grep -v /dev/sr | grep -v DVD |  grep -v CD | grep Model | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}'))
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
  parted --script $drive mkpart primary ext4 261MiB 100%
  mkfs.fat -F32 "$drive"*1
else
  parted --script $drive mklabel msdos
  parted --script $drive mkpart primary ext4 1MiB 100%
  parted --script $drive set 1 boot on
  mkfs.ext4 -F "$drive"*1
fi

# Format drive
if [ "$EFI" = true ] ; then
  mkfs.ext4 -F "$drive"*2
else
  mkfs.ext4 -F "$drive"*1
fi

# Vultr Raid1 selection
if [ "$SCRIPTED" == "1" ] && [ "$(is_vultr)" == "1" ]; then
  raid1=$(getValue "raid1" "archian.json")
  if [ "${raid1}" == "true" ]; then
    mdadm --create --verbose --level=1 --metadata=1.2 --raid-devices=1 /dev/md/md0 /dev/vda1 --force
  fi
fi

# Mount drive
if [ "$EFI" = true ] ; then
  mount "$drive"*2 /mnt
  mkdir -p /mnt/boot/efi
  mount "$drive"*1 /mnt/boot/efi
else
  MOUNTDRIVE="$(ls "$drive"*1)"
  if [ "$SCRIPTED" == "1" ] && [ "$(is_vultr)" == "1" ]; then
    raid1=$(getValue "raid1" "archian.json")
    if [ "${raid1}" == "true" ]; then
      MOUNTDRIVE="/dev/md0"
    fi
  fi

  mount "$MOUNTDRIVE" /mnt
fi

ALLOC="8G"
if [ "$(is_vultr)" == "1" ]; then
  ALLOC="4G"
fi

fallocate -l ${ALLOC} /mnt/swapfile
chmod 600 /mnt/swapfile
mkswap /mnt/swapfile

# Install base
pacstrap /mnt base linux linux-firmware --noconfirm

# Generate fstab
genfstab -U /mnt >> /mnt/etc/fstab
echo "/swapfile swap swap defaults 0 0" >> /mnt/etc/fstab

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

# Installer selection
if [ "$SCRIPTED" == "1" ]; then
  files=$(getValue "files" "archian.json")
  if [ ! -z "${files}" ]; then
    wget "${files} -O files.zip"
    unzip -o files.zip

    if [ -f "archian-boot.sh" ]; then
        mv archian-boot.sh ./rootfs/opt/boot.sh
        chmod +x ./rootfs/opt/boot.sh
    fi

    if [ -f "archian-post.sh" ]; then
        mv archian-post.sh ./bin/archian-post.sh
        chmod +x ./bin/archian-post.sh
    fi
  fi
fi

# Build chroot installer
mkdir -p /mnt/root/
cp -rf ../archian /mnt/root/archian

# Create bootstrap
echo '#!/bin/bash' >> /mnt/root/archian/bootstrap.sh
echo "/root/archian/bin/chroot-installer.sh $drive $os" >> /mnt/root/archian/bootstrap.sh
chmod +x /mnt/root/archian/bootstrap.sh

# Chroot in and run second part
arch-chroot /mnt /root/archian/bootstrap.sh

# Move log
if [ -f arch-install.log ]; then
  mv arch-install.log /mnt/var/log/
fi

# Announce
echo "----------------------------------------"
echo "Finished installing!"
echo "Go ahead and reboot and unmount your ISO"
echo "----------------------------------------"

if [ "$(is_vultr)" == "1" ]; then
  reboot -f -i now
fi
