#!/bin/bash

function blackArchSetup {
    install "Desktop" "desktop"
    installOptional "Nvidia" "nvidia"
    installOptional "AMDGPU" "amdgpu"
    installOptional "Developement" "dev"
    installOptional "Virtualization" "virt"
    installWine

    curl -O https://blackarch.org/strap.sh
    chmod +x ./strap.sh
    ./strap.sh

    pacman -Syyu --noconfirm

    /root/archian/bin/dialog --backtitle "Archian" \
                    --title "" \
                    --yesno "Install Black Arch packages?" 8 30

    answer=$?
    if [ "$answer" -eq 0 ] ; then
        pacman -S blackarch --noconfirm
    fi
}