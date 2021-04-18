
# Archian
This is a fully automated and interactive script for installing Arch. It contains a wide variety of options. To install use the
following command after booting to the Arch ISO,

### Use
```
curl -q https://raw.githubusercontent.com/eb3095/archian/master/web.sh | bash
```

or

```
pacman -Sy --noconfirm
pacman -S git --noconfirm
git clone https://github.com/eb3095/archian
cd archian
./install.sh
```

or

Use the ISO from the **Archian Media** section.

### Available Bases
* Desktop
* BlackArch
* Server

### Available Package Selections
* Virtualization + OVMF
* Nvidia Drivers
* AMDGPU Drivers
* Vulcan
* Wine
* Developement tools
* Desktop Applications

### Available Desktops
* KDE
* Enlightenment
* LXDE
* XFCE
* None

### Scripted Installs

#### archian.json
You can now script the install entirely with archian.json. An example is available in templates/example.json. This defines everything
before hand about the install process. Package configuration is exclusionary but you can disable all packages. Black arch is for the
blackarch install only.

The entire install process is logged to /var/log/arch-install.log. The install process is only logged when scripted. As of now I do
not have a proper work around for stdout/stderr redirection that doesn't break dialog.

Note the "files" option in the json format. This is to provide a link to download the rootfs directory and scripts. This needs to be a
zip file as of right now. The structure of this should be as follows.

```
rootfs/
  root/
  etc/
archian-boot.sh
archian-post.sh
```

#### archian-boot.sh
The boot script is a bash script named archian-boot.sh. This executes on first boot after the archian boot process runs. The boot script
is entirely optional. This does not require archian.json. Everything is logged to /var/log/archboot.log.

#### archian-post.sh
This script is executed after everything is done, while still chrooted, but before the installer is removed. Use the following to install
packages via trizen from repo or aur. Be warned this isn't verified and just confirms everything. This script is optional. This does not
require archian.json. This is logged to /var/log/archpost.log

```
install_pkgs nano vi emacs
```

#### rootfs
Files in rootfs are copied over, overwriting anything else in there. If you need anything more then that, do it in the scripts.

These files simply need to be in the folder you are in when you execute the curl for web.sh. If you git clone it your self just move
them into the archian folder's rootfs before running install.sh. Same with the ISO if you build it manually.

Web
```
./
  archian.json
  archian-boot.sh
  archian-post.sh
  rootfs/
```

Git / ISO
```
archian.json
archian-boot.sh
archian-post.sh
archian/
  install.sh
  rootfs/
  bin/
  lib/
  ...
```


### Archian Media
Build tool for PXE and ISO comming soon.

<a href="https://www.buymeacoffee.com/eb3095" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: 41px !important;width: 174px !important;box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;-webkit-box-shadow: 0px 3px 2px 0px rgba(190, 190, 190, 0.5) !important;" ></a>