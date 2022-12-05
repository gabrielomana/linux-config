#!/bin/bash

#REPOS
clear
echo "REPOS"
sudo echo -e "[main]\ngpgcheck=1\ninstallonly_limit=3\nclean_requirements_on_remove=True\nbest=False\nskip_if_unavailable=True\n#Speed\nfastestmirror=True\nmax_parallel_downloads=10\ndefaultyes=True\nkeepcache=True\ndeltarpm=True" | sudo tee /etc/dnf/dnf.conf
sudo dnf clean all
sudo dnf makecache --refresh
sudo dnf -y install fedora-workstation-repositories
sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo dnf clean all
sudo dnf makecache --refresh
sudo dnf -y install util-linux-user dnf-plugins-core openssl finger dos2unix nano sed sudo numlockx wget curl git nodejs cargo
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
echo "*************************************************************************************"
sleep 7

# UNINSTALL
clear
echo "UNINSTALL"
sudo dnf -y remove gnome-photos gnome-boxes gnome-text-editor evince simple-scan totem gnome-weather gnome-maps gnome-contacts eog baobab libreoffice* rhythmbox 
sudo dnf -y remove awesome i3 openbox ratpoison
sudo dnf -y autoremove
echo "*************************************************************************************"
sleep 7

#TOOLS
clear
echo -e "TOOLS\n"
sudo dnf install -y \
firefox \
unrar p7zip unzip file-roller \
gedit \
cheese \
timeshift \
flameshot \
tilix \
https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm

sudo gsettings set org.gnome.desktop.default-applications.terminal exec 'tilix'

#SYSTEM
clear
echo -e "SYSTEM\n"
sudo dnf install -y \
v4l2loopback-utils \
neofetch \
stacer bleachbit python3-psutil.x86_64 \
cups-pdf \
grub-customizer \
tesseract tesseract-devel tesseract-langpack-cat tesseract-langpack-eng tesseract-langpack-spa gimagereader-qt \
policycoreutils-gui firewall-config

sudo npm install -g hblock
hblock

###### EXTRA LIBS AND CODECS
clear
echo "EXTRA LIBS AND CODECS"
sudo dnf -y install dnfdragora wget curl git nodejs java-latest-openjdk.x86_64 cargo samba screen dconf dconf-editor cabextract xorg-x11-font-utils fontconfig util-linux-user gedit cmake alien anacron
sudo dnf -y groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf -y install gstreamer1-libav gstreamer1-plugins-bad-free-extras gstreamer1-plugins-bad-freeworld gstreamer1-plugins-good-extras gstreamer1-plugins-ugly unrar p7zip p7zip-plugins gstreamer1-plugin-openh264 mozilla-openh264 openh264 webp-pixbuf-loader gstreamer1-plugins-bad-free-fluidsynth gstreamer1-plugins-bad-free-wildmidi gstreamer1-svt-av1 libopenraw-pixbuf-loader dav1d file-roller x264 h264enc x265 svt-av1 rav1e cabextract mencoder mplayer ffmpeg
sudo dbf -y install lame\* --exclude=lame-devel
sudo dnf -y groupupdate sound-and-video
sudo dnf -y groupupdate core
sudo dnf -y install rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data 
echo "*************************************************************************************"
sleep 7


#MULTIMEDIA
clear
echo -e "MULTIMEDIA\n"
sudo dnf install -y \
smplayer \
audacity \
deadbeef deadbeef-mpris2-plugin deadbeef-plugins \
shotwell


###### INSTALL NEMO / REMOVE NAUTILIUS
clear
echo "INSTALL NEMO / REMOVE NAUTILIUS"
sudo dnf -y remove nautilus.x86_64 gnome-shell-extension-desktop-icons
sudo dnf -y autoremove

sudo dnf -y  install nemo nemo.x86_64 nemo-extensions.x86_64 nemo-preview.x86_64 nemo-fileroller.x86_64 nemo-python-devel.x86_64 nemo-terminal.noarch nemo-compare.noarch
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.nemo.desktop show-desktop-icons true
echo -e "[Desktop Entry]\nType=Application\nName=Files\nComment=Start Nemo desktop at log in\nExec=nemo-desktop\nOnlyShowIn=GNOME;Unity;\nAutostartCondition=GSettings org.nemo.desktop show-desktop-icons\nX-GNOME-AutoRestart=true" | sudo tee /etc/xdg/autostart/nemo-autostart.desktop
sudo cp /usr/share/applications/nemo.desktop ~/.local/share/applications/nemo.desktop
sudo grep -v -s  "OnlyShowIn=X-Cinnamon;" ~/.local/share/applications/nemo.desktop > tmpfile && mv tmpfile ~/.local/share/applications/nemo.desktop

echo "*************************************************************************************"
sleep 7

###### EXTRAS GNOME
clear
echo "EXTRAS GNOME"
sudo dnf -y  install chrome-gnome-shell gnome-tweaks-tool gnome-extensions-app gnome-software chrome-gnome-shell 
#sudo dnf -y  install lightdm-gtk
#systemctl disable gdm.service
#systemctl enable lightdm

echo "*************************************************************************************"
sleep 7
###### UPDATE
clear
echo "UPDATE"
sudo dnf -y upgrade --refresh
sudo dnf clean all
echo "*************************************************************************************"
sleep 7
sudo dnf clean dbcache
sudo bleachbit
reboot
