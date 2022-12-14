#!/bin/bash
mintsources
# CODECS | FONTS
sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
sudo dnf install -y dejavu-fonts* google-roboto-fonts
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
audacity \
neofetch \
unrar p7zip unzip ark \
featherpad vlc \
qemu qemu-kvm libvirt libvirt-devel virt-top libguestfs-tools guestfs-tools bridge-utils virt-manager \
stacer bleachbit \
cups-pdf \
digikam \
grub-customizer \
tesseract tesseract-devel tesseract-langpack-cat tesseract-langpack-eng tesseract-langpack-spa gimagereader-qt timeshift \
google-chrome-stable chromium firefox \
policycoreutils-gui firewall-config \
ksnip

sudo systemctl start libvirtd
sudo systemctl enable libvirtd

sudo dnf -y install webapp-manager

sudo yum -y localinstall https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm

##################### APPS PLASMA/KDE #########################################

sudo dnf -y install kcalc kate kate-plugins kmix knotes plasma-nm plasma-pa plasma-widget*
sudo dnf -y install clementine okular kcron ffmpegthumbs krename kid3 kcolorchooser kdenetwork-filesharing kfind kget kinfocenter kio-extras krdc
sudo dnf -y install kaccounts-providers
sudo dnf -y install kio-gdrive
sudo dnf -y install cmake extra-cmake-modules kf5-kconfig-devel \
    kf5-kcoreaddons-devel kf5-kwindowsystem-devel kwin-devel \
    qt5-qtbase-devel libepoxy-devel kf5-kconfigwidgets-devel
sudo dnf -y remove kwrite

################################################################################

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
flatpak install flathub us.zoom.Zoom -y
flatpak install flathub app.ytmdesktop.ytmdesktop -y
flatpak install flathub tv.kodi.Kodi -y
flatpak install flathub com.github.bajoja.indicator-kdeconnect -y
flatpak install flathub org.phoenicis.playonlinux -y
flatpak install flathub com.usebottles.bottles -y
flatpak install flathub com.anydesk.Anydesk -y
flatpak install flathub com.microsoft.Teams -y
flatpak install flathub org.atheme.audacious -y
flatpak install flathub org.nomacs.ImageLounge -y


# UPDATE & UPGRADE
sudo dnf -y install topgrade
sudo cp -r Files/topgrade.toml ~/.config/topgrade.toml
sudo cp -r Files/topgrade.toml /root/.config/topgrade.toml
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.config/zsh_config/zsh_path
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.config/zsh_config/zsh_path
sudo topgrade

sudo dnf clean dbcache
sudo bleachbit




