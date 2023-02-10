#!/bin/bash

if ! [ $(id -u) = 0 ]; then
echo "Run as root"
exit 1
fi

#POP_OS ICONS
clear
echo "COPY FILES"
sudo mkdir /usr/share/themes/Dew-theme_1.0
sudo cp style/custom.htm /usr/share/themes/Dew-theme_1.0/
sudo cp -rf style/custom-theme/ /usr/share/themes/Dew-theme_1.0/custom-theme
sudo cp Pop_Os-Icons.tar.gz /usr/share/themes/Dew-theme_1.0/
sleep 5

#Lightly
clear
echo "INSTALL LIGHTLY"
cd /usr/share/themes/Dew-theme_1.0

nala install cmake build-essential libkf5config-dev libkdecorations2-dev libqt5x11extras5-dev qtdeclarative5-dev extra-cmake-modules libkf5guiaddons-dev libkf5configwidgets-dev libkf5windowsystem-dev libkf5coreaddons-dev libkf5iconthemes-dev gettext qt3d5-dev -y

git clone --single-branch --depth=1 https://github.com/Luwx/Lightly.git /git/Lightly
cd Lightly && mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_INSTALL_LIBDIR=lib -DBUILD_TESTING=OFF ..
make
make install
sleep 5

#Lightly
clear
echo "INSTALL LIGHTLY SHADERS"
#LightlyShaders
cd /usr/share/themes/Dew-theme_1.0

nala install git cmake g++ gettext extra-cmake-modules qttools5-dev libqt5x11extras5-dev libkf5configwidgets-dev libkf5crash-dev libkf5globalaccel-dev libkf5kio-dev libkf5notifications-dev kinit-dev kwin-dev -y

git clone https://github.com/Luwx/LightlyShaders /git/LightlyShaders
cd LightlyShaders; mkdir qt5build; cd qt5build; cmake ../ -DCMAKE_INSTALL_PREFIX=/usr -DQT5BUILD=ON && make && make install && (kwin_x11 --replace &)
sleep 5


#Theme Windows
clear
echo "WINDOWS 11 THEME"
cd /usr/share/themes/Dew-theme_1.0

git clone https://github.com/yeyushengfan258/Win11OS-kde.git /git/Win11OS-kde
cd Win11OS-kde
./install.sh
sleep 5

#PAPIRUS
clear
echo "INSTALL PAPIRUS"
add-apt-repository ppa:papirus/papirus -y
##Fix deprecated Key MINT issue
mv /etc/apt/trusted.gpg /etc/apt/papirus.gpg
ln -s /etc/apt/papirus.gpg /etc/apt/trusted.gpg.d/papirus.gpg
nala update && nala install papirus-icon-theme -y
sleep 5


#ARC THEME &&  ARK-KDE  THEME
clear
echo "ARC THEME &&  ARK-KDE  THEME"
sudo nala install arc-theme arc-kde -y --install-recommends
sleep 5


#POP_OS ICONS
clear
echo "POP_OS ICONS"
cd /usr/share/themes/Dew-theme_1.0
tar -xf Pop_Os-Icons.tar.gz -C /usr/share/icons/
sleep 5

#FINAL STEPS
clear
echo "FINAL STEPS"
cd /usr/share/themes/Dew-theme_1.0
u="$(logname)"
runuser -l $u -c 'firefox custom.htm'
sleep 5
echo "DONE!"



