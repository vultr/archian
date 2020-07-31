#!/bin/bash

env

# UFW
ufw enable
ufw default deny incoming
ufw allow 22

systemctl disable archboot.service
rm -f /etc/systemd/system/archboot.service
rm -f /opt/archboot.sh
