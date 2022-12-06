!/bin/bash
clear
#language

clear
sudo apt clean
sudo apt-get -y install language-pack-es
sudo apt-get -y install language-pack-es-base
cd /usr/share/locales/
sudo ./install-language-pack es_ES
echo -e "LANG=\"es_ES.UTF-8\"\nLC_ALL=\"es_ES.UTF-8\"\nLANGUAGE=\"es_ES\"" | sudo tee /etc/environment
echo -e "LANG=\"es_ES.UTF-8\"\nLC_ALL=\"es_ES.UTF-8\"\nLANGUAGE=\"es_ES\"" | sudo tee /etc/default/locale
echo -e "es_ES.UTF-8 UTF-8\nen_US.UTF-8 UTF-8" | sudo tee /var/lib/locales/supported.d/local
sudo dpkg-reconfigure locales

#GNOME
#Ubunutu Minimal
#sudo apt install ubuntu-desktop-minimal language-pack-gnome-es language-pack-gnome-es-base gnome-user-docs gnome-user-docs-es plymouth-theme-ubuntu-logo  -y
#GNOME Vanilla Minimal
sudo apt install vanilla-gnome-desktop gnome-session gnome-terminal language-pack-gnome-es language-pack-gnome-es-base gnome-user-docs gnome-user-docs-es plymouth-theme-ubuntu-logo lightdm -y
sudo apt install gedit evince file-roller -y


clear
sudo apt-get purge -y --auto-remove mate-desktop mate-* lightdm
sudo apt-get purge -y --auto-remove ubuntu-mate-artwork ubuntu-mate-default-settings ubuntu-mate-icon-themes ubuntu-mate-themes ubuntu-mate-wallpapers* caja-open-terminal libmate-desktop-2-17 plymouth-theme-ubuntu-mate-logo plymouth-theme-ubuntu-mate-text caja-eiciel caja-extensions-common caja-gtkhash caja-sendto caja-wallpaper libcaja-extension1 engrampa* plank
sudo apt purge libreoffice* -y
sudo apt-get autoremove -y

#remove snap service (existing sanp applications must be uninstalled first)
sudo apt autoremove --purge snapd -y
sudo rm -rf ~/snap
sudo rm -rf /var/cache/snapd
sudo apt purge snapd
sudo apt-mark hold snapd
echo -e "Package: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee /etc/apt/preferences.d/nosnap.pref
sudo apt update -y

#sudo apt-get -y install language-pack-es-base
clear
#sudo dpkg-reconfigure locales

sudo systemctl set-default graphical.target
sudo systemctl enable gdm3

clear
#REPOS
###### REPOSITORIES

####Vanilla
sudo add-apt-repository ppa:ubuntustudio-ppa/backports -y
sudo add-apt-repository ppa:kisak/kisak-mesa -y
sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo add-apt-repository multiverse -y
sudo add-apt-repository ppa:mozillateam/ppa

sudo apt install -t 'o=LP-PPA-mozillateam' firefox -y
echo -e "Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501" | sudo tee /etc/apt/preferences.d/mozillateamppa.pref
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
screen bleachbit \
util-linux* apt-utils bash-completion openssl finger dos2unix nano sed numlockx
sudo apt clean -y
sudo bleachbit
reboot
clear
