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
            ("kde") desktop=1; break;;
            ("enlightenment") desktop=2; break;;
            ("lxde") desktop=3; break;;
            ("xfce") desktop=4; break;;
            *) desktop=5; break;;
        esac
    else
        # Install DE
        desktop=$(/root/archian/bin/dialog --backtitle "Archian" \
                        --title "Desktop Selection" \
                        --menu "Select desktop installation." 15 30 10 1 "KDE" 2 "Enlightenment" 3 "LXDE" 4 "XFCE" 5 "None" \
                        3>&1 1>&2 2>&3 3>&-)
    fi

    case $desktop in
        [1]* ) installKDE; break;;
        [2]* ) installEnlightenment; break;;
        [3]* ) installLXDE; break;;
        [4]* ) installXFCE; break;;
        [5]* ) break;;
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