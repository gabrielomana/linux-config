#!/bin/bash
clear
sudo apt -y purge --autoremove mint-meta-xfce thunar thunar* xfce4* xfconf xfdesktop4 xfwm4 mugshot
clear
sudo apt -y purge --autoremove libreoffice* simple-scan drawing pix thunderbird* transmission* hexchat xviewer gnome-calculator seahorse gnome-disk* xed exo-utils mintstick file-roller gucharmap gnome-logs gnome-font-viewer xreader warpinator celluloid pavucontrol rhythmbox thingy \
compiz* gnome-disk* metacity gcr* baobab mintinstall* mintupdate mintbackup system-config-printer mintreport* gdebi* gnome-logs
clear
sudo apt-get update --fix-missing
sudo apt-get install -f

#GNOME Vanilla Minimal
echo "GNOME Vanilla Minimal"
sudo apt install -y vanilla-gnome-desktop gnome-session xinit gnome-terminal gedit lightdm language-pack-gnome-es language-pack-gnome-es-base gnome-user-docs gnome-user-docs-es plymouth-theme-ubuntu-logo
sudo apt install -y build-essential software-properties-gtk gcc make perl sed git nano g++ npm file-roller

# clear
# CLEAN GNOME
echo "CLEAN GNOME"
sudo apt purge libreoffice* transmission* gnome-maps gnome-weather gnome-contacts gnome-music gnome-photos eog gpac totem* simple-scan gnome-mahjongg gnome-mines aisleriot gnome-sudoku -y
sudo apt remove postfix -y && apt purge postfix -y
sudo apt autoremove -y
sudo apt-get update --fix-missing
sudo apt-get install -f
sudo systemctl set-default graphical.target


clear
# REPOSITORIES
echo "REPOSITORIES"

####Vanilla
#sudo add-apt-repository ppa:kisak/kisak-mesa -y
sudo add-apt-repository multiverse -y
sudo add-apt-repository ppa:ubuntustudio-ppa/backports -y
sudo add-apt-repository ppa:mozillateam/ppa -y

sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo add-apt-repository ppa:appimagelauncher-team/stable -y
#sudo add-apt-repository ppa:ubuntucinnamonremix/all -y

sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/keys.gpg
clear
sudo apt update -y


echo -e "CORE\n"
sudo apt install -y \
build-essential software-properties-gtk gcc make perl g++ npm \
wget curl git gdebi \
dconf* cabextract fontconfig cmake anacron \
software-properties-common ca-certificates gnupg2 ubuntu-keyring apt-transport-https \
default-jre nodejs cargo \
ubuntu-drivers-common \
ubuntu-restricted-extras \
gstreamer1.0-libav ffmpeg x264 x265 h264enc mencoder mplayer \
cabextract \
samba \
screen bleachbit \
util-linux* apt-utils bash-completion openssl finger dos2unix nano sed numlockx \
unrar p7zip unzip file-roller

sudo apt remove postfix -y && apt purge postfix -y
sudo apt autoremove -y


#SYSTEM
clear
echo -e "SYSTEM\n"
sudo apt install -y \
v4l2loopback-utils \
neofetch \
printer-driver-cups-pdf \
grub-customizer \
tesseract-ocr-spa gImageReader* \
policycoreutils-gui firewall-config

sudo npm install -g hblock
hblock

#TOOLS
clear
echo -e "TOOLS\n"
sudo apt install -y \
unrar p7zip unzip \
gedit \
cheese \
timeshift \
flameshot \
tilix \
appimagelauncher

sudo gsettings set org.gnome.desktop.default-applications.terminal exec 'tilix'

#MULTIMEDIA
clear
echo -e "MULTIMEDIA\n"
sudo apt install -y \
smplayer \
audacity \
shotwell

# # #OFIMATICA  ******************************************#
# # clear
# # echo -e "OFIMATICA\n"
# # sudo apt install -y pdfarranger evince 

#NAUTILUS > NEMO
clear
echo -e "NAUTILUS > NEMO\n"
sudo apt -y install python-nemo nemo-compare nemo-terminal nemo-fileroller cinnamon-l10n mint-translations --install-recommends

sudo apt purge nautilus gnome-shell-extension-desktop-icons -y
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.nemo.desktop show-desktop-icons true
gsettings set org.nemo.desktop use-desktop-grid true
echo -e "[Desktop Entry]\nType=Application\nName=Files\nExec=nemo-desktop\nOnlyShowIn=GNOME;Unity;\nX-Ubuntu-Gettext-Domain=nemo" | sudo tee /etc/xdg/autostart/nemo-autostart.desktop

sudo apt install chrome-gnome-shell gnome-tweaks gnome-shell-extensions gnome-software -y
sudo apt-get update –fix-missing
sudo apt-get install -f
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo dpkg --configure -a


clear
echo -e "FULL UPDATE\n"
sudo apt clean -y
sudo apt update -y && sudo apt upgrade -y && sudo apt full-upgrade -y
sudo reboot


