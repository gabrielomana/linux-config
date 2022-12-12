#!/bin/bash

#REPOSITORIES  *******************************************#
sudo apt install -y apt-transport-https curl
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main"|sudo tee /etc/apt/sources.list.d/brave-browser-release.list


mkdir -p ~/.gnupg
chmod 700 ~/.gnupg
gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
chmod 644 /tmp/onlyoffice.gpg
sudo chown root:root /tmp/onlyoffice.gpg
sudo mv /tmp/onlyoffice.gpg /etc/apt/trusted.gpg.d/
echo 'deb https://download.onlyoffice.com/repo/debian squeeze main' | sudo tee -a /etc/apt/sources.list.d/onlyoffice.list

curl -1sLf \
   'https://dl.cloudsmith.io/public/balena/etcher/setup.deb.sh' \
   | sudo -E bash

sudo apt update

# FONTS
sudo apt install -y ttf-mscorefonts-installer fonts-dejavu fonts-freefont-ttf ttf-bitstream-vera fonts-freefont-otf fonts-lyx xfonts-100dpi xfonts-75dpi fonts-roboto-hinted fonts-roboto-unhinted | tee 2> install.log




#INTERNET  *******************************************#
sudo apt install -y \
brave-browser \
filezilla

flatpak install flathub io.github.mimbrero.WhatsAppDesktop -y
flatpak install flathub us.zoom.Zoom -y
flatpak install flathub com.anydesk.Anydesk -y
flatpak install flathub com.microsoft.Teams -y


#OFIMATICA  ******************************************#
sudo apt-get install onlyoffice-desktopeditors -y

#*****************************************************#


#MULTIMEDIA  *****************************************#

sudo timedatectl set-local-rtc 1

flatpak install flathub app.ytmdesktop.ytmdesktop -y
flatpak install flathub tv.kodi.Kodi -y
flatpak install flathub com.github.bajoja.indicator-kdeconnect -y


#HERRAMIENTAS  ***************************************#

sudo apt install -y \
qemu qemu-kvm libvirt-clients libvirt-daemon-system bridge-utils virtinst virt-manager virt-viewer virt-top libguestfs-tools guestfs-tools virt-manager
sudo systemctl start libvirtd
sudo systemctl enable libvirtd

#SISTEMA   *******************************************#

sudo apt -y install balena-etcher-electron
sudo cargo install cargo-update

flatpak install flathub org.phoenicis.playonlinux -y
flatpak install flathub com.usebottles.bottles -y


#*****************************************************#


# UPDATE & UPGRADE
sudo cargo install topgrade
sudo cp -r Files/topgrade.toml ~/.config/topgrade.toml
sudo cp -r Files/topgrade.toml /root/.config/topgrade.toml
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.config/zsh_config/zsh_path
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.config/zsh_config/zsh_path
sudo topgrade

sudo bleachbit
reboot
