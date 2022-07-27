#!/bin/bash

# CODECS | FONTS 
sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
sudo dnf install -y dejavu-fonts* google-roboto-fonts
wget -q -O - https://gist.githubusercontent.com/Blastoise/72e10b8af5ca359772ee64b6dba33c91/raw/2d7ab3caa27faa61beca9fbf7d3aca6ce9a25916/clearType.sh | sudo bash
wget -q -O - https://gist.githubusercontent.com/Blastoise/b74e06f739610c4a867cf94b27637a56/raw/96926e732a38d3da860624114990121d71c08ea1/tahoma.sh | sudo bash
wget -q -O - https://gist.githubusercontent.com/Blastoise/64ba4acc55047a53b680c1b3072dd985/raw/6bdf69384da4783cc6dafcb51d281cb3ddcb7ca0/segoeUI.sh | sudo bash
wget -q -O - https://gist.githubusercontent.com/Blastoise/d959d3196fb3937b36969013d96740e0/raw/429d8882b7c34e5dbd7b9cbc9d0079de5bd9e3aa/otherFonts.sh | sudo bash
sudo fc-cache -fv

sudo dnf -y install mkchromecast
sudo timedatectl set-local-rtc 1

######ahorro bateria portatiles######
#sudo dnf install tlp tlp-rdw

#Hblock
sudo npm install -g hblock
hblock
  
#Wine
#sudo rm /etc/dpkg/dpkg.cfg.d/multiarch
#sudo apt-get install gtk2-engines-murrine:i386 libcanberra-gtk-module:i386 libatk-adaptor:i386 libgail-common:i386 -y
#sudo dpkg --add-architecture i386
#sudo apt install --install-recommends -y wine-installer
#sudo apt install --install-recommends -y winehq-stable wine64
#sudo apt install --install-recommends -y wine64
#sudo apt install --install-recommends -y winetricks libgl1-mesa-glx:i386 libgl1-mesa-dri:i386 winbind os-prober 
#wget https://winegui.melroy.org/downloads/WineGUI-v1.8.1.deb
#sudo gdebi WineGUI-v1.8.1.deb <<<'S'
#rm *.deb -rf

#sudo winetricks mspatcha
#sudo winecfg

# INSTALLATION OF BASIC PACKAGES
sudo dnf install -y \
filezilla \
v4l2loopback-utils \
nomacs \
audacity \
neofetch \
unrar p7zip unzip file-roller \
gedit \
qemu qemu-kvm libvirt libvirt-devel virt-top libguestfs-tools guestfs-tools bridge-utils virt-manager \
uget \
stacer bleachbit \
cups-pdf \
shotwell \
deadbeef deadbeef-mpris2-plugin deadbeef-plugins \
grub-customizer \
tilix \
https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm \
tesseract tesseract-devel tesseract-langpack-cat tesseract-langpack-eng tesseract-langpack-spa gimagereader-qt timeshift \
google-chrome-stable chromium \
policycoreutils-gui firewall-config

sudo systemctl start libvirtd
sudo systemctl enable libvirtd

sudo dnf -y install webapp-manager

gsettings set org.gnome.desktop.default-applications.terminal exec 'tilix'


#FoxIt PDF
#wget http://cdn01.foxitsoftware.com/pub/foxit/reader/desktop/linux/2.x/2.4/en_us/FoxitReader.enu.setup.2.4.4.0911.x64.run.tar.gz
#tar xzvf FoxitReader*.tar.gz
#sudo chmod a+x FoxitReader*.run
#sudo ./FoxitReader*.run
#rm Foxit* -rf

#PDFSam
sudo dnf -y install pdfsam

#Youtube-DL
sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
sudo chmod a+rx /usr/local/bin/youtube-dl

#OnlyOffice
sudo yum install onlyoffice-desktopeditors -y

#Rclone
wget https://rclone.org/install.sh
sudo chmod a+rx install.sh
sudo ./install.sh
rm install.sh -rf

#BALENA
sudo dnf -y install balena-etcher-electron


#Flatpak
flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y
flatpak install flathub org.videolan.VLC -y
flatpak install flathub org.qbittorrent.qBittorrent -y
flatpak install flathub us.zoom.Zoom -y
flatpak install flathub app.ytmdesktop.ytmdesktop -y
flatpak install flathub tv.kodi.Kodi -y
flatpak install flathub org.phoenicis.playonlinux -y
flatpak install flathub com.usebottles.bottles -y
flatpak install flathub com.anydesk.Anydesk -y
flatpak install flathub org.kde.okular -y
flatpak install flathub com.microsoft.Teams -y
flatpak install flathub com.notepadqq.Notepadqq -y
flatpak install flathub io.freetubeapp.FreeTube -y
flatpak install flathub org.ksnip.ksnip -y
# UPDATE & UPGRADE

sudo dnf -y install topgrade
sudo cp -r Files/topgrade.toml ~/.config/topgrade.toml
sudo cp -r Files/topgrade.toml /root/.config/topgrade.toml
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.config/zsh_config/zsh_path
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.config/zsh_config/zsh_path
sudo topgrade

sudo dnf clean dbcache 
bleachbit
firefox Files/extensions.html
reboot




