#!/bin/bash
sudo mkdir /usr/share/themes/myPlasmaTheme-1.0 
sudo cp custom.html /usr/share/themes/myPlasmaTheme-1.0/
sudo cp Pop_Os-Icons.tar.gz /usr/share/themes/myPlasmaTheme-1.0/
sudo cp Gabriel.profile /usr/share/themes/myPlasmaTheme-1.0/

#Lightly
cd /usr/share/themes/myPlasmaTheme-1.0

sudo apt install -y cmake build-essential libkf5config-dev libkdecorations2-dev libqt5x11extras5-dev qtdeclarative5-dev extra-cmake-modules libkf5guiaddons-dev libkf5configwidgets-dev libkf5windowsystem-dev libkf5coreaddons-dev libkf5iconthemes-dev gettext qt3d5-dev

git clone --single-branch --depth=1 https://github.com/Luwx/Lightly.git /
cd Lightly && mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_TESTING=OFF ..
make
sudo make install

#LightlyShaders
cd /usr/share/themes/myPlasmaTheme-1.0

sudo apt install -y git cmake g++ gettext extra-cmake-modules qttools5-dev libqt5x11extras5-dev libkf5configwidgets-dev libkf5crash-dev libkf5globalaccel-dev libkf5kio-dev libkf5notifications-dev kinit-dev kwin-dev 

git clone https://github.com/Luwx/LightlyShaders
cd LightlyShaders; mkdir qt5build; cd qt5build; cmake ../ -DCMAKE_INSTALL_PREFIX=/usr -DQT5BUILD=ON && make && sudo make install && (kwin_x11 --replace &)

#Theme Windows
cd /usr/share/themes/myPlasmaTheme-1.0
git clone https://github.com/yeyushengfan258/We10XOS-kde.git
./We10XOS-kde/instal.sh

#PAPIRUS
cd /usr/share/themes/myPlasmaTheme-1.0

sudo add-apt-repository ppa:papirus/papirus -y
##Fix deprecated Key MINT issue
sudo mv /etc/apt/trusted.gpg /etc/apt/papirus.gpg
sudo ln -s /etc/apt/papirus.gpg /etc/apt/trusted.gpg.d/papirus.gpg

sudo apt update && sudo apt install -y papirus-icon-theme

#ORCHIS KDE
cd /usr/share/themes/myPlasmaTheme-1.0
git clone https://github.com/Luwx/LightlyShadershttps://github.com/vinceliuice/Orchis-kde.git
cd Orchis-kde
./install.sh

#ORCHIS GTK
cd /usr/share/themes/myPlasmaTheme-1.0
git clone https://github.com/vinceliuice/Orchis-theme.git
cd Orchis-theme
./install.sh

#POP_OS ICONS
cd /usr/share/themes/myPlasmaTheme-1.0

firefox custom.html

sudo systemctl disable sddm
sudo systemctl enable lightdm
sudo systemctl enable lightdm-plymouth
cp Gabriel.profile ~/.local/share/konsole
reboot

