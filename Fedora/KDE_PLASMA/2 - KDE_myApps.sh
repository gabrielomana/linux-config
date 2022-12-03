#!/bin/bash

#REPOSITORIES  *******************************************#
#sudo dnf -y install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
#sudo dnf -y install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
#sudo dnf -y install fedora-workstation-repositories
#sudo dnf config-manager --set-enabled google-chrome
sudo dnf -y copr enable refi64/webapp-manager
sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc

sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

curl -1sLf \
   'https://dl.cloudsmith.io/public/balena/etcher/setup.rpm.sh' \
   | sudo -E bash

sudo yum -y install https://download.onlyoffice.com/repo/centos/main/noarch/onlyoffice-repo.noarch.rpm
sudo dnf -y copr enable ayoungdukie/Personal_Repo 

sudo rpm --import https://raw.githubusercontent.com/UnitedRPMs/unitedrpms/master/URPMS-GPG-PUBLICKEY-Fedora
sudo dnf -y install https://github.com/UnitedRPMs/unitedrpms/releases/download/20/unitedrpms-$(rpm -E %fedora)-20.fc$(rpm -E %fedora).noarch.rpm

sudo dnf makecache --refresh


# FONTS
sudo rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
sudo dnf install -y dejavu-fonts* google-roboto-fonts
sudo fc-cache -fv



#INTERNET  *******************************************#
sudo dnf install -y \
brave-browser \
filezilla

flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y
flatpak install flathub us.zoom.Zoom -y
flatpak install flathub com.anydesk.Anydesk -y
flatpak install flathub com.microsoft.Teams -y


#OFIMATICA  ******************************************#
sudo yum install onlyoffice-desktopeditors -y

#*****************************************************#


#MULTIMEDIA  *****************************************#
sudo dnf install -y \
clementine

sudo timedatectl set-local-rtc 1

flatpak install flathub app.ytmdesktop.ytmdesktop -y
flatpak install flathub tv.kodi.Kodi -y
flatpak install flathub com.github.bajoja.indicator-kdeconnect -y


#HERRAMIENTAS  ***************************************#

sudo dnf install -y \
qemu qemu-kvm libvirt libvirt-devel virt-top libguestfs-tools guestfs-tools bridge-utils virt-manager
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

#SISTEMA   *******************************************#

sudo dnf -y install webapp-manager
sudo yum -y localinstall https://github.com/TheAssassin/AppImageLauncher/releases/download/v2.2.0/appimagelauncher-2.2.0-travis995.0f91801.x86_64.rpm

sudo dnf -y install balena-etcher-electron
sudo cargo install cargo-update

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
reboot
