#!/bin/bash
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

#Repos MINT
sudo sh -c 'echo "deb http://packages.linuxmint.com/ uma main" >> /etc/apt/sources.list.d/mint.list'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6616109451BBBF2
sudo apt reinstall libxapp1 -y
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/mint.gpg
sudo apt update
sudo apt-get install linuxmint-keyring -y
#******************


#GNOME
#Ubunutu Minimal
sudo apt install ubuntu-desktop-minimal -y
#GNOME Vanilla Minimal
#sudo apt install vanilla-gnome-desktop

sudo apt install gedit evince file-roller lightdm -y
sudo apt-get -y install language-pack-es-base
clear
sudo dpkg-reconfigure locales

sudo systemctl set-default graphical.target
sudo systemctl enable lightdm


###Nautilis
sudo apt purge nautilus gnome-shell-extension-desktop-icons -y
sudo apt install nemo -y
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.nemo.desktop show-desktop-icons true
gsettings set org.nemo.desktop use-desktop-grid true
echo -e "[Desktop Entry]\nType=Application\nName=Files\nExec=nemo-desktop\nOnlyShowIn=GNOME;Unity;\nX-Ubuntu-Gettext-Domain=nemo" | sudo tee /etc/xdg/autostart/nemo-autostart.desktop

sudo apt install mint-dev-tools -y
sudo apt-get install libglib2.0-dev -y
sudo mkdir -p /git/
sudo mkdir -p /git/nemo-extensions/
sudo git clone https://github.com/linuxmint/nemo-extensions /git/nemo-extensions/
cd /git/nemo-extensions/
sudo git pull origin master
sudo ./build nemo-python nemo-terminal nemo-compare
sudo dpkg -i python-nemo*.deb
sudo apt install gir1.2-xapp-1.0 -y
sudo dpkg -i nemo-terminal*.deb nemo-compare*.deb
sudo rm *.deb -rf
cd -

sudo apt install chrome-gnome-shell gnome-tweaks gnome-shell-extensions gnome-software -y
sudo apt-get update –fix-missing
sudo apt-get install -f
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo dpkg --configure -a


sudo apt install -t 'o=LP-PPA-mozillateam' firefox -y
echo -e "Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501" | sudo tee /etc/apt/preferences.d/mozillateamppa.pref
sudo apt update -y

# CORE APPS
sudo apt install -y \
build-essential \
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
reboot
