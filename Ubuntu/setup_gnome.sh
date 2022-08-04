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
build-essential software-properties-gtk gcc make perl g++ \
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

###Nautilis>Nemo

sudo echo "deb http://packages.linuxmint.com una main upstream import backport" > /etc/apt/sources.list.d/linux-mint.list  
sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A6616109451BBBF2
sudo apt reinstall libxapp1 -y
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/mint.gpg
sudo apt install linuxmint-keyring -y
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
#sudo apt -y install python-nemo nemo-compare nemo-terminal nemo-fileroller cinnamon-l10n mint-translations --install-recommends

sudo sh -c 'echo "Package: *\nPin: release o=Ubuntu\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo "Package: *\nPin: release o=LP-PPA-ubuntustudio-ppa-backports\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo "Package: *\nPin: release o=LLP-PPA-pipewire-debian-pipewire-upstream\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo "Package: *\nPin: release o=LP-PPA-kisak-kisak-mesa\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo "Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo "Package: *\nPin: release o=LP-PPA-graphics-drivers\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo "Package: *\nPin: release o=linuxmint\nPin-Priority: 100\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo apt update
clear
sudo apt install nemo -y


sudo apt purge nautilus gnome-shell-extension-desktop-icons -y

xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.nemo.desktop show-desktop-icons true
gsettings set org.nemo.desktop use-desktop-grid true
echo -e "[Desktop Entry]\nType=Application\nName=Files\nExec=nemo-desktop\nOnlyShowIn=GNOME;Unity;\nX-Ubuntu-Gettext-Domain=nemo" | sudo tee /etc/xdg/autostart/nemo-autostart.desktop
sudo apt -y install python-nemo nemo-compare nemo-terminal nemo-fileroller cinnamon-l10n mint-translations --install-recommends

sudo apt install chrome-gnome-shell gnome-tweaks gnome-shell-extensions gnome-software -y
sudo apt-get update –fix-missing
sudo apt-get install -f
sudo apt-get autoremove -y
sudo dpkg --configure -a
sudo apt-get clean -y
clear
sudo apt update -y && sudo apt upgrade -y && sudo apt full-upgrade -y
clear
sudo dpkg-reconfigure locales
export LANG=es_ES.UTF-8
clear
reboot



