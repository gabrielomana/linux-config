#!/bin/bash

# UNINSTALL
clear
echo "UNINSTALL"
sudo dnf -y remove gwenview akregator kmail konversation krfb kmahjongg kmines dragonplayer elisa-player korganizer kontact kpat
sudo dnf -y groupremove "LibreOffice"
sudo dnf -y remove libreoffice-*
sudo dnf -y autoremove
echo "*************************************************************************************"
sleep 7


# CONF DNF
clear
echo "CONF DNF"
sudo echo -e "[main]\ngpgcheck=1\ninstallonly_limit=3\nclean_requirements_on_remove=True\nbest=False\nskip_if_unavailable=True\n#Speed\nfastestmirror=True\nmax_parallel_downloads=10\ndefaultyes=True\nkeepcache=True\ndeltarpm=True" | sudo tee /etc/dnf/dnf.conf
sudo dnf clean all
sudo dnf makecache --refresh
echo "*************************************************************************************"
sleep 7


#REPOSITORIES  *******************************************#
sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf -y install fedora-workstation-repositories
sudo dnf config-manager --set-enabled google-chrome
sudo dnf -y copr enable refi64/webapp-manager
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
curl -1sLf \
'https://dl.cloudsmith.io/public/balena/etcher/setup.rpm.sh' \
| sudo -E bash

sudo yum -y install https://download.onlyoffice.com/repo/centos/main/noarch/onlyoffice-repo.noarch.rpm
sudo yum -y install epel-release

sudo dnf -y copr enable ayoungdukie/Personal_Repo 
sudo dnf -y copr enable bugzy/mkchromecast

sudo rpm --import https://raw.githubusercontent.com/UnitedRPMs/unitedrpms/master/URPMS-GPG-PUBLICKEY-Fedora
sudo dnf -y install https://github.com/UnitedRPMs/unitedrpms/releases/download/20/unitedrpms-$(rpm -E %fedora)-20.fc$(rpm -E %fedora).noarch.rpm

sudo dnf makecache --refresh
sudo dnf config-manager --set-disabled balena-etcher-noarch
sudo dnf config-manager --set-disabled balena-etcher-source
sudo dnf makecache --refresh


#CODECS, LIBS  *******************************************#
sudo dnf -y group install "C Development Tools and Libraries" "Development Tools"
sudo dnf -y install util-linux-user dnf-plugins-core openssl finger dos2unix nano sed sudo numlockx wget curl git nodejs cargo python3-psutil.x86_64
sudo dnf -y install dnfdragora java-latest-openjdk.x86_64 samba screen cabextract xorg-x11-font-utils fontconfig cmake alien anacron 
sudo dnf -y groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf -y install gstreamer1-libav gstreamer1-plugins-bad-free-extras gstreamer1-plugins-bad-freeworld gstreamer1-plugins-good-extras gstreamer1-plugins-ugly unrar p7zip p7zip-plugins gstreamer1-plugin-openh264 mozilla-openh264 openh264 webp-pixbuf-loader gstreamer1-plugins-bad-free-fluidsynth gstreamer1-plugins-bad-free-wildmidi gstreamer1-svt-av1 libopenraw-pixbuf-loader dav1d x264 h264enc x265 svt-av1 rav1e cabextract mencoder mplayer ffmpeg
sudo dbf -y install lame\* --exclude=lame-devel
sudo dnf -y groupupdate sound-and-video
sudo dnf -y groupupdate core
sudo dnf -y install rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data 
sudo cargo install cargo-update
numlockx on
sudo numlockx on
echo "$(cat /etc/sddm.conf | sed -E s/'^\#?Numlock\=.*$'/'Numlock=on'/)" | sudo tee /etc/sddm.conf && sudo systemctl daemon-reload
echo "*************************************************************************************"
sleep 7


# FONTS
sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
sudo dnf install -y dejavu-fonts* google-roboto-fonts
sudo dnf copr enable atim/ubuntu-fonts -y && sudo dnf install ubuntu-family-fonts
sudo fc-cache -fv



#INTERNET  *******************************************#
sudo dnf install -y \
firefox \
brave-browser \
filezilla

flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y
flatpak install flathub us.zoom.Zoom -y
flatpak install flathub com.anydesk.Anydesk -y
flatpak install flathub com.microsoft.Teams -y


#OFIMATICA  ******************************************#
sudo dnf -y install \
pdfsam \
okular

sudo yum install onlyoffice-desktopeditors -y

#*****************************************************#


#MULTIMEDIA  *****************************************#
sudo dnf install -y \
vlc \
audacity \
audacious \
audacious-plugins-freeworld  \
nomacs \
mkchromecast \
clementine

sudo timedatectl set-local-rtc 1

flatpak install flathub app.ytmdesktop.ytmdesktop -y
flatpak install flathub tv.kodi.Kodi -y
flatpak install flathub com.github.bajoja.indicator-kdeconnect -y


#HERRAMIENTAS  ***************************************#

sudo dnf install -y \
unrar p7zip unzip ark \
featherpad \
qemu qemu-kvm libvirt libvirt-devel virt-top libguestfs-tools guestfs-tools bridge-utils virt-manager \
digikam \
timeshift \
ksnip \

#APPs KDE  ***************************************#
sudo dnf install -y \
kcalc \
kate kate-plugins \
kmix \
knotes \
kcron \
krename \
kid3 \
kcolorchooser \
kdenetwork-filesharing \
kfind \
kget \
kinfocenter \
kio-extras \
krdc \
plasma-nm plasma-pa plasma-widget* ffmpegthumbs \
kaccounts-providers
kio-gdrive \

sudo dnf -y remove kwrite

#*****************************************************#


#SISTEMA   *******************************************#

sudo dnf install -y \
v4l2loopback-utils \
neofetch \
stacer bleachbit \
cups-pdf \
grub-customizer \
tesseract tesseract-devel tesseract-langpack-cat tesseract-langpack-eng tesseract-langpack-spa gimagereader-qt \
policycoreutils-gui firewall-config \

sudo npm install -g hblock
hblock


sudo systemctl start libvirtd
sudo systemctl enable libvirtd

sudo dnf -y install webapp-manager
sudo yum -y localinstall https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm

sudo curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl
sudo chmod a+rx /usr/local/bin/youtube-dl
sudo dnf -y install balena-etcher-electron

flatpak install flathub org.phoenicis.playonlinux -y
flatpak install flathub com.usebottles.bottles -y


#*****************************************************#


# UPDATE & UPGRADE
sudo dnf -y install topgrade
sudo cp -r Files/topgrade.toml ~/.config/topgrade.toml
sudo cp -r Files/topgrade.toml /root/.config/topgrade.toml
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.config/zsh_config/zsh_path
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.config/zsh_config/zsh_path
sudo topgrade

sudo dnf clean dbcache
sudo bleachbit
