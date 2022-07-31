#!/bin/bash
clear
#REPOS
echo "REPOS"
sudo dnf -y install fedora-workstation-repositories
sudo dnf config-manager --set-enabled google-chrome
sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
sudo dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
sudo echo -e "[main]\ngpgcheck=1\ninstallonly_limit=3\nclean_requirements_on_remove=True\nbest=False\nskip_if_unavailable=True\n#Speed\nfastestmirror=True\nmax_parallel_downloads=10\ndefaultyes=True\nkeepcache=True\ndeltarpm=True" | sudo tee /etc/dnf/dnf.conf
sudo dnf clean all
sudo dnf makecache --refresh
sudo dnf -y install util-linux-user openssl finger dos2unix nano sed numlockx
echo "*************************************************************************************"
sleep 7

#KDE
clear
echo -e "INSTALL KDE PLASMA\n"
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

#NAME
clear
echo -e "NAME HOST\n"
read -p "New name: " nombre
echo -e "\n"
sudo hostnamectl set-hostname $nombre
echo "*************************************************************************************"
sleep 7

#USER
clear
echo "USER NAME"
read -p "Add new user? (y/n): " a
if [ $a == "y" ]
then
read -p "Enter Name : " name
read -p "Enter Username (login) : " username
read -s -p "Enter password : " password
echo ""
sudo useradd -p $(openssl passwd -1 $password) $username
sudo chfn -f $name $username
sudo usermod -aG wheel $username
sudo usermod -aG vboxsf $username
else
echo "*************************************************************************************"
fi
sleep 7

###### UPDATE
clear
echo "UPDATE"
sudo dnf -y upgrade --refresh
sudo dnf clean all
echo "*************************************************************************************"
sleep 7
reboot
