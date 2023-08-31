#!/bin/bash
dir="$(pwd)"
. "${dir}"/KDE_PLASMA/sources/functions/functions

date -s "$(wget --method=HEAD -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f2-7)"

# Instalación y configuración de idioma y locales
sudo apt update
sudo apt install locales -y
sudo apt-get install locales-all -y
sudo apt-get install language-pack-es -y
sudo locale-gen "es_ES.UTF-8"
sudo apt install hunspell-es -y
sudo localectl set-x11-keymap es,es
sudo update-locale LANG=es_ES.UTF-8
source /etc/default/locale

# Actualización del sistema
sudo apt update
sudo apt full-upgrade -y
sudo dpkg --configure -a
sudo apt install -f
sudo apt autoremove
sudo apt clean
sudo apt --fix-broken install
sudo aptitude safe-upgrade -y
sudo apt install linux-headers-$(uname -r) -y

# Instalación y actualización de NALA (si es necesario)
sudo apt install nala -y
sudo nala fetch --auto --fetches 5 -y
sudo nala update
sudo nala upgrade -y
sudo nala install -f

# Instalación de paquetes básicos
clear
echo "BASIC PACKAGES"
sleep 3
dir="$(pwd)"
sudo apt install aptitude curl wget apt-transport-https dirmngr lz4 sudo gpgv gnupg devscripts systemd-sysv software-properties-common ca-certificates dialog dkms cmake build-essential python3-pip pipx -y
sleep 5
clear

# Instalación de Pipewire y Wireplumber
# sudo apt install libfdk-aac2 libldacbt-{abr,enc}2 libopenaptx0 gstreamer1.0-pipewire libpipewire-0.3-{0,dev,modules} libspa-0.2-{bluetooth,dev,jack,modules} pipewire{,-{audio-client-libraries,pulse,bin,tests}} pipewire-doc libpipewire-* wireplumber{,-doc} gir1.2-wp-0.4 libwireplumber-0.4-{0,dev} pipewire pipewire-audio-client-libraries pipewire-media-session-* libspa-0.2-bluetooth -y
# sudo touch /etc/pipewire/media-session.d/with-pulseaudio
# sudo cp /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.* /etc/systemd/user/
# systemctl --user --now disable pulseaudio.{socket,service}
# systemctl --user mask pulseaudio
# systemctl --user --now enable pipewire{,-pulse}.{socket,service}
# systemctl --user --now enable wireplumber.service
# sleep 5
# clear

# Instalación de otros paquetes básicos
echo "OTHER BASIC PACKAGES"
sleep 3
sudo nala install apt-xapian-index netselect-apt tree bash-completion util-linux debian-reference-es linux-base lsb-release make man-db manpages memtest86+ coreutils dos2unix usbutils bleachbit python3-venv python3-pip unrar-free zip rsync p7zip net-tools screen neofetch -y
sleep 5
clear

# Configuración de Zswap, swappiness y actualización de Grub
clear
echo "ZSWAP+SWAPPINESS+GRUB"
sleep 3
echo "vm.swappiness=25" | sudo tee -a /etc/sysctl.conf
sudo cp /etc/default/grub /etc/default/grub_old
sudo cp "${dir}/dotfiles/grub" /etc/default/grub
sudo update-grub
echo "lz4" | sudo tee -a /etc/initramfs-tools/modules
echo "lz4_compress" | sudo tee -a /etc/initramfs-tools/modules
echo "z3fold" | sudo tee -a /etc/initramfs-tools/modules
sudo update-initramfs -u

