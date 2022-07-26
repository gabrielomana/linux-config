#!/bin/bash
clear
sudo apt purge --autoremove mint-meta-xfce thunar thunar* ^xfce4* xfconf xfdesktop4 xfwm4 mugshot -y
clear
sudo apt purge --autoremove libreoffice* simple-scan drawing pix thunderbird* transmission* hexchat xviewer gnome-calculator seahorse gnome-disk* xed exo-utils mintstick file-roller gucharmap gnome-logs gnome-font-viewer xreader warpinator celluloid pavucontrol rhythmbox thingy \
compiz* gnome-disk* metacity gcr* baobab mintinstall* mintupdate mintbackup system-config-printer mintreport* gdebi* gnome-logs -y
clear
sudo apt-get -f install
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get update --fix-missing
sudo apt-get install -f
sudo rm /usr/share/xfce4/ -rf
sudo rm /usr/share/thunar/ -rf
clear

#GNOME Vanilla Minimal
echo "GNOME Vanilla Minimal"
sudo apt install -y vanilla-gnome-desktop gedit language-pack-gnome-es language-pack-gnome-es-base gnome-user-docs gnome-user-docs-es plymouth-theme-ubuntu-logo
sudo apt install -y build-essential software-properties-gtk gcc make perl sed git nano g++ npm file-roller lightdm-gtk-greeter*

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

clear
# REPOSITORIES
echo "REPOSITORIES"

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

sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y
sudo add-apt-repository ppa:pipewire-debian/wireplumber-upstream -y
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/pipewire_wireplumber.gpg

# sudo add-apt-repository ppa:kisak/kisak-mesa -y
# sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
# sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/kisak-mesa.gpg

clear
sudo apt update -y

sudo apt install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo apt install -y gnome-software-plugin-flatpak


echo -e "CORE\n"
sudo apt install -y \
build-essential gcc make perl g++ npm \
wget curl git gdebi \
dconf* cabextract fontconfig cmake anacron \
software-properties-common ca-certificates gnupg2 ubuntu-keyring apt-transport-https \
default-jre nodejs cargo libssl-dev pkg-config \
ubuntu-drivers-common \
ubuntu-restricted-extras \
gstreamer1.0-libav ffmpeg x264 x265 lame mencoder mplayer \
samba \
screen bleachbit \
util-linux* apt-utils bash-completion openssl finger dos2unix nano sed numlockx \
unrar p7zip unzip file-roller

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
tesseract-ocr-spa gimagereader \
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
shotwell eog

#OFIMATICA  ******************************************#
clear
echo -e "OFIMATICA\n"
sudo apt install -y pdfarranger evince 

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
sudo apt-get update �fix-missing
sudo apt-get install -f
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo dpkg --configure -a
sudo rm /usr/share/xsessions/*classic* -rf

clear
echo -e "FULL UPDATE\n"
sudo apt clean -y
sudo apt update -y && sudo apt upgrade -y && sudo apt full-upgrade -y
sudo aptitude safe-upgrade -y
sudo reboot


