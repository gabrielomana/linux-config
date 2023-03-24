#!/bin/bash

# This script lets you upgrade your Sparky 6 installation to Sparky 7.
# It is provided as it is, means no guarantee that will be working with no problems, you are using it on your own risk!
# Backup your personal files before starting.
# Dependencies: apt bash coreutils dialog dpkg grep iputils-ping sparky-info sudo
# Make it executable: chmod +x sparky-dist-upgrade67
# Run it: sudo sparky-dist-upgrade67

# Created by pavroo August 22, 2021
# License: GNU GPL 3

DEPS="bash coreutils dialog grep iputils-ping sparky-info sudo"
TESTROOT=`whoami`
if [ "$TESTROOT" != "root" ]; then
	echo "must be root... exiting..."
	echo "usage is: sudo ./sparky-dist-upgrade67"
	exit 1
fi

PINGTEST0=$(ping -c 1 debian.org | grep [0-9])
if [ "$PINGTEST0" = "" ]; then
	echo "Debian server is offline... exiting..."
	exit 1
fi

PINGTEST1=$(ping -c 1 sparkylinux.org | grep [0-9])
if [ "$PINGTEST1" = "" ]; then
	echo "Sparky server is offline... exiting..."
	exit 1
fi

OSCODE="`cat /etc/lsb-release | grep Tolo`"
if [ "$OSCODE" = "" ]; then
	echo "This is not Sparky 6 Po Tolo... exiting..."
	exit 1
fi

DIALOG="`which dialog`"
HEIGHT="20"
WIDTH="75"
TITLE="--title "
TEXT=""
YESNO="--yesno "
TITLETEXT="Sparky Dist Upgrade 6 to 7"
$DIALOG $TITLE"$TITLETEXT" $YESNO $TEXT"\nThis script lets you upgrade your Sparky 6 installation to Sparky 7. \n\nIt is provided as it is, means no guarantee that will be working with no problems, you are using it on your own risk! \n\nBackup your personal files before starting. \n\nMake sure you have all dependencies installed:\n$DEPS \n\nStarting dist upgrade now?" $HEIGHT $WIDTH
if [ "$?" != "0" ]; then
	echo "Exiting now..."
	exit 1
fi

rm -f /etc/apt/sources.list
cat > /etc/apt/sources.list <<FOO
deb http://deb.debian.org/debian/ bookworm main contrib non-free non-free non-free-firmware
deb-src http://deb.debian.org/debian/ bookworm main contrib non-free non-free non-free-firmware
deb http://security.debian.org/debian-security/ bookworm-security/updates main non-free non-free non-free-firmware contrib
deb-src http://security.debian.org/debian-security/ bookworm-security/updates main contrib non-free non-free non-free-firmware
deb http://deb-multimedia.org/ bookworm main non-free
FOO

rm -f /etc/apt/sources.list.d/sparky.list
cat > /etc/apt/sources.list.d/sparky.list <<FOO
deb [signed-by=/usr/share/keyrings/sparky.gpg.key] https://repo.sparkylinux.org/ core main
deb-src [signed-by=/usr/share/keyrings/sparky.gpg.key] https://repo.sparkylinux.org/ core main
deb [signed-by=/usr/share/keyrings/sparky.gpg.key] https://repo.sparkylinux.org/ orion main
deb-src [signed-by=/usr/share/keyrings/sparky.gpg.key] https://repo.sparkylinux.org/ orion main
FOO
wget -O - https://repo.sparkylinux.org/sparky.gpg.key | sudo tee /usr/share/keyrings/sparky.gpg.key
sudo rm -f /etc/apt/sources.list
sudo rm -f /etc/apt/sources.list.d/mx*.list
sudo rm -f /etc/apt/sources.list.d/*backports.list

sudo apt-key del C40956B8
sudo apt-key del D117204E
sudo apt update

sudo apt full-upgrade -y --force-yes
sudo dpkg --configure -a --force-confnew

