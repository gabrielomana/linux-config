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
sudo dnf -y install util-linux-user openssl finger dos2unix nano sed sudo numlockx
echo "*************************************************************************************"
sleep 7

#GNOME
clear
echo "INSTALL GNOME"
sudo dnf -y groupinstall "GNOME Desktop Environment" "Herramientas y Librerías de Desarrollo en C" "Herramientas de desarrollo" "GNOME" "Fuentes" "Soporte para Hardware" "Sonido y vídeo" "NetworkManager-wifi" "wpa_supplicant"
sudo dnf -y install @base-x gnome-shell gnome-terminal nautilus firefox gnome-terminal-nautilus xdg-user-dirs xdg-user-dirs-gtk ffmpegthumbnailer gnome-calculator gnome-system-monitor gedit evince file-roller
sudo dnf -y install NetworkManager-config-connectivity-fedora bluedevil gnome-keyring-pam @"Hardware Support" @base-x @"Fonts" @"Common NetworkManager Submodules"

# UNINSTALL
clear
echo "UNINSTALL"
sudo dnf -y remove gnome-photos gnome-boxes gnome-text-editor evince simple-scan totem gnome-weather gnome-maps gnome-contacts eog baobab libreoffice* rhythmbox 
sudo dnf -y autoremove
echo "*************************************************************************************"
sleep 7

echo "\ndefaul Grafics:"
sudo numlockx on
sudo systemctl enable gdm
sudo systemctl set-default graphical.target
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
read -p "Add new user? (y/n)" a
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
