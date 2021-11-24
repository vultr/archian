#!/bin/bash

function blackArchSetup {
    install "Desktop" "desktop"
    installOptional "Nvidia" "nvidia"
    installOptional "AMDGPU" "amdgpu"
    installOptional "Developement" "dev"
    installOptional "Virtualization" "virt"
    installOptional "Docker" "docker"
    installOptional "LXD" "lxd"
    installOptional "Extras" "extras"
    installWine

    curl -O https://blackarch.org/strap.sh
    chmod +x ./strap.sh
    ./strap.sh

    pacman -Syyu --noconfirm

    if [ "$SCRIPTED" == "1" ]; then
        INSTALL=$(getValue "packages.blackarch")
        if [ "$INSTALL" == "true" ]; then
            answer=1
        else
            answer=0
        fi
    else
        dialog --backtitle "Archian" \
                        --title "" \
                        --yesno "Install Black Arch packages?" 8 30

        answer=$?
    fi

    if [ "$answer" -eq 0 ] ; then
        pacman -S blackarch --noconfirm
    fi
}