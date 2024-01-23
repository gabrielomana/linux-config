#!/bin/bash
if [ "$(whoami)" != "root" ]
then
    sudo su -s "$0"
    exit
fi
dir="$(pwd)"

extra_apps="${dir}/sources/lists/extra_apps.list"

. "${dir}/sources/functions/zsh_starship"

# # POP_OS ICONS
# clear
# echo "POP_OS! ICONS"
# sudo wget https://github.com/gabrielomana/Pop_Os-Icons/raw/main/Pop_Os-Icons.tar.gz
# sudo tar -xvf Pop_Os-Icons.tar.gz -C /usr/share/icons/
# rm Pop_Os-Icons.tar.gz -rf
# sleep 3

# # Theme Windows
# clear
# echo "Theme: Win11OS"
# git clone https://github.com/yeyushengfan258/Win11OS-kde.git /git/Win11OS-kde
# cd /git/Win11OS-kde
# ./install.sh
# sleep 3

# # Win10OS-cursors
# clear
# echo "Win10OS-cursors"
# git clone https://github.com/yeyushengfan258/Win10OS-cursors.git /git/Win10OS-cursors/
# cd /git/Win10OS-cursors/
# ./install.sh
# sleep 3

# # phinger-cursors
# clear
# echo "INSTALL phinger-cursors"
# wget https://github.com/phisch/phinger-cursors/releases/latest/download/phinger-cursors-variants.tar.bz2
# sudo tar -xjvf phinger-cursors-variants.tar.bz2 -C /usr/share/icons/
# rm phinger-cursors-variants.tar.bz2 -rf
# sleep 3

# # Orchis Theme
# clear
# echo "Theme: Orchis Theme"
# git clone https://github.com/vinceliuice/Orchis-kde.git /git/Orchis-kde
# cd /git/Orchis-kde
# ./install.sh
# sleep 3
# git clone https://github.com/vinceliuice/Orchis-theme.git /git/Orchis-theme
# cd /git/Orchis-theme
# ./install.sh
# sleep 3

# # Application Style: Klassy
# clear
# echo "Application Style: Klassy"
#     debian_version=$(curl -sL https://deb.debian.org/debian/dists/stable/InRelease | grep "^Version:" | cut -d' ' -f2 | awk -F. '{print $1}')
#     echo "deb http://download.opensuse.org/repositories/home:/paul4us/Debian_$debian_version/ /" | sudo tee /etc/apt/sources.list.d/home:paul4us.list
#     curl -fsSL https://download.opensuse.org/repositories/home:paul4us/Debian_$debian_version/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_paul4us.gpg > /dev/null

# sudo nala update
# sudo nala install build-essential libkf5config-dev libkdecorations2-dev libqt5x11extras5-dev qtdeclarative5-dev extra-cmake-modules libkf5guiaddons-dev libkf5configwidgets-dev libkf5windowsystem-dev libkf5coreaddons-dev gettext cmake libkf5iconthemes-dev libkf5package-dev libkf5style-dev libkf5kcmutils-dev kirigami2-dev -y
# sudo apt reinstall qtdeclarative5-dev
# sudo nala install -y klassy
# sleep 3

# # PAPIRUS
# clear
# echo "INSTALL PAPIRUS"
# sudo apt install papirus-icon-theme *kvantum* -y

# okular ${dir}/customization_guide.pdf
# sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
# sudo nala update; sudo nala upgrade -y; sudo nala install -f;

# DOTFILES+ZSH+OHMYZSH+STARSHIP
clear
echo "ZSH"
sleep 3
clear
cd ${dir}
a=0
f=0
install_ZSH
