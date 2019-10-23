#!/bin/bash

# Desktop Installaltion Script
# Version: 1.0
# Author: Eric Benner

# Assign arguments
drive=$1

# Check for UEFI
EFI=false
EFIVARS=/sys/firmware/efi/efivars
if [ -d "$EFIVARS" ]; then
    EFI=true
fi

#
# Functions
#

# Packages
function install {
  arg1=$1
  arg2=$2
  IFSB=$IFS
  IFS=$' '
  PACKAGES=($(cat $arg2))
  IFS=$IFSB
  for (( c=0; c<${#PACKAGES[@]}; c++ ))
  do
     OPTIONS+=( "${PACKAGES[$c]}" )
     OPTIONS+=( "" )
     OPTIONS+=( "on" )
  done

  count=${#PACKAGES[@]}
  packs=$(dialog --backtitle "Archian" \
                  --title "Packages" \
                  --checklist "Choose $arg1 packages" 50 40 "${count}" "${OPTIONS[@]}" \
                  3>&1 1>&2 2>&3 3>&-)

  runuser -l installer -c "trizen -Sy --noconfirm ${packs}"
}

# Optional Packages
function installOptional {
  arg1=$1
  arg2=$2
  dialog --backtitle "Archian" \
          --title "Packages" \
          --yesno "Install $arg1 packages?" 8 30

  $answer=$?
  if [ "$answer" = "1" ] ; then
    install $arg1 $arg2
  fi
}

#
# End Functions
#

# Set time zone
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

# Set the clock
hwclock --systohc

# Configure locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen

# Generate locale
locale-gen

# Configure locale
echo LANG=en_US.UTF-8 > /etc/locale.conf

# Set hostname
echo arch > /etc/hostname

# Create Hosts file
echo "127.0.0.1      localhost" >> /etc/hosts
echo "::1            localhost" >> /etc/hosts
echo "127.0.1.1      arch.localdomain arch" >> /etc/hosts

# Make initramfs
mkinitcpio -p linux

# Install ABSOLUTE essentials
pacman -Sy wget git unzip zip base-devel grub zsh efibootmgr dosfstools os-prober mtools sudo nano dialog --noconfirm

# Set root password
while true; do
  rootpw=$(dialog --backtitle "Archian" \
                  --title "Password" \
                  --insecure \
                  --passwordbox "Enter a root password" 10 30 \
                  3>&1 1>&2 2>&3 3>&-)

  confirmPassword=$(dialog --backtitle "Archian" \
                  --title "Password" \
                  --insecure \
                  --passwordbox "Confirm root password" 10 30 \
                  3>&1 1>&2 2>&3 3>&-)

  if [ "$rootpw" != "$confirmPassword" ] ; then
    dialog --backtitle "Archian" \
            --title "Password" \
            --msgbox 'Passwords dont match!' 6 20
  else
    break
  fi
done

# Get user
user=$(dialog --backtitle "Archian" \
                --title "User" \
                --inputbox "Enter a user name" 10 30 \
                3>&1 1>&2 2>&3 3>&-)

# Set user password
while true; do
  userpw=$(dialog --backtitle "Archian" \
                  --title "Password" \
                  --insecure \
                  --passwordbox "Enter a password for ${user}" 10 30 \
                  3>&1 1>&2 2>&3 3>&-)

  confirmPassword=$(dialog --backtitle "Archian" \
                  --title "Password" \
                  --insecure \
                  --passwordbox "Confirm password for ${user}" 10 30 \
                  3>&1 1>&2 2>&3 3>&-)

  if [ "$userpw" != "$confirmPassword" ] ; then
    dialog --backtitle "Archian" \
            --title "Password" \
            --msgbox 'Passwords dont match!' 6 20
  else
    break
  fi
done

# Set root password
echo root:"$rootpw" | chpasswd

# Setup user
mkdir /home/$user
mkdir /home/$user/bin
cp /etc/skel/.bash* /home/$user/
echo 'if [[ $UID -ge 1000 && -d $HOME/bin && -z $(echo $PATH | grep -o $HOME/bin) ]]' >> /home/$user/.bashrc
echo 'then' >> /home/$user/.bashrc
echo '    export PATH="${PATH}:$HOME/bin"' >> /home/$user/.bashrc
echo 'fi' >> /home/$user/.bashrc
useradd -d /home/$user $user
echo $user:"$userpw" | chpasswd
chown -R $user:$user /home/$user
usermod -aG wheel $user

# Setup SUDOERS
sed -i -e 's/# %wheel ALL=(ALL) NOPASSWD\: ALL/%wheelnpw ALL=(ALL) NOPASSWD\: ALL/' /etc/sudoers
sed -i -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
groupadd wheelnpw

# Setup installer
useradd installer
usermod -aG wheelnpw installer
mkdir /home/installer
chown installer:installer /home/installer

# Install Grub
if [ "$EFI" = true ] ; then
  grub-install --target=x86_64-efi  --bootloader-id=grub_uefi
else
  grub-install --target=i386-pc $drive
fi

# Generate Grub
grub-mkconfig -o /boot/grub/grub.cfg

# Install trizen
pushd /tmp
git clone https://aur.archlinux.org/trizen.git
popd
chmod -R 777 /tmp/trizen
runuser -l installer -c 'cd /tmp/trizen;makepkg -si --noconfirm'
rm -rf /tmp/trizen

# Enable Multilib
echo "[multilib]" >> /etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

# Enable Multilib Testing
echo "[multilib-testing]" >> /etc/pacman.conf
echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

# Install Base Packages
install "base" "/root/archian/packages.txt"

# Install Virtualization Packages
installOptional "virtualization" "/root/archian/virt-packages.txt"

# Install Dev Packages
installOptional "dev" "/root/archian/dev-packages.txt"

# Install Nvidia Packages
installOptional "nvidia" "/root/archian/nvidia.txt"

# Install AMDGPU Packages
installOptional "amdgpu" "/root/archian/amdgpu.txt"

# Install WINE
wine=$(dialog --backtitle "Archian" \
                --title "Wine Selection" \
                --menu "Select wine installation." 15 30 3 1 "Wine" 2 "Wine Staging" 3 "None" \
                3>&1 1>&2 2>&3 3>&-)

case $wine in
    [1]* ) runuser -l installer -c "trizen -Sy --noconfirm wine dxvk-bin lutris"; break;;
    [2]* ) runuser -l installer -c "trizen -Sy --noconfirm wine-staging dxvk-bin lutris"; break;;
    [3]* ) break;;
esac

# Install DE
desktop=$(dialog --backtitle "Archian" \
                --title "Desktop Selection" \
                --menu "Select desktop installation." 15 30 3 1 "KDE" 2 "Enlightenment" 3 "LXDE" 4 "XFCE" 5 "None" \
                3>&1 1>&2 2>&3 3>&-)

case $desktop in
    [1]* ) DE=`cat /root/kde.txt`; runuser -l installer -c "trizen -Sy --noconfirm ${DE}"; systemctl enable sddm; break;;
    [2]* ) DE=`cat /root/enlightenment.txt`; runuser -l installer -c "trizen -Sy --noconfirm ${DE}"; systemctl enable lightdm; break;;
    [3]* ) DE=`cat /root/lxde.txt`; runuser -l installer -c "trizen -Sy --noconfirm ${DE}"; systemctl enable lightdm; break;;
    [4]* ) DE=`cat /root/xfce.txt`; runuser -l installer -c "trizen -Sy --noconfirm ${DE}"; systemctl enable lightdm; break;;
    [5]* ) break;;
esac

# Remove Garbage
runuser -l installer -c 'trizen --remove --noconfirm kwrite konsole konqueror kate kmail'

# Fix permissions for iw
setcap cap_net_raw,cap_net_admin=eip /usr/bin/iwconfig

# Enable/Disable services
systemctl enable ufw
systemctl enable sshd
systemctl enable NetworkManager
systemctl disable dhcpcd
timedatectl set-ntp true

# Configure Firewall
ufw enable
ufw default deny incoming
ufw allow 22

# Dispose of installer user
userdel installer
rm -rf /home/installer

# Cleanup
rm -rf /root/archian
