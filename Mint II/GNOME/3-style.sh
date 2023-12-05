#!/bin/bash
if [ "$(whoami)" != "root" ]
then
    sudo su -s "$0"
    exit
fi
dir="$(pwd)"

##THEMES

##Arc
sudo nala install arc-theme -y

#Fluent
sudo git clone https://github.com/vinceliuice/Fluent-gtk-theme /git/Fluent-gtk-theme/
cd /git/Fluent-gtk-theme/
sudo ./install.sh -t all -c -s -i
sudo ./install.sh --tweaks round
sudo ./install.sh --tweaks blur
sudo ./install.sh --tweaks square

sudo git clone https://github.com/refi64/stylepak.git /tmp/stylepak/
cd /tmp/stylepak/
sudo ./stylepak install-system

###### ICONS & CURSORS ###########

##Papirus
clear
echo "INSTALL PAPIRUS"
sudo add-apt-repository ppa:papirus/papirus -y
##Fix deprecated Key MINT issue
sudo mv /etc/apt/trusted.gpg /etc/apt/papirus.gpg
sudo ln -s /etc/apt/papirus.gpg /etc/apt/trusted.gpg.d/papirus.gpg
sudo nala update && sudo nala install papirus-icon-theme -y

#Pop_OS
sudo nala install pop-icon-theme -y

## Phinger-cursors
mkdir ~/.icons
sudo wget -cO- https://github.com/phisch/phinger-cursors/releases/latest/download/phinger-cursors-variants.tar.bz2 | tar xfj - -C ~/.icons

###### APPLY STYLE ###########

echo -e "Enable User theme extensions
Theme : Fluent-Dark-compact
Cursors : Phinger-cursors
Icons : Papirus Dark
Shell : Fluent-Dark-compact
Fonts : Ubuntu NF Book:10"







