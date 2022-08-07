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


###Nautilis>Nemo

sudo echo "deb http://packages.linuxmint.com una main upstream import backport" > /etc/apt/sources.list.d/linux-mint.list  
sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A6616109451BBBF2
sudo apt reinstall libxapp1 -y
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/mint.gpg
sudo apt install linuxmint-keyring -y
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
#sudo apt -y install python-nemo nemo-compare nemo-terminal nemo-fileroller cinnamon-l10n mint-translations --install-recommends

sudo sh -c 'echo "Package: *\nPin: release o=Ubuntu\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo "Package: *\nPin: release o=LP-PPA-ubuntustudio-ppa-backports\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo "Package: *\nPin: release o=LLP-PPA-pipewire-debian-pipewire-upstream\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo "Package: *\nPin: release o=LP-PPA-kisak-kisak-mesa\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo "Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo "Package: *\nPin: release o=LP-PPA-graphics-drivers\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo sh -c 'echo "Package: *\nPin: release o=linuxmint\nPin-Priority: 100\n\n" >> /etc/apt/preferences.d/priority.pref'
sudo apt update
clear
sudo apt install nemo -y

sudo apt purge nautilus gnome-shell-extension-desktop-icons -y

xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.nemo.desktop show-desktop-icons true
gsettings set org.nemo.desktop use-desktop-grid true
echo -e "[Desktop Entry]\nType=Application\nName=Files\nExec=nemo-desktop\nOnlyShowIn=GNOME;Unity;\nX-Ubuntu-Gettext-Domain=nemo" | sudo tee /etc/xdg/autostart/nemo-autostart.desktop
sudo apt -y install python-nemo nemo-compare nemo-terminal nemo-fileroller cinnamon-l10n mint-translations --install-recommends

sudo apt install chrome-gnome-shell gnome-tweaks gnome-shell-extensions gnome-software -y
sudo apt-get update –fix-missing
sudo apt-get install -f
sudo apt-get autoremove -y
sudo dpkg --configure -a
sudo apt-get clean -y
reboot
