#!/bin/bash
clear
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
sudo apt install ubuntu-desktop-minimal -y
#GNOME Vanilla Minimal
#sudo apt install vanilla-gnome-desktop

sudo apt install gedit evince file-roller lightdm -y
#sudo apt-get -y install language-pack-es-base
clear
#sudo dpkg-reconfigure locales

sudo systemctl set-default graphical.target
sudo systemctl enable lightdm


sudo apt install -t 'o=LP-PPA-mozillateam' firefox -y
sudo apt update -y

# CORE APPS
sudo apt install -y \
build-essential software-properties-gtk gcc make perl g++\
wget curl git gdebi \
software-properties-common ca-certificates gnupg2 ubuntu-keyring apt-transport-https \
default-jre nodejs cargo \
ubuntu-drivers-common \
ubuntu-restricted-extras \
gstreamer1.0-libav ffmpeg x264 x265 h264enc mencoder mplayer \
cabextract \
samba \
screen \
util-linux-user openssl finger dos2unix nano sed numlockx
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

#Repos MINT
clear
sudo sh -c 'echo "deb http://packages.linuxmint.com/ vanessa main" >> /etc/apt/sources.list.d/mint_vanessa.list'
sudo sh -c 'echo "deb http://packages.linuxmint.com/ vanessa upstream" >> /etc/apt/sources.list.d/mint_vanessa.list'
sudo sh -c 'echo "deb http://packages.linuxmint.com/ vanessa backport" >> /etc/apt/sources.list.d/mint_vanessa.list'
sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A1715D88E1DF1F24 40976EAF437D05B5 3B4FE6ACC0B21F32 A6616109451BBBF2
sudo apt reinstall libxapp1 -y
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/mint.gpg
sudo apt-get install linuxmint-keyring -y
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done

sudo sh -c 'echo -e "Package: *\nPin: release o=Ubuntu\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo -e "Package: *\nPin: release o=LP-PPA-ubuntustudio-ppa-backports\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo -e "Package: *\nPin: release o=LLP-PPA-pipewire-debian-pipewire-upstream\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo -e "Package: *\nPin: release o=LP-PPA-kisak-kisak-mesa\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo -e "Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo -e "Package: *\nPin: release o=LP-PPA-graphics-drivers\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo -e "Package: *\nPin: release o=linuxmint\nPin-Priority: 100\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo apt update
#******************
