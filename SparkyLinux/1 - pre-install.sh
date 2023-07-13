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
sudo dpkg-reconfigure locales
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

sudo rm /etc/apt/sources.list -f
echo -e "deb https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb https://deb.debian.org/debian-security/ testing-security main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian-security/ testing-security main contrib non-free non-free-firmware
deb https://deb.debian.org/debian/ testing-updates main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ testing-updates main contrib non-free non-free-firmware
deb https://www.deb-multimedia.org testing main non-free"  | sudo tee -a /etc/apt/sources.list

sudo sed 's/orion/sisters/g' /etc/apt/sources.list.d/sparky.list

#UPGRADE
sudo sparky-upgrade -y
sudo dpkg --configure -a

##PIPEWIRE
sudo apt install wireplumber pipewire-media-session- -y
sudo apt install libspa-0.2-bluetooth pulseaudio-module-bluetooth -y


##NALA
sudo apt install nala -y

########### FULL UPDATE ##########################################
clear
echo "FULL UPDATE"
sudo apt-get upgrade --with-new-pkgs --autoremove -y
sudo apt --fix-missing update
sudo apt update
sudo apt install -f
sudo dpkg --configure -a
sudo dpkg -l | grep ^..r | cut  -d " " -f 3 | xargs sudo dpkg --remove --force-remove-reinstreq


sudo apt autoremove
sudo apt clean
sudo apt update
sudo apt install linux-headers-$(uname -r) -y



########### MX REPOS ##########################################

# echo "MX REPOS"
# deb_cn=$(curl -s https://deb.debian.org/debian/dists/stable/Release | grep ^Codename: | tail -n1 | awk '{print $2}')
# deb_cn="$(echo "$deb_cn" | tr -d ' ')"
# echo -e "deb https://mxrepo.com/mx/repo/ $deb_cn main non-free" | sudo tee -a /etc/apt/sources.list.d/mx.list
#
# sudo rm /etc/apt/trusted.gpg -rf
# sudo curl -s https://mxrepo.com/mx23repo.asc | sudo apt-key add -
# if test -f "/etc/apt/trusted.gpg"; then
# sudo mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
# sudo ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
# sleep 5
# echo " "
# fi
#
# echo -e "Package: firefox
# Pin: release a=mx
# Pin-Priority: 500
#
# Package: *
# Pin: release a=mx
# Pin-Priority: 1" | sudo tee -a /etc/apt/preferences.d/99mx.pref
#
# sudo apt clean
# sudo apt update
#
# sudo nala fetch --auto --fetches 5 -y
# sudo nala update
# sudo nala upgrade -y


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
