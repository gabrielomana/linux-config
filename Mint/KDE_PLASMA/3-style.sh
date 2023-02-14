#!/bin/bash
if [ "$(whoami)" != "root" ]
then
    sudo su -s "$0"
    exit
fi
dir="$(pwd)"

#POP_OS ICONS
clear
echo "COPY FILES"
sudo mkdir /usr/share/themes/Dew-theme_1.0
sudo cp style/custom-theme.htm /usr/share/themes/Dew-theme_1.0/
sudo cp -rf style/custom-theme/ /usr/share/themes/Dew-theme_1.0/custom-theme/
sudo cp style/Pop_Os-Icons.tar.gz /usr/share/themes/Dew-theme_1.0/
sleep 3

#Theme Windows
clear
echo "Theme: Win11OS"

git clone https://github.com/yeyushengfan258/Win11OS-kde.git /git/Win11OS-kde
cd /git/Win11OS-kde
./install.sh
sleep 5

#Windows Cursors
clear
echo "INSTALL PAPIRUS"
git clone https://github.com/yeyushengfan258/Win10OS-cursors.git /git/Win10OS-cursors/
cd /git/Win10OS-cursors/
./install.sh
sleep 5

# #phinger-cursors
clear
echo "INSTALL phinger-cursors"
wget https://github.com/phisch/phinger-cursors/releases/latest/download/phinger-cursors-variants.tar.bz2
sudo tar -xjvf phinger-cursors-variants.tar.bz2 -C /usr/share/icons/
rm phinger-cursors-variants.tar.bz2 -rf
sleep 5

sleep 5

#Orchis Theme
clear
echo "Theme: Orchis Theme"

git clone https://github.com/vinceliuice/Orchis-kde.git /git/Orchis-kde
cd /git/Orchis-kde
./install.sh
sleep 5
git clone https://github.com/vinceliuice/Orchis-theme.git /git/Orchis-theme
cd /git/Orchis-theme
./install.sh
sleep 5


##Application Style: Klassy
clear
echo "Application Style: Klassy"
sudo nala install build-essential libkf5config-dev libkdecorations2-dev libqt5x11extras5-dev qtdeclarative5-dev extra-cmake-modules libkf5guiaddons-dev libkf5configwidgets-dev libkf5windowsystem-dev libkf5coreaddons-dev gettext cmake libkf5iconthemes-dev libkf5package-dev libkf5style-dev libkf5kcmutils-dev kirigami2-dev -y
sudo apt reinstall qtdeclarative5-dev
git clone https://github.com/paulmcauley/klassy.git /git/Klassy
cd /git/Klassy
sudo ./install.sh
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


# #ARC THEME &&  ARK-KDE  THEME
# clear
# echo "ARC THEME &&  ARK-KDE  THEME"
# sudo nala install arc-theme arc-kde -y --install-recommends
# sleep 5


#POP_OS ICONS
clear
echo "POP_OS ICONS"
cd /usr/share/themes/Dew-theme_1.0
tar -xf Pop_Os-Icons.tar.gz -C /usr/share/icons/
sleep 5

if [ "$(whoami)" == "root" ]
then
    exit
fi
#FINAL STEPS
# clear
# echo "FINAL STEPS"
# cd /usr/share/themes/Dew-theme_1.0
# u=$(logname)
# runuser -l $u -c 'firefox custom.htm'
# sleep 5
# echo "DONE!"
