#!/bin/bash
#NAME
echo NEW NAME FOR DE COMPUTER:
read nombre
sudo hostnamectl set-hostname $nombre

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
sudo dnf -y group install "C Development Tools and Libraries" "Development Tools"
echo "*************************************************************************************"
sleep 7

###### REPOSITORIES
clear
echo "REPOSITORIES"
sudo dnf -y install fedora-workstation-repositories
sudo dnf config-manager --set-enabled google-chrome
sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo flatpak remote-add --if-not-exists --authenticator-install flathub https://flathub.org/repo/flathub.flatpakrepo
sudo dnf -y copr enable refi64/webapp-manager

curl -1sLf \
'https://dl.cloudsmith.io/public/balena/etcher/setup.rpm.sh' \
| sudo -E bash


sudo yum -y install https://download.onlyoffice.com/repo/centos/main/noarch/onlyoffice-repo.noarch.rpm
sudo yum -y install epel-release

sudo dnf -y copr enable ayoungdukie/Personal_Repo 

sudo dnf -y copr enable bugzy/mkchromecast

sudo rpm --import https://raw.githubusercontent.com/UnitedRPMs/unitedrpms/master/URPMS-GPG-PUBLICKEY-Fedora
sudo dnf -y install https://github.com/UnitedRPMs/unitedrpms/releases/download/20/unitedrpms-$(rpm -E %fedora)-20.fc$(rpm -E %fedora).noarch.rpm

sudo dnf -y makecache --refresh
sudo dnf config-manager --set-disabled balena-etcher-noarch
sudo dnf config-manager --set-disabled balena-etcher-source
sudo dnf makecache --refresh
echo "*************************************************************************************"
sleep 7


###### EXTRA LIBS AND CODECS
clear
echo "EXTRA LIBS AND CODECS"
sudo dnf -y install dnfdragora wget curl git nodejs java-latest-openjdk.x86_64 cargo samba screen cabextract xorg-x11-font-utils fontconfig util-linux-user cmake alien anacron numlockx
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


echo "*************************************************************************************"
sleep 7
###### UPDATE
clear
echo "UPDATE"
sudo dnf -y upgrade --refresh
sudo dnf clean all
echo "*************************************************************************************"
sleep 7
reboot
