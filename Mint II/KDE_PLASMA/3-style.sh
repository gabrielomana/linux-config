#!/bin/bash
if [ "$(whoami)" != "root" ]; then
    sudo su -s "$0"
    exit
fi

dir="$(pwd)"
extra_apps="${dir}/sources/lists/extra_apps.list"

. "${dir}/sources/functions/zsh_starship"

# Función para instalar temas e iconos
install_theme() {
    clear
    echo "Installing $1"
    git clone $2 /git/$1
    cd /git/$1
    ./install.sh
    sleep 3
}

# POP_OS ICONS
install_theme "Pop_Os-Icons" https://github.com/gabrielomana/Pop_Os-Icons.git

# Theme Windows
install_theme "Win11OS-kde" https://github.com/yeyushengfan258/Win11OS-kde.git

# Win10OS-cursors
install_theme "Win10OS-cursors" https://github.com/yeyushengfan258/Win10OS-cursors.git

# phinger-cursors
clear
echo "INSTALL phinger-cursors"
wget https://github.com/phisch/phinger-cursors/releases/latest/download/phinger-cursors-variants.tar.bz2
sudo tar -xjvf phinger-cursors-variants.tar.bz2 -C /usr/share/icons/
rm phinger-cursors-variants.tar.bz2 -rf
sleep 3

# Orchis Theme
install_theme "Orchis-kde" https://github.com/vinceliuice/Orchis-kde.git
install_theme "Orchis-theme" https://github.com/vinceliuice/Orchis-theme.git

# Application Style: Klassy
install_theme "Klassy" https://github.com/paulmcauley/klassy.git
sudo apt install build-essential libkf5config-dev libkdecorations2-dev libqt5x11extras5-dev qtdeclarative5-dev extra-cmake-modules libkf5guiaddons-dev libkf5configwidgets-dev libkf5windowsystem-dev libkf5coreaddons-dev gettext cmake libkf5iconthemes-dev libkf5package-dev libkf5style-dev libkf5kcmutils-dev kirigami2-dev -y
sudo apt reinstall qtdeclarative5-dev
cd /git/Klassy
sudo ./install.sh
sleep 3

# PAPIRUS
clear
echo "INSTALL PAPIRUS"
sudo apt install papirus-icon-theme *kvantum* -y

# Open customization guide in Okular
okular ${dir}/customization_guide.pdf

# Clean up and update
sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
sudo nala update; sudo nala upgrade -y; sudo nala install -f;

# DOTFILES+ZSH+OHMYZSH+STARSHIP
clear
echo "ZSH"
sleep 3
clear
cd ${dir}
a=0
f=0
install_ZSH
