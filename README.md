
# Archian
This is a fully automated and interactive script for installing Arch. It contains a wide variety of options. To install use the following command after booting to the Arch ISO,

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

### archian.json
You can now script the install entirely with archian.json. An example is available in templates/example.json.

This file simply needs to be in the folder you execute the curl for web.sh to bash. If you git clone it your self just move it into the archian folder before running install.sh.


### Archian Media
Build tool for PXE and ISO comming soon.
