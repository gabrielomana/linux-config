#!/bin/bash
clear
#UNINSTALL XFCE
clear
echo "UNINSTALL XFCE"
sudo apt purge --autoremove mint-meta-xfce thunar thunar* ^xfce4* xfce* xfconf xfdesktop4 xfwm4 mugshot -y
clear
sudo apt purge --autoremove libreoffice* simple-scan drawing pix thunderbird* transmission* hexchat xviewer gnome-calculator seahorse gnome-disk* xed exo-utils mintstick file-roller gucharmap gnome-logs gnome-font-viewer xreader warpinator celluloid pavucontrol rhythmbox thingy \
compiz* gnome-disk* metacity gcr* baobab mintinstall* mintupdate mintbackup system-config-printer mintreport* gdebi* gnome-logs menulibre celluloid rhythmbox sticky lightdm lightdm-settings -y

clear
sudo apt-get -f install
sudo apt-get clean
sudo apt-get autoclean
sudo apt-get update --fix-missing
sudo apt-get install -f

clear
sudo rm /usr/share/xfce4/ -rf
sudo rm /usr/share/thunar/ -rf
sudo rm /usr/share/themes/Mint* -rf
sudo rm /usr/share/themes/mint* -rf
sudo rm /usr/share/Thunar -rf

clear
sudo apt update; sudo apt upgrade -y; sudo apt install -f; sudo dpkg --configure -a; sudo apt-get autoremove; sudo apt --fix-broken install; sudo update-apt-xapian-index

#KDE PLASMA
clear
echo "KDE PLASMA"
# sudo apt -y install tasksel
# sudo tsksell install kde-desktop
sudo apt -y install kde-plasma-desktop
sudo apt -y install plasma-workspace-wayland
sudo apt -y install sddm sddm-theme-breeze
sudo systemctl set-default graphical.target
sudo systemctl enable sddm
lookandfeeltool -a org.kde.breezedark.desktop
sudo lookandfeeltool -a org.kde.breezedark.desktop

#CLEAN PLASMA
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
###### REPOSITORIES
clear
echo "REPOSITORIES"

sudo add-apt-repository multiverse -y

sudo add-apt-repository ppa:cappelikan/ppa -y
##Fix deprecated Key MINT issue
sudo mv /etc/apt/trusted.gpg /etc/apt/mainline.gpg
sudo ln -s /etc/apt/mainline.gpg /etc/apt/trusted.gpg.d/mainline.gpg

sudo add-apt-repository ppa:graphics-drivers/ppa -y
##Fix deprecated Key MINT issue
sudo mv /etc/apt/trusted.gpg /etc/apt/nvidia.gpg
sudo ln -s /etc/apt/nvidia.gpg /etc/apt/trusted.gpg.d/nvidia.gpg

sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
##Fix deprecated Key MINT issue
sudo mv /etc/apt/trusted.gpg /etc/apt/grub-customizer.gpg
sudo ln -s /etc/apt/grub-customizer.gpg /etc/apt/trusted.gpg.d/grub-customizer.gpg

sudo add-apt-repository ppa:appimagelauncher-team/stable -y
##Fix deprecated Key MINT issue
sudo mv /etc/apt/trusted.gpg /etc/apt/appimagelauncher.gpg
sudo ln -s /etc/apt/appimagelauncher.gpg /etc/apt/trusted.gpg.d/appimagelauncher.gpg

sudo add-apt-repository ppa:kubuntu-ppa/backports -y
##Fix deprecated Key MINT issue
sudo mv /etc/apt/trusted.gpg /etc/apt/kubuntu_backports.gpg
sudo ln -s /etc/apt/kubuntu_backports.gpg /etc/apt/trusted.gpg.d/kubuntu_backports.gpg

sudo add-apt-repository ppa:kubuntu-ppa/backports-extra -y
##Fix deprecated Key MINT issue
sudo mv /etc/apt/trusted.gpg /etc/apt/kubuntu_backports_extra.gpg
sudo ln -s /etc/apt/kubuntu_backports_extra.gpg /etc/apt/trusted.gpg.d/kubuntu_backports_extra.gpg

sudo add-apt-repository ppa:ubuntustudio-ppa/backports -y
##Fix deprecated Key MINT issue
sudo mv /etc/apt/trusted.gpg /etc/apt/ubuntustudio.gpg
sudo ln -s /etc/apt/ubuntustudio.gpg /etc/apt/trusted.gpg.d/ubuntustudio.gpg

sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y
##Fix deprecated Key MINT issue
sudo mv /etc/apt/trusted.gpg /etc/apt/pipewire.gpg
sudo ln -s /etc/apt/pipewire.gpg /etc/apt/trusted.gpg.d/pipewire.gpg

sudo add-apt-repository ppa:pipewire-debian/wireplumber-upstream -y
##Fix deprecated Key MINT issue
sudo mv /etc/apt/trusted.gpg /etc/apt/wireplumber.gpg
sudo ln -s /etc/apt/wireplumber.gpg /etc/apt/trusted.gpg.d/wireplumber.gpg

sudo add-apt-repository ppa:qbittorrent-team/qbittorrent-stable -y
##Fix deprecated Key MINT issue
sudo mv /etc/apt/trusted.gpg /etc/apt/qbittorrent.gpg
sudo ln -s /etc/apt/qbittorrent.gpg /etc/apt/trusted.gpg.d/qbittorrent.gpg

mkdir -p ~/.gnupg
chmod 700 ~/.gnupg
gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
chmod 644 /tmp/onlyoffice.gpg
sudo chown root:root /tmp/onlyoffice.gpg
sudo mv /tmp/onlyoffice.gpg /etc/apt/trusted.gpg.d/
echo 'deb https://download.onlyoffice.com/repo/debian squeeze main' | sudo tee -a /etc/apt/sources.list.d/onlyoffice.list

#sudo add-apt-repository ppa:kisak/kisak-mesa -y
##Fix deprecated Key MINT issue
#sudo mv /etc/apt/trusted.gpg /etc/apt/kisak-mesa.gpg
#sudo ln -s /etc/apt/kisak-mesa.gpg /etc/apt/trusted.gpg.d/kisak-mesa.gpg

sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
sudo apt update -y
clear

sudo apt install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo apt install plasma-discover-backend-flatpak -y


#EXTRA APPS KDE
clear
echo -e "APPS KDE\n"
sudo apt install -y \
kcalc \
kate \
kmix \
knotes \
kde-config-cron* \
krename \
kamoso \
kid3 \
kcolorchooser \
kcharselect \
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

#CORE APPS
clear
echo -e "CORE APPS\n"
sudo apt install -y \
build-essential gcc make perl g++ npm \
wget curl git gdebi \
dconf* cabextract fontconfig cmake anacron \
software-properties-common ca-certificates gnupg2 ubuntu-keyring apt-transport-https \
default-jre nodejs cargo libssl-dev pkg-config \
ubuntu-drivers-common \
ubuntu-restricted-extras \
gstreamer1.0-libav ffmpeg x264 x265 mencoder lame mplayer \
samba \
screen bleachbit \
util-linux* apt-utils bash-completion openssl finger dos2unix nano sed numlockx \
unrar p7zip unzip ark
sudo apt install -y mainline

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
mkdir /tmp/nerd-fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/JetBrainsMono.zip /tmp/nerd-fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Ubuntu.zip /tmp/nerd-fonts/
wget https://github.com/ryanoasis/nerd-fonts/releases/download/v2.2.2/Mononoki.zip /tmp/nerd-fonts/
sudo unzip -o JetBrainsMono.zip -d /tmp/nerd_fonts/JetBrainsMono/
sudo unzip -o JetBrainsMono.zip -d /tmp/nerd_fonts/Ubuntu/
sudo unzip -o JetBrainsMono.zip -d /tmp/nerd_fonts/Mononoki/
sudo mv /tmp/nerd_fonts/JetBrainsMono/*.ttf /usr/share/fonts/nerd_fots/
sudo mv /tmp/nerd_fonts/Ubuntu/*.ttf /usr/share/fonts/nerd_fots/
sudo mv /tmp/nerd_fonts/Mononoki/*.ttf /usr/share/fonts/nerd_fots/
sudo mv /tmp/nerd_fonts/JetBrainsMono/*.otf /usr/share/fonts/nerd_fots/
sudo mv /tmp/nerd_fonts/Ubuntu/*.otf /usr/share/fonts/nerd_fots/
sudo mv /tmp/nerd_fonts/Mononoki/*.otf /usr/share/fonts/nerd_fots/
sudo rm /tmp/nerd_fonts/ -rf
fc-cache -f -v


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
featherpad \
qbittorrent

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
sudo apt-get install onlyoffice-desktopeditors -y

#FULL UPDATE  ******************************************#
clear
echo -e "FULL UPDATE\n"
sudo apt clean -y
sudo apt update; sudo apt full-upgrade -y; sudo apt install -f; sudo dpkg --configure -a; sudo apt-get autoremove; sudo apt --fix-broken install; sudo update-apt-xapian-index
sudo aptitude safe-upgrade -y
sudo systemctl disable casper-md5check.service
reboot

