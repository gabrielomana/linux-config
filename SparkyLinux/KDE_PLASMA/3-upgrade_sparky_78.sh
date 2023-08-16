#!/bin/bash

# This script lets you upgrade your Sparky 7 installation to Sparky 8.
# It is provided as it is, means no guarantee that will be working with no problems, you are using it on your own risk!
# Backup your personal files before starting.
# Dependencies: apt bash coreutils dialog dpkg grep iputils-ping sparky-info sudo
# Make it executable: chmod +x sparky-dist-upgrade78
# Run it: sudo sparky-dist-upgrade78

# Created by pavroo August 22, 2021
# last update June 18, 2023
# License: GNU GPL 3

DEPS="bash coreutils dialog grep iputils-ping sparky-info sudo"
TESTROOT=`whoami`
if [ "$TESTROOT" != "root" ]; then
	echo "must be root... exiting..."
	echo "usage is: sudo ./sparky-dist-upgrade78"
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

OSCODE="`cat /etc/lsb-release | grep Orion`"
if [ "$OSCODE" = "" ]; then
	echo "This is not Sparky 7 Orion Belt... exiting..."
	exit 1
fi

DIALOG="`which dialog`"
HEIGHT="20"
WIDTH="75"
TITLE="--title "
TEXT=""
YESNO="--yesno "
TITLETEXT="Sparky Dist Upgrade 7 to 8"
$DIALOG $TITLE"$TITLETEXT" $YESNO $TEXT"\nThis script lets you upgrade your Sparky 7 installation to Sparky 8. \n\nIt is provided as it is, means no guarantee that will be working with no problems, you are using it on your own risk! \n\nBackup your personal files before starting. \n\nMake sure you have all dependencies installed:\n$DEPS \n\nStarting dist upgrade now?" $HEIGHT $WIDTH
if [ "$?" != "0" ]; then
	echo "Exiting now..."
	exit 1
fi

sudo rm /etc/apt/sources.list -f
echo -e "deb https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb https://deb.debian.org/debian-security/ testing-security main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian-security/ testing-security main contrib non-free non-free-firmware
deb https://deb.debian.org/debian/ testing-updates main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ testing-updates main contrib non-free non-free-firmware
deb https://www.deb-multimedia.org testing main non-free"  | sudo tee -a /etc/apt/sources.list

sudo rm -f /etc/apt/sources.list.d/sparky.list
echo -e "deb https://repo.sparkylinux.org/ core main
deb-src https://repo.sparkylinux.org/ core main
deb https://repo.sparkylinux.org/ sisters main
deb-src https://repo.sparkylinux.org/ sisters main"  | sudo tee -a /etc/apt/sources.list.d/sparky.list

sudo apt update
sudo apt full-upgrade
sudo dpkg --configure -a
sudo apt install -f
sudo apt autoremove
sudo apt clean
sudo apt update
sudo nala update; sudo nala upgrade -y; sudo nala install -f; sudo apt --fix-broken install
sudo aptitude safe-upgrade -y

$DIALOG $TITLE"$TITLETEXT" $YESNO $TEXT"\nIf all done, reboot your machine to take effects.\n\nReboot now?" $HEIGHT $WIDTH
if [ "$?" != "0" ]; then
	exit 1
else
	reboot
fi

exit 0
