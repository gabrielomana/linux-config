#!/bin/bash
clear
sudo apt-get purge -y --auto-remove mate-desktop mate-* lightdm
sudo apt-get purge -y --auto-remove ubuntu-mate-artwork ubuntu-mate-default-settings ubuntu-mate-icon-themes ubuntu-mate-themes ubuntu-mate-wallpapers* caja-open-terminal libmate-desktop-2-17 plymouth-theme-ubuntu-mate-logo plymouth-theme-ubuntu-mate-text caja-eiciel caja-extensions-common caja-gtkhash caja-sendto caja-wallpaper libcaja-extension1 engrampa* plank
dpkg --purge mate-* --force-all
sudo rm /var/lib/apt/lists/*MATE*
sudo apt purge libreoffice* -y
sudo apt-get autoremove -y
clear
#REMOVE SNAP/ADD FLATPACK

#remove snap service (existing sanp applications must be uninstalled first)
sudo apt autoremove --purge snapd -y
sudo rm -rf ~/snap
sudo rm -rf /var/cache/snapd
sudo apt purge snapd
sudo apt-mark hold snapd
echo -e "Package: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee /etc/apt/preferences.d/nosnap.pref
sudo apt update -y

#limpiar y arreglar paquetes rotos
sudo apt-get update –fix-missing
sudo apt-get install -f
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo dpkg --configure -a

#install flatpak service
sudo apt install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
clear

#########################################################################

#REPOS
###### REPOSITORIES

####Vanilla
sudo add-apt-repository ppa:ubuntustudio-ppa/backports -y
sudo add-apt-repository ppa:kisak/kisak-mesa -y
sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo add-apt-repository multiverse -y
sudo add-apt-repository ppa:mozillateam/ppa -y

#GNOME
#Ubunutu Minimal
#sudo apt install ubuntu-desktop-minimal language-pack-gnome-es language-pack-gnome-es-base gnome-user-docs gnome-user-docs-es plymouth-theme-ubuntu-logo  -y
#GNOME Vanilla Minimal
sudo apt install vanilla-gnome-desktop language-pack-gnome-es language-pack-gnome-es-base gnome-user-docs gnome-user-docs-es plymouth-theme-ubuntu-logo  -y

sudo apt install gedit evince file-roller -y
#sudo apt-get -y install language-pack-es-base
clear
#sudo dpkg-reconfigure locales

sudo systemctl set-default graphical.target
sudo systemctl enable gdm3


sudo apt install -t 'o=LP-PPA-mozillateam' firefox -y
echo -e "Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501" | sudo tee /etc/apt/preferences.d/mozillateamppa.pref
sudo apt update -y

# CORE APPS
sudo apt install -y \
build-essential software-properties-gtk gcc make perl g++ \
wget curl git gdebi \
dconf dconf-editor cabextract xorg-x11-font-utils fontconfig cmake anacron \
software-properties-common ca-certificates gnupg2 ubuntu-keyring apt-transport-https \
default-jre nodejs cargo \
ubuntu-drivers-common \
ubuntu-restricted-extras \
gstreamer1.0-libav ffmpeg x264 x265 h264enc mencoder mplayer \
cabextract \
samba \
screen \
util-linux* apt-utils bash-completion openssl finger dos2unix nano sed numlockx
sudo apt clean -y
clear

###### Purga
clear
sudo apt remove postfix -y && apt purge postfix -y
sudo dpkg-reconfigure postfix
sudo purge libreoffice libreoffice-\* -y
sudo apt autoremove -y
clear
 "*************************************************************************************"
sleep 7


###### UPDATE
clear
sudo apt update -y && sudo apt upgrade -y && sudo apt full-upgrade -y
echo "*************************************************************************************"
sleep 7
reboot



