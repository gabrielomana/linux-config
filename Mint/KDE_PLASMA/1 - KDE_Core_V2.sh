#!/bin/bash
clear
dir="$(pwd)"

. "${dir}"/sources/functions/functions

codecs="${dir}/sources/lists/codecs.list"
exta_apps="${dir}/sources/lists/exta_apps.list"
kde_plasma="${dir}/sources/lists/kde_plasma.list"
kde_plasma_apps="${dir}/sources/lists/kde_plasma_apps.list"
multimedia="${dir}/sources/lists/multimedia.list"
tools="${dir}/sources/lists/tools.list"
utilities="${dir}/sources/lists/utilities.list"
xfce="${dir}/sources/lists/xfce.list"

######################## UNINSTALL XFCE ###############################
clear
echo "UNINSTALL XFCE"
check_uninstalled "${xfce}"

clear
echo "UNINSTALL XFCE: Fix missing"
sudo apt-get -f install
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get update --fix-missing
sudo apt-get install -f

clear
echo "UNINSTALL XFCE: Remove folders"
sudo rm /usr/share/xfce4/ -rf
sudo rm /usr/share/thunar/ -rf
sudo rm /usr/share/themes/Mint* -rf
sudo rm /usr/share/themes/mint* -rf
sudo rm /usr/share/Thunar -rf

clear
echo "UNINSTALL XFCE: Update & clean"
sudo apt update; sudo apt upgrade -y; sudo apt install -f; sudo dpkg --configure -a; sudo apt-get autoremove; sudo apt --fix-broken install; sudo update-apt-xapian-index
sudo apt remove initramfs-tools -y
sudo apt clean
sudo apt install initramfs-tools -y
sudo apt-get update --fix-missing
sudo apt-get install -f

######################## REPOSITORIES ###############################
clear
echo "REPOSITORIES"
add_repos

##### CLEAN ANH GET MISSINGS KEYS ####
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
sudo apt update -y
clear

##### FLATPACKS ####
sudo apt install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo


######################## KDE PLASMA ###############################
clear
echo "KDE PLASMA"
check_installed "${kde_plasma}"
sudo systemctl set-default graphical.target
sudo systemctl enable sddm
lookandfeeltool -a org.kde.breezedark.desktop
sudo lookandfeeltool -a org.kde.breezedark.desktop
sudo apt install plasma-discover-backend-flatpak -y

#CLEAN PLASMA
clear
echo "KDE PLASMA: Remove apps and bloatware"
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


#KDE'S apps
clear
echo "KDE PLASMA: KDE'S apps"
# sudo apt install -y \
# kcalc \
# kate \
# kmix \
# knotes \
# kde-config-cron* \
# krename \
# kamoso \
# kid3 \
# kcolorchooser \
# kcharselect \
# kdenetwork-filesharing \
# kfind \
# kget \
# kinfocenter \
# kio-extras \
# krdc \
# kaccounts-providers \
# kio-gdrive \
# kbackup \
# plasma-nm plasma-pa plasma-widget* ffmpegthumbs ark \
# okular
check_installed "${kde_plasma_apps}"


######################## CORE APPS ###############################
clear
echo "CORE APPS"


#Development tools and libraries
# sudo apt install -y \
# build-essential gcc make perl g++ npm \
# wget curl git gdebi \
# "dconf*" cabextract fontconfig cmake anacron \
# software-properties-common ca-certificates gnupg2 ubuntu-keyring apt-transport-https \
# default-jre nodejs libssl-dev pkg-config
check_installed "${tools}"


curl https://sh.rustup.rs -sSf | sh
source ~/.profile
source ~/.cargo/env

#Codecs and Drivers
# sudo apt install -y \
# ubuntu-drivers-common \
# ubuntu-restricted-extras \
# gstreamer1.0-libav ffmpeg x264 x265 mencoder lame mplayer
check_installed "${codecs}"

#Utilities
# sudo apt install -y \
# samba \
# screen bleachbit \
# "util-linux*" apt-utils bash-completion openssl finger dos2unix nano sed numlockx \
# unrar p7zip unzip bat \
# mainline \
# v4l2loopback-utils \
# neofetch \
# printer-driver-cups-pdf \
# grub-customizer \
# tesseract-ocr-spa gimagereader \
# timeshift \
# ksnip \
# appimagelauncher \
# featherpad \
# pdfarranger \
# qbittorrent
check_installed "${utilities}"

cargo install --git https://github.com/Peltoche/lsd.git --branch master
#falta el alias de batch"

sudo npm install -g hblock
hblock


#PIPEWIRE & WIREPLUMBER
sudo apt install -y libfdk-aac2 libldacbt-{abr,enc}2 libopenaptx0
sudo apt install -y gstreamer1.0-pipewire libpipewire-0.3-{0,dev,modules} libspa-0.2-{bluetooth,dev,jack,modules} pipewire{,-{audio-client-libraries,pulse,bin,locales,tests}}
sudo apt install -y pipewire-doc
sudo apt-get install -y wireplumber{,-doc} gir1.2-wp-0.4 libwireplumber-0.4-{0,dev}
systemctl --user --now disable pulseaudio.{socket,service}
systemctl --user mask pulseaudio
systemctl --user --now enable pipewire{,-pulse}.{socket,service}
systemctl --user --now enable wireplumber.service

#NERD FONTS
mkdir /tmp/nerd_fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/JetBrainsMono.zip -P /tmp/nerd_fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Ubuntu.zip -P /tmp/nerd_fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Mononoki.zip -P /tmp/nerd_fonts/

sudo unzip /tmp/nerd_fonts/JetBrainsMono.zip -d /tmp/nerd_fonts/JetBrainsMono
sudo unzip /tmp/nerd_fonts/Ubuntu.zip -d /tmp/nerd_fonts/Ubuntu/
sudo unzip /tmp/nerd_fonts/Mononoki.zip -d /tmp/nerd_fonts/Mononoki/

sudo mkdir /usr/share/fonts/nerd_fonts/
sudo mv /tmp/nerd_fonts/JetBrainsMono/*.ttf /usr/share/fonts/nerd_fonts/
sudo mv /tmp/nerd_fonts/Ubuntu/*.ttf /usr/share/fonts/nerd_fonts/
sudo mv /tmp/nerd_fonts/Mononoki/*.ttf /usr/share/fonts/nerd_fonts/
sudo mv /tmp/nerd_fonts/JetBrainsMono/*.otf /usr/share/fonts/nerd_fonts/
sudo mv /tmp/nerd_fonts/Ubuntu/*.otf /usr/share/fonts/nerd_fonts/
sudo mv /tmp/nerd_fonts/Mononoki/*.otf /usr/share/fonts/nerd_fonts/
sudo rm /tmp/nerd_fonts/ -rf
sudo apt install -y fonts-noto-color-emoji
sudo cp Files/fonts.conf /etc/fonts/fonts.conf -rf
fc-cache -f -v

#MULTIMEDIA
clear
echo -e "MULTIMEDIA\n"
sudo apt remove gpac -y
# sudo apt install -y \
# vlc \
# audacity \
# audacious \
# nomacs \
# digikam
check_installed "${multimedia}"

sudo timedatectl set-local-rtc 1

##############################################################################################
########################################  EXTRA APPS ##########################################

declare -a apps
declare -a install
apps=(brave onlyoffice filezilla WhatsApp ytmdesktop KODI QEMU Balena-etcher Playonlinux Extra-Fonts)
s=${#apps[*]}
a=0
j=0

    while [ $a -lt 1  ]
    do
        read -p "Do you wish to install Extra Apps? " yn
        case $yn in
            [Yy]* ) a=1;check_installed "${exta_apps}";clear;;
            [Nn]* ) a=1;echo "OK\n";clear;;
            * ) echo "Please answer yes or no.";;
        esac
    done

#######################################_END_#################################################
#############################################################################################


######## CARGO & TOPGRADE #####################################
cargo install cargo-update
cargo install topgrade
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.bashrc
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.bashrc

######## KONSOLE #############################################
sudo cp Style/Colors/* /usr/share/konsole/ -rf
cp Files/konsole.profile ~/.local/share/konsole/

######## ZSH+OH_MY_ZSH+STARSHIP+GRUB ###############################
sudo apt -y install zsh
sudo chsh -s $(which zsh)
sudo chsh -s /usr/bin/zsh $USER
chsh -s $(which zsh)
chsh -s /usr/bin/zsh $USER

git clone https://github.com/ohmyzsh/ohmyzsh/ /tmp/ohmyzsh/
ZSH= sh /tmp/ohmyzsh/tools/install.sh
rm -rf /tmp/ohmyzsh/


git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/fast-syntax-highlighting
git clone https://github.com/MichaelAquilina/zsh-you-should-use.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/you-should-use

cp -r Files/.zshrc ~/
cp -r Files/topgrade.toml ~/.config
cp -r Files/starship/starship_3.toml ~/.config/starship.toml


sudo mv ~/.config/neofetch/config.conf ~/.config/neofetch/config_old.conf
sudo cp -r Files/neofetch.conf ~/.config/neofetch/config.conf
sudo mv /etc/default/grub /etc/default/grub_old
sudo cp -r Files/grub /etc/default/grub
sudo update-grub


######## FULL UPDATE ##########################################
clear
echo -e "FULL UPDATE\n"
sudo apt clean -y
sudo apt update; sudo apt full-upgrade -y; sudo apt install -f; sudo dpkg --configure -a; sudo apt-get autoremove; sudo apt --fix-broken install; sudo update-apt-xapian-index
sudo aptitude safe-upgrade -y
sudo systemctl disable casper-md5check.service
reboot

