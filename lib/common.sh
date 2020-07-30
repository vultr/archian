#!/bin/bash

#
# Functions
#

# Packages
function install {
  NAME=$1
  FILE="/root/archian/packages/$2.txt"
  IFSB=$IFS
  IFS=$' '
  PACKAGES=($(cat $FILE))
  IFS=$IFSB
  unset OPTIONS
  for (( c=0; c<${#PACKAGES[@]}; c++ ))
  do
     OPTIONS+=( "${PACKAGES[$c]}" )
     OPTIONS+=( "" )
     OPTIONS+=( "on" )
  done

  count=${#PACKAGES[@]}
  packs=$(/root/archian/bin/dialog --backtitle "Archian" \
                  --title "Packages" \
                  --checklist "Choose $NAME packages" 30 40 "${count}" "${OPTIONS[@]}" \
                  3>&1 1>&2 2>&3 3>&-)

  runuser -l installer -c "trizen -Sy --noconfirm ${packs}"
}

# Optional Packages
function installOptional {
  NAME=$1
  FILE=$2
  /root/archian/bin/dialog --backtitle "Archian" \
          --title "Packages" \
          --yesno "Install $NAME packages?" 8 30

  answer=$?
  if [ "$answer" -eq 0 ] ; then
    install $NAME $FILE
  fi
}

function setClock {
    # Set time zone
    ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

    # Set the clock
    hwclock --systohc
}

function configureLocale {
    # Configure locale
    echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen

    # Generate locale
    locale-gen

    # Configure locale
    echo LANG=en_US.UTF-8 > /etc/locale.conf
}

function configureHosts {
    # Set hostname
    echo arch > /etc/hostname

    # Create Hosts file
    echo "127.0.0.1      localhost" >> /etc/hosts
    echo "::1            localhost" >> /etc/hosts
    echo "127.0.1.1      arch.localdomain arch" >> /etc/hosts
}

function buildInitramfs {
    # Make initramfs
    mkinitcpio -p linux
}

function setRootPassword {
    # Set root password
    while true; do
    rootpw=$(/root/archian/bin/dialog --backtitle "Archian" \
                    --title "Password" \
                    --insecure \
                    --passwordbox "Enter a root password" 10 30 \
                    3>&1 1>&2 2>&3 3>&-)

    confirmPassword=$(/root/archian/bin/dialog --backtitle "Archian" \
                    --title "Password" \
                    --insecure \
                    --passwordbox "Confirm root password" 10 30 \
                    3>&1 1>&2 2>&3 3>&-)

    if [ "$rootpw" != "$confirmPassword" ] ; then
        /root/archian/bin/dialog --backtitle "Archian" \
                --title "Password" \
                --msgbox 'Passwords dont match!' 6 20
    else
        break
    fi
    done

    # Set root password
    echo root:"$rootpw" | chpasswd
}

function addUser {
    # Get user
    user=$(/root/archian/bin/dialog --backtitle "Archian" \
                    --title "User" \
                    --inputbox "Enter a user name" 10 30 \
                    3>&1 1>&2 2>&3 3>&-)

    # Set user password
    while true; do
    userpw=$(/root/archian/bin/dialog --backtitle "Archian" \
                    --title "Password" \
                    --insecure \
                    --passwordbox "Enter a password for ${user}" 10 30 \
                    3>&1 1>&2 2>&3 3>&-)

    confirmPassword=$(/root/archian/bin/dialog --backtitle "Archian" \
                    --title "Password" \
                    --insecure \
                    --passwordbox "Confirm password for ${user}" 10 30 \
                    3>&1 1>&2 2>&3 3>&-)

    if [ "$userpw" != "$confirmPassword" ] ; then
        /root/archian/bin/dialog --backtitle "Archian" \
                --title "Password" \
                --msgbox 'Passwords dont match!' 6 20
    else
        break
    fi
    done

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
}

function configureSudo {
    sed -i -e 's/# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
}

function setupInstaller {
    sed -i -e 's/# %wheel ALL=(ALL) NOPASSWD\: ALL/%wheelnpw ALL=(ALL) NOPASSWD\: ALL/' /etc/sudoers
    groupadd wheelnpw
    useradd installer
    usermod -aG wheelnpw installer
    mkdir /home/installer
    chown installer:installer /home/installer

    # Install trizen
    pushd /tmp
    git clone https://aur.archlinux.org/trizen.git
    popd
    chmod -R 777 /tmp/trizen
    runuser -l installer -c 'cd /tmp/trizen;makepkg -si --noconfirm'
    rm -rf /tmp/trizen
}

function installGrub {
    EFI=$1
    drive=$2

    # Install Grub
    if [ "$EFI" = true ] ; then
    grub-install --target=x86_64-efi  --bootloader-id=grub_uefi
    else
    grub-install --target=i386-pc $drive
    fi

    # Generate Grub
    grub-mkconfig -o /boot/grub/grub.cfg
}

function configureRepo {
    # Enable Multilib
    echo "[multilib]" >> /etc/pacman.conf
    echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf

    # Enable Multilib Testing
    echo "[multilib-testing]" >> /etc/pacman.conf
    echo "Include = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
}

function installWine {
    wine=$(/root/archian/bin/dialog --backtitle "Archian" \
                  --title "Wine Selection" \
                  --menu "Select wine installation." 15 30 10 1 "Wine" 2 "Wine Staging" 3 "None" \
                  3>&1 1>&2 2>&3 3>&-)

    case $wine in
        [1]* ) runuser -l installer -c "trizen -Sy --noconfirm wine"; break;;
        [2]* ) runuser -l installer -c "trizen -Sy --noconfirm wine-staging"; break;;
        [3]* ) break;;
    esac
}

function fixIW {
    setcap cap_net_raw,cap_net_admin=eip /usr/bin/iwconfig
}

function configureFirewall {
    ufw enable
    ufw default deny incoming
    ufw allow 22
}

function removeInstaller {
    userdel installer
    rm -rf /home/installer
}

function cleanup {
    rm -rf /root/archian
}



#
# Variables
#

# Check for UEFI
EFI=false
EFIVARS=/sys/firmware/efi/efivars
if [ -d "$EFIVARS" ]; then
    EFI=true
fi