#!/bin/bash

function desktopSetup {
    install "Desktop" "desktop"
    installOptional "Nvidia" "nvidia"
    installOptional "AMDGPU" "amdgpu"
    installOptional "Developement" "dev"
    installOptional "Virtualization" "virt"
    installWine

    if [ "$SCRIPTED" == "1" ]; then
        desktop=$(getValue "packages.desktopEnvironment")
        case $desktop in
            ("kde") desktop=1;;
            ("enlightenment") desktop=2;;
            ("lxde") desktop=3;;
            ("xfce") desktop=4;;
            *) desktop=5;;
        esac
    else
        # Install DE
        desktop=$(dialog --backtitle "Archian" \
                        --title "Desktop Selection" \
                        --menu "Select desktop installation." 15 30 10 1 "KDE" 2 "Enlightenment" 3 "LXDE" 4 "XFCE" 5 "None" \
                        3>&1 1>&2 2>&3 3>&-)
    fi

    case $desktop in
        [1]* ) installKDE;;
        [2]* ) installEnlightenment;;
        [3]* ) installLXDE;;
        [4]* ) installXFCE;;
        [5]* ) ;;
    esac
}

function installDE {
    DE=`cat /root/archian/packages/$1.txt`
    runuser -l installer -c "trizen -Sy --noconfirm ${DE}";
}

function installKDE {
    installDE "kde"
    runuser -l installer -c 'trizen --remove --noconfirm kwrite konsole konqueror kate kmail yakuake';
    systemctl enable sddm;
}

function installEnglightenment {
    installDE "enlightenment"
    systemctl enable lightdm;
}

function installLXDE {
    installDE "lxde"
    systemctl enable lightdm;
}

function installXFCE {
    installDE "xfce"
    systemctl enable lightdm;
}