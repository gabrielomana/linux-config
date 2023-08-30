#!/bin/bash
# if [ "$(whoami)" != "root" ]
# then
#     sudo su -s "$0"
#     exit
# fi
date -s "$(wget --method=HEAD -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f2-7)"

###################### LANGUAGE ###############################
sudo apt install locales -y
sudo apt-get install locales-all -y
sudo apt-get install language-pack-es -y
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

###################### UPDATE ###############################
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

###################### BASICS PACKEGES ###############################
clear
echo "BASICS PACKEGES"
sleep 3
dir="$(pwd)"

sudo nala install aptitude curl wget apt-transport-https dirmngr lz4 sudo gpgv gnupg devscripts systemd-sysv software-properties-common ca-certificates dialog dkms cmake build-essential python3-pip pipx wireplumber pipewire-media-session-* libspa-0.2-bluetooth pulseaudio-module-bluetooth -y
sleep 5

clear
echo "OTHER BASICS PACKEGES"1
sleep 3

sudo nala install apt-xapian-index netselect-apt tree bash-completion util-linux build-essential console-setup debian-reference-es linux-base lsb-release make man-db manpages memtest86+ coreutils dos2unix usbutils bleachbit python3-venv python3-pip unrar-free zip rsync p7zip net-tools screen neofetch -y
sleep 3

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

###################### BRANCH ROLLING ###############################
clear
a=0
f=0
while [ $a -lt 1 ]
do
    read -p "Do you want to move to the Rolling branch?? " yn
    case $yn in
        [Yy]* ) a=1;rolling_branch;f=1;clear;;
        [Nn]* ) a=1;echo "OK";clear;;
        * ) echo "Please answer yes or no.";;
    esac
done

clear
if [ $f == 1 ]; then
    sudo wget https://sparkylinux.org/files/sparky-dist-upgrade78
    sudo chmod +x sparky-dist-upgrade78
    sudo ./sparky-dist-upgrade78
    sudo apt autoremove
    sudo apt clean
    sudo apt update
    sudo apt --fix-broken install
    sudo aptitude safe-upgrade -y
    sudo rm sparky-dist-upgrade78* -rf

    sudo rm /etc/apt/sources.list -f
    echo -e "deb http://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
    deb-src http://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
    deb http://security.debian.org/debian-security/ trixie-security/updates main contrib non-free non-free-firmware
    deb-src http://security.debian.org/debian-security/ trixie-security/updates main contrib non-free non-free-firmware
    deb http://deb.debian.org/debian testing-updates main contrib non-free non-free-firmware
    deb-src http://deb.debian.org/debian testing-updates main contrib non-free non-free-firmware
    deb http://deb-multimedia.org/ testing main non-free"  | sudo tee -a /etc/apt/sources.list
    sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade
    sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
    sleep 3
    sudo nala update
    sudo nala fetch --auto --fetches 5 -y
    sudo nala update; sudo nala upgrade -y; sudo nala install -f; sudo apt --fix-broken install
    clear
fi
clear
sudo reboot
