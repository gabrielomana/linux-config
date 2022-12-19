#!/bin/bash
clear

#REPOSITORIES  *******************************************#
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list

curl -1sLf \
   'https://dl.cloudsmith.io/public/balena/etcher/setup.deb.sh' \
   | sudo -E bash


sudo apt update
clear
mintsources
clear
sudo apt update
#*****************************************************#


# FONTS *******************************************#
sudo apt install -y ttf-mscorefonts-installer fonts-dejavu fonts-freefont-ttf ttf-bitstream-vera fonts-freefont-otf fonts-lyx xfonts-100dpi xfonts-75dpi fonts-roboto-hinted fonts-roboto-unhinted | tee 2> install.log
#*****************************************************#

#INTERNET  *******************************************#
sudo apt install -y \
brave-browser \
filezilla

flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y
#flatpak install flathub us.zoom.Zoom -y
#flatpak install flathub com.anydesk.Anydesk -y
#flatpak install flathub com.microsoft.Teams -y
#*****************************************************#


#MULTIMEDIA  *****************************************#
sudo timedatectl set-local-rtc 1
flatpak install flathub app.ytmdesktop.ytmdesktop -y
flatpak install flathub tv.kodi.Kodi -y
#*****************************************************#


#HERRAMIENTAS  ***************************************#
sudo apt install -y \
qemu qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virtinst virt-manager virt-viewer virt-top libguestfs-tools guestfs-tools virt-manager
sudo systemctl start libvirtd
sudo systemctl enable libvirtd
#*****************************************************#


#SISTEMA   *******************************************#
sudo apt -y install balena-etcher-electron
sudo cargo install cargo-update
flatpak install flathub org.phoenicis.playonlinux -y
flatpak install flathub com.usebottles.bottles -y
#*****************************************************#


# UPDATE & UPGRADE
cargo install topgrade
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.bashrc
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.bashrc

sudo apt clean -y
sudo apt update -y && sudo apt upgrade -y && sudo apt full-upgrade -y
sudo aptitude safe-upgrade -y

sudo bleachbit
sudo apt update -y
mintsources

#ZSH
clear
echo -e "ZSH"
sudo apt -y install zsh
sudo chsh -s $(which zsh)
sudo chsh -s /usr/bin/zsh $USER
chsh -s $(which zsh)
chsh -s /usr/bin/zsh $USER
sudo mkdir ~/.fonts
sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf -P /usr/share/fonts/
sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf -P /usr/share/fonts/
sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf -P /usr/share/fonts/
sudo wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf -P /usr/share/fonts/
fc-cache -f -v

reboot

