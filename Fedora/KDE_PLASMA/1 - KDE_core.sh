#!/bin/bash
clear
# UNINSTALL
echo "UNINSTALL"
sudo dnf -y remove gwenview akregator kmail konversation krfb kmahjongg kmines dragonplayer elisa-player korganizer kontact kpat
sudo dnf -y groupremove "LibreOffice"
sudo dnf -y remove libreoffice-*
sudo dnf -y remove awesome i3 openbox ratpoison
sudo dnf -y autoremove
echo "*************************************************************************************"
sleep 7


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
echo "*************************************************************************************"
sleep 7

#KDE PLASMA
clear
echo -e "KDE PLASMA\n"
sudo dnf -y groupinstall "Espacios de trabajo KDE Plasma" "Herramientas y Librerías de Desarrollo en C" "Herramientas de desarrollo" "KDE" "Fuentes" "Soporte para Hardware" "Sonido y vídeo"
sudo dnf -y install NetworkManager-config-connectivity-fedora bluedevil breeze-gtk breeze-icon-theme cagibi colord-kde cups-pk-helper dolphin glibc-all-langpacks gnome-keyring-pam kcm_systemd kde-gtk-config kde-partitionmanager kde-print-manager kde-settings-pulseaudio kde-style-breeze kdegraphics-thumbnailers kdeplasma-addons kdialog kdnssd kf5-akonadi-server kf5-akonadi-server-mysql kf5-baloo-file kf5-kipi-plugins khotkeys kmenuedit konsole5 kscreen kscreenlocker ksshaskpass ksysguard kwalletmanager5 kwebkitpart kwin pam-kwallet phonon-qt5-backend-gstreamer pinentry-qt plasma-breeze plasma-desktop plasma-desktop-doc plasma-drkonqi plasma-nm plasma-nm-l2tp plasma-nm-openconnect plasma-nm-openswan plasma-nm-openvpn plasma-nm-pptp plasma-nm-vpnc plasma-pa plasma-user-manager plasma-workspace plasma-workspace-geolocation polkit-kde qt5-qtbase-gui qt5-qtdeclarative sddm sddm-breeze sddm-kcm sni-qt xorg-x11-drv-libinput setroubleshoot @"Hardware Support" @base-x @Fonts @"Common NetworkManager Submodules" @"Fonts"

echo -e "\nDefaul Grafics:"
sudo systemctl set-default graphical.target
sudo systemctl enable sddm
sudo numlockx on
echo "$(cat /etc/sddm.conf | sed -E s/'^\#?Numlock\=.*$'/'Numlock=on'/)" | sudo tee /etc/sddm.conf && sudo systemctl daemon-reload
#sudo sed 's/#Numlock=none/Numlock=on/g' /etc/sddm.conf > output.conf
#sudo sed 's/# DisplayServer=wayland/DisplayServer=x11/g' output.conf > output2.conf
#sudo mv output2.conf /etc/sddm.conf
#rm output.conf
#sudo dnf -y install materia-kde-sddm sddm-themes sddm-kcm
sleep 3

echo -e "\nRemove Software"
sudo dnf -y remove gwenview akregator kmail konversation krfb kmahjongg kmines dragonplayer elisa-player korganizer kontact kpat
sudo dnf -y groupremove "LibreOffice"
sudo dnf -y remove libreoffice-*
sudo dnf -y autoremove
echo "*************************************************************************************"
sleep 7

#APPS KDE
clear
echo -e "APPS KDE\n"
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
kaccounts-providers \
kio-gdrive \
plasma-nm plasma-pa plasma-widget* ffmpegthumbs --allowerasing

sudo dnf -y remove kwrite

#TOOLS
clear
echo -e "TOOLS\n"
sudo dnf install -y \
firefox \
unrar p7zip unzip ark \
featherpad \
digikam \
timeshift \
ksnip \
pdfarranger


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

#CODECS & LIBS
clear
echo -e "CODECS & LIBS\n"
sudo dnf -y group install "C Development Tools and Libraries" "Development Tools"
sudo dnf -y install util-linux-user dnf-plugins-core openssl finger dos2unix nano sed sudo numlockx wget curl git nodejs cargo python3-psutil.x86_64
sudo dnf -y install dnfdragora java-latest-openjdk.x86_64 samba screen cabextract xorg-x11-font-utils fontconfig cmake alien anacron
sudo dnf -y groupupdate multimedia --setop="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
sudo dnf -y install gstreamer1-libav gstreamer1-plugins-bad-free-extras gstreamer1-plugins-bad-freeworld gstreamer1-plugins-good-extras gstreamer1-plugins-ugly unrar p7zip p7zip-plugins gstreamer1-plugin-openh264 mozilla-openh264 openh264 webp-pixbuf-loader gstreamer1-plugins-bad-free-fluidsynth gstreamer1-plugins-bad-free-wildmidi gstreamer1-svt-av1 libopenraw-pixbuf-loader dav1d x264 h264enc x265 svt-av1 rav1e cabextract mencoder mplayer ffmpeg
sudo dnf -y install lame\* --exclude=lame-devel
sudo dnf -y groupupdate sound-and-video
sudo dnf -y groupupdate core
sudo dnf -y install rpmfusion-free-appstream-data rpmfusion-nonfree-appstream-data
numlockx on
sudo numlockx on
echo "$(cat /etc/sddm.conf | sed -E s/'^\#?Numlock\=.*$'/'Numlock=on'/)" | sudo tee /etc/sddm.conf && sudo systemctl daemon-reload
sudo dnf copr enable atim/ubuntu-fonts -y && sudo dnf install -y ubuntu-family-fonts
sudo fc-cache -fv


#MULTIMEDIA
clear
echo -e "MULTIMEDIA\n"
sudo dnf install -y \
vlc \
audacity \
audacious \
audacious-plugins-freeworld  \
nomacs


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

