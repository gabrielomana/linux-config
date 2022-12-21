#!/bin/bash
if ! [ $(id -u) = 0 ]; then echo "Run as root" exit 1 fi

mkdir /usr/share/themes/myPlasmaTheme-1.0 
cp custom.htm /usr/share/themes/myPlasmaTheme-1.0/
cp -rf CUSTOMIZACION_archivos/ /usr/share/themes/myPlasmaTheme-1.0/CUSTOMIZACION_archivos
cp Pop_Os-Icons.tar.gz /usr/share/themes/myPlasmaTheme-1.0/
cp Gabriel.profile /usr/share/themes/myPlasmaTheme-1.0/

#Lightly
cd /usr/share/themes/myPlasmaTheme-1.0

apt install -y cmake build-essential libkf5config-dev libkdecorations2-dev libqt5x11extras5-dev qtdeclarative5-dev extra-cmake-modules libkf5guiaddons-dev libkf5configwidgets-dev libkf5windowsystem-dev libkf5coreaddons-dev libkf5iconthemes-dev gettext qt3d5-dev

git clone --single-branch --depth=1 https://github.com/Luwx/Lightly.git
cd Lightly && mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_TESTING=OFF ..
make
make install

#LightlyShaders
cd /usr/share/themes/myPlasmaTheme-1.0

apt install -y git cmake g++ gettext extra-cmake-modules qttools5-dev libqt5x11extras5-dev libkf5configwidgets-dev libkf5crash-dev libkf5globalaccel-dev libkf5kio-dev libkf5notifications-dev kinit-dev kwin-dev 

git clone https://github.com/Luwx/LightlyShaders
cd LightlyShaders; mkdir qt5build; cd qt5build; cmake ../ -DCMAKE_INSTALL_PREFIX=/usr -DQT5BUILD=ON && make && make install && (kwin_x11 --replace &)

#Theme Windows
cd /usr/share/themes/myPlasmaTheme-1.0

git clone https://github.com/yeyushengfan258/Win11OS-kde.git
cd Win11OS-kde
./install.sh

#PAPIRUS
add-apt-repository ppa:papirus/papirus -y
##Fix deprecated Key MINT issue
mv /etc/apt/trusted.gpg /etc/apt/papirus.gpg
ln -s /etc/apt/papirus.gpg /etc/apt/trusted.gpg.d/papirus.gpg
apt update && apt install -y papirus-icon-theme

#ARC THEME &&  ARK-KDE  THEME
sudo apt-get install -y --install-recommends arc-theme arc-kde

#POP_OS ICONS
cd /usr/share/themes/myPlasmaTheme-1.0
tar -xf Pop_Os-Icons.tar.gz -C /usr/share/icons/
clear
