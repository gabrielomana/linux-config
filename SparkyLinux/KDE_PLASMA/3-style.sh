#!/bin/bash
if [ "$(whoami)" != "root" ]
then
    sudo su -s "$0"
    exit
fi
dir="$(pwd)"

#POP_OS ICONS
clear
echo "POP_OS! ICONS"
wget https://github.com/gabrielomana/Pop_Os-Icons/raw/main/KDE/Pop_Os-Icons.tar.gz
sudo tar -xvf Pop_Os-Icons.tar.gz -C /usr/share/icons/
rm Pop_Os-Icons.tar.gz -rf
sleep 3


#Theme Windows
clear
echo "Theme: Win11OS"

git clone https://github.com/yeyushengfan258/Win11OS-kde.git /git/Win11OS-kde
cd /git/Win11OS-kde
./install.sh
sleep 3

#Win10OS-cursors
clear
echo "Win10OS-cursors"
git clone https://github.com/yeyushengfan258/Win10OS-cursors.git /git/Win10OS-cursors/
cd /git/Win10OS-cursors/
./install.sh
sleep 3

##phinger-cursors
clear
echo "INSTALL phinger-cursors"
wget https://github.com/phisch/phinger-cursors/releases/latest/download/phinger-cursors-variants.tar.bz2
sudo tar -xjvf phinger-cursors-variants.tar.bz2 -C /usr/share/icons/
rm phinger-cursors-variants.tar.bz2 -rf
sleep 3

#Orchis Theme
clear
echo "Theme: Orchis Theme"

git clone https://github.com/vinceliuice/Orchis-kde.git /git/Orchis-kde
cd /git/Orchis-kde
./install.sh
sleep 3
git clone https://github.com/vinceliuice/Orchis-theme.git /git/Orchis-theme
cd /git/Orchis-theme
./install.sh
sleep 3


##Application Style: Klassy
clear
echo "Application Style: Klassy"
sudo nala install build-essential libkf5config-dev libkdecorations2-dev libqt5x11extras5-dev qtdeclarative5-dev extra-cmake-modules libkf5guiaddons-dev libkf5configwidgets-dev libkf5windowsystem-dev libkf5coreaddons-dev gettext cmake libkf5iconthemes-dev libkf5package-dev libkf5style-dev libkf5kcmutils-dev kirigami2-dev -y
sudo apt reinstall qtdeclarative5-dev
git clone https://github.com/paulmcauley/klassy.git /git/Klassy
cd /git/Klassy
sudo ./install.sh
sleep 3


#PAPIRUS
clear
echo "INSTALL PAPIRUS"
sudo sh -c "echo 'deb http://ppa.launchpad.net/papirus/papirus/ubuntu focal main' > /etc/apt/sources.list.d/papirus-ppa.list"

sudo apt-get install dirmngr -y
sudo gpg --no-default-keyring --keyring gnupg-ring:/etc/apt/trusted.gpg.d/papirus.gpg --keyserver keyserver.ubuntu.com --recv E58A9D36647CAE7F
sudo chmod 644 /etc/apt/trusted.gpg.d/papirus.gpg
sudo apt-get update
sudo nala update && sudo nala install papirus-icon-theme kvantum -y

okular ${dir}/customization_guide.pdf
sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
sudo nala update -y
reboot


