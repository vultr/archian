#!/bin/bash

env

# UFW
ufw enable
ufw default deny incoming
ufw allow 22

# Execute user script if it exists
if [ -f "/opt/boot.sh" ]; then
    /opt/boot.sh
    rm /opt/boot.sh
fi

systemctl disable archboot.service
rm -f /etc/systemd/system/archboot.service
rm -f /opt/archboot.sh
