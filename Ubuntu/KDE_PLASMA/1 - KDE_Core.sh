#!/bin/bash

#UNINSTALL XFCE
clear
sudo apt purge --autoremove mint-meta-xfce thunar thunar* ^xfce4* xfce4* xfconf xfdesktop4 xfwm4 mugshot -y
clear
sudo apt purge --autoremove libreoffice* simple-scan drawing pix thunderbird* transmission* hexchat xviewer gnome-calculator seahorse gnome-disk* xed exo-utils mintstick file-roller gucharmap gnome-logs gnome-font-viewer xreader warpinator celluloid pavucontrol rhythmbox thingy \
compiz* gnome-disk* metacity gcr* baobab mintinstall* mintupdate mintbackup system-config-printer mintreport* gdebi* gnome-logs menulibre celluloid rhythmbox -y
clear
sudo apt-get -f install
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get update --fix-missing
sudo apt-get install -f
sudo rm /usr/share/xfce4/ -rf
sudo rm /usr/share/thunar/ -rf
clear

#KDE PLASMA
echo "KDE PLASMA"
sudo apt -y install tasksel
sudo tsksell install kde-desktop
sudo apt install -y plasma-workspace-wayland --install-recommends
sudo systemctl set-default graphical.target

# CLEAN PLASMA
clear
echo "UNINSTALL"
sudo apt purge --autoremove libreoffice* -y

sudo apt purge --autoremove \
gwenview \
akregator \
kmail \
konversation \
krfb \
kmahjongg \
kmines \
dragonplayer \
elisa \
korganizer \
kontact \
kpat \
gimp \
k3b \
apper \
kmouth \
konqueror \
muon \
kontrast \
libreoffice-base-core \
libreoffice-common \
libreoffice-core \
libreoffice-math \
libreoffice-style-breeze \
libreoffice-style-colibre \
libreoffice-writer -y

sudo apt -y autoremove
sudo apt-get -f install
sudo apt-get clean
sudo apt-get autoclean

echo "*************************************************************************************"

#EXTRA APPS KDE
clear
echo -e "APPS KDE\n"
sudo apt install -y kde-plasma-desktop
sudo apt install -y \
kcalc \
kate \
kmix \
knotes \
kde-config-cron* \
krename \
kid3 \
kcolorchooser \
kdenetwork-filesharing \
kfind \
kget \
kinfocenter \
kio-extras \
krdc \
kaccounts-providers \
kio-gdrive \
kbackup \
plasma-nm plasma-pa plasma-widget* ffmpegthumbs

sudo apt purge kwrite -y

###### REPOSITORIES
echo "REPOSITORIES"

sudo add-apt-repository multiverse -y

sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/nvidia.gpg

sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/grub-customizer.gpg

sudo add-apt-repository ppa:appimagelauncher-team/stable -y
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/appimagelauncher.gpg


sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/keys.gpg

sudo add-apt-repository ppa:kubuntu-ppa/backports -y
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/kubuntu.gpg

sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/pipewire.gpg

sudo add-apt-repository ppa:pipewire-debian/wireplumber-upstream -y
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/wireplumber.gpg

# sudo add-apt-repository ppa:kisak/kisak-mesa -y
# sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
# sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/kisak-mesa.gpg


clear
sudo apt update -y

sudo apt install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo apt install plasma-discover-backend-flatpak -y


echo -e "CORE\n"
sudo apt install -y \
build-essential gcc make perl g++ npm \
wget curl git gdebi \
dconf* cabextract fontconfig cmake anacron \
software-properties-common ca-certificates gnupg2 ubuntu-keyring apt-transport-https \
default-jre nodejs cargo \
ubuntu-drivers-common \
ubuntu-restricted-extras \
gstreamer1.0-libav ffmpeg x264 x265 mencoder lame mplayer \
samba \
screen bleachbit \
util-linux* apt-utils bash-completion openssl finger dos2unix nano sed numlockx \
unrar p7zip unzip ark

sudo apt remove postfix -y && apt purge postfix -y
sudo apt autoremove -y

sudo apt install -y libfdk-aac2 libldacbt-{abr,enc}2 libopenaptx0
sudo apt install -y gstreamer1.0-pipewire libpipewire-0.3-{0,dev,modules} libspa-0.2-{bluetooth,dev,jack,modules} pipewire{,-{audio-client-libraries,pulse,bin,locales,tests}}
sudo apt install -y pipewire-doc
sudo apt-get install -y wireplumber{,-doc} gir1.2-wp-0.4 libwireplumber-0.4-{0,dev}
systemctl --user --now disable pulseaudio.{socket,service}
systemctl --user mask pulseaudio
systemctl --user --now enable pipewire{,-pulse}.{socket,service}
systemctl --user --now enable wireplumber.service


#SYSTEM
clear
echo -e "SYSTEM\n"
sudo apt install -y \
v4l2loopback-utils \
neofetch \
printer-driver-cups-pdf \
grub-customizer \
tesseract-ocr-spa gimagereader

sudo npm install -g hblock
hblock

#TOOLS
clear
echo -e "TOOLS\n"
sudo apt install -y \
digikam \
timeshift \
ksnip \
appimagelauncher \
featherpad

#MULTIMEDIA
clear
echo -e "MULTIMEDIA\n"
sudo apt remove gpac -y

sudo apt install -y \
vlc \
audacity \
audacious \
nomacs 

#OFIMATICA  ******************************************#
clear
echo -e "OFIMATICA\n"
sudo apt install -y pdfarranger okular 

clear
echo -e "FULL UPDATE\n"
sudo apt clean -y
sudo apt update -y && sudo apt upgrade -y && sudo apt full-upgrade -y
sudo aptitude safe-upgrade -y
sudo reboot
