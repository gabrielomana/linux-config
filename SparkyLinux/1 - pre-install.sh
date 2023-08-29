#!/bin/bash
# if [ "$(whoami)" != "root" ]
# then
#     sudo su -s "$0"
#     exit
# fi
# date -s "$(wget --method=HEAD -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f2-7)"

###################### LANGUAGE ###############################
sudo apt install locales -y
sudo apt-get install locales-all -y
sudo apt-get install language-pack-es -y
#sudo dpkg-reconfigure locales
sudo locale-gen "es_ES.UTF-8"
sudo apt install hunspell-es -y
sudo setxkbmap -layout 'es,es'
export LC_ALL="es_ES.UTF-8"
export LANGUAGE=\"es_ES.UTF-8\"
export LC_CTYPE="es_ES.UTF-8"
export LC_NUMERIC="es_ES.UTF-8"
export LC_TIME="es_ES.UTF-8"
export LC_COLLATE="es_ES.UTF-8"
export LC_MONETARY="es_ES.UTF-8"
export LC_MESSAGES="es_ES.UTF-8"
export LC_PAPER="es_ES.UTF-8"
export LC_NAME="es_ES.UTF-8"
export LC_ADDRESS="es_ES.UTF-8"
export LC_TELEPHONE="es_ES.UTF-8"
export LC_MEASUREMENT="es_ES.UTF-8"
export LC_IDENTIFICATION="es_ES.UTF-8"

###################### BASICS PACKEGES ###############################
clear
echo "BASICS PACKEGES"
sleep 3
dir="$(pwd)"

sudo apt install aptitude curl wget apt-transport-https dirmngr lz4 sudo gpgv gnupg devscripts systemd-sysv software-properties-common ca-certificates dialog dkms isenkram-cli cmake build-essential python3-pip pipx -y
sleep 5
sudo rm /etc/apt/sources.list.d/isenkram-autoinstall-firmware.list

###################### BRANCH DEBIAN (REPOS) ###############################
#
# sudo rm /etc/apt/sources.list -f
# echo -e "deb https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
# deb-src https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
# deb https://deb.debian.org/debian-security/ testing-security main contrib non-free non-free-firmware
# deb-src https://deb.debian.org/debian-security/ testing-security main contrib non-free non-free-firmware
# deb https://deb.debian.org/debian/ testing-updates main contrib non-free non-free-firmware
# deb-src https://deb.debian.org/debian/ testing-updates main contrib non-free non-free-firmware
# deb https://www.deb-multimedia.org testing main non-free"  | sudo tee -a /etc/apt/sources.list
#
# sudo rm -f /etc/apt/sources.list.d/sparky.list
# echo -e "deb https://repo.sparkylinux.org/ core main
# deb-src https://repo.sparkylinux.org/ core main
# deb https://repo.sparkylinux.org/ sisters main
# deb-src https://repo.sparkylinux.org/ sisters main"  | sudo tee -a /etc/apt/sources.list.d/sparky.list

sudo apt update
sudo apt full-upgrade -y
sudo dpkg --configure -a
sudo apt install -f
sudo apt autoremove
sudo apt clean
sudo apt update
sudo apt --fix-broken install
sudo aptitude safe-upgrade -y
sudo apt install linux-headers-$(uname -r) -y


##NALA
sudo apt install nala -y
sudo nala fetch --auto --fetches 5 -y
sudo nala update; sudo nala upgrade -y; sudo nala install -f;

##PIPEWIRE
sudo apt install wireplumber pipewire-media-session- -y
sudo apt install libspa-0.2-bluetooth pulseaudio-module-bluetooth -y


###################### OTHER BASICS PACKEGES ###############################
clear
echo "OTHER BASICS PACKEGES"1
sleep 3

sudo nala install apt-xapian-index netselect-apt tree bash-completion util-linux build-essential console-setup debian-reference-es linux-base lsb-release make man-db manpages memtest86+ coreutils dos2unix usbutils unrar-free zip rsync p7zip net-tools screen neofetch -y

####################### ZSWAP+SWAPPINESS+GRUB ###############################
clear
echo "ZSWAP+SWAPPINESS+GRUB"
sleep 3
echo -e "vm.swappiness=25" | sudo tee -a /etc/sysctl.conf

sudo cp /etc/default/grub /etc/default/grub_old
sudo cp ${dir}/dotfiles/grub /etc/default/grub
sudo update-grub

echo -e 'lz4' | sudo tee -a /etc/initramfs-tools/modules
echo -e 'lz4_compress' | sudo tee -a /etc/initramfs-tools/modules
echo -e 'z3fold' | sudo tee -a /etc/initramfs-tools/modules

sudo update-initramfs -u

###################### FIRMWARE ###############################
clear
echo "FIRMWARE"
sleep 3
isenkram-autoinstall-firmware
sudo reboot
