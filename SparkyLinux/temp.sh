#!/bin/bash
dir="$(pwd)"

. "${dir}"/sources/functions/functions

# date -s "$(wget --method=HEAD -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f2-7)"
#
# # Instalación y configuración de idioma y locales
# sudo apt update
# sudo apt install locales -y
# sudo apt-get install locales-all -y
# sudo apt-get install language-pack-es -y
# sudo locale-gen "es_ES.UTF-8"
# sudo apt install hunspell-es -y
# sudo localectl set-x11-keymap es,es
# sudo update-locale LANG=es_ES.UTF-8
# source /etc/default/locale
#
# # Actualización del sistema
# sudo apt update
# sudo apt full-upgrade -y
# sudo dpkg --configure -a
# sudo apt install -f
# sudo apt autoremove
# sudo apt clean
# sudo apt --fix-broken install
# sudo aptitude safe-upgrade -y
# sudo apt install linux-headers-$(uname -r) -y
#
# # Instalación y actualización de NALA (si es necesario)
# sudo apt install nala -y
# sudo nala fetch --auto --fetches 5 -y
# sudo nala update
# sudo nala upgrade -y
# sudo nala install -f
#
# # Instalación de paquetes básicos
# clear
# echo "BASIC PACKAGES"
# sleep 3
# dir="$(pwd)"
# sudo apt install aptitude curl wget apt-transport-https dirmngr lz4 sudo gpgv gnupg devscripts systemd-sysv software-properties-common ca-certificates dialog dkms cmake build-essential python3-pip pipx -y
# sleep 5
# clear
#
# # Instalación de Pipewire y Wireplumber
# sudo apt install libfdk-aac2 libldacbt-{abr,enc}2 libopenaptx0 gstreamer1.0-pipewire libpipewire-0.3-{0,dev,modules} libspa-0.2-{bluetooth,dev,jack,modules} pipewire{,-{audio-client-libraries,pulse,bin,tests}} pipewire-doc libpipewire-* wireplumber{,-doc} gir1.2-wp-0.4 libwireplumber-0.4-{0,dev} pipewire pipewire-audio-client-libraries pipewire-media-session-* libspa-0.2-bluetooth -y
# sudo touch /etc/pipewire/media-session.d/with-pulseaudio
# sudo cp /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.* /etc/systemd/user/
# systemctl --user --now disable pulseaudio.{socket,service}
# systemctl --user mask pulseaudio
# systemctl --user --now enable pipewire{,-pulse}.{socket,service}
# systemctl --user --now enable wireplumber.service
# sleep 5
# clear
#
# # Instalación de otros paquetes básicos
# echo "OTHER BASIC PACKAGES"
# sleep 3
# sudo nala install apt-xapian-index netselect-apt tree bash-completion util-linux debian-reference-es linux-base lsb-release make man-db manpages memtest86+ coreutils dos2unix usbutils bleachbit python3-venv python3-pip unrar-free zip rsync p7zip net-tools screen neofetch -y
# sleep 5
# clear
#
# # Configuración de Zswap, swappiness y actualización de Grub
# clear
# echo "ZSWAP+SWAPPINESS+GRUB"
# sleep 3
# echo "vm.swappiness=25" | sudo tee -a /etc/sysctl.conf
# sudo cp /etc/default/grub /etc/default/grub_old
# sudo cp "${dir}/dotfiles/grub" /etc/default/grub
# sudo update-grub
# echo "lz4" | sudo tee -a /etc/initramfs-tools/modules
# echo "lz4_compress" | sudo tee -a /etc/initramfs-tools/modules
# echo "z3fold" | sudo tee -a /etc/initramfs-tools/modules
# sudo update-initramfs -u

# Reinicio opcional a la rama "Rolling"
clear
a=0
f=0
while [ $a -lt 1 ]; do
    read -p "¿Quieres cambiar a la rama Rolling? " yn
    case $yn in
        [Yy]* ) a=1; rolling_branch; f=1; clear;;
        [Nn]* ) a=1; echo "OK"; clear;;
        * ) echo "Por favor, responde sí o no.";;
    esac
done

if [ $f == 1 ]; then
 DEPS="bash coreutils dialog grep iputils-ping sparky-info sudo"

  PINGTEST0=$(ping -c 1 debian.org | grep [0-9])
  if [ -z "$PINGTEST0" ]; then
    echo "Debian server is offline... exiting..."
    exit 1
  fi

  PINGTEST1=$(ping -c 1 sparkylinux.org | grep [0-9])
  if [ -z "$PINGTEST1" ]; then
    echo "Sparky server is offline... exiting..."
    exit 1
  fi

  OSCODE=$(grep Orion /etc/lsb-release)
  if [ -z "$OSCODE" ]; then
    echo "This is not Sparky 7 Orion Belt... exiting..."
    exit 1
  fi

  sudo rm -f /etc/apt/sources.list
  echo -e "deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security/ trixie-security/updates main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security/ trixie-security/updates main contrib non-free non-free-firmware
deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
deb http://deb-multimedia.org/ trixie main non-free" | sudo tee -a /etc/apt/sources.list

  sudo rm -f /etc/apt/sources.list.d/sparky.list
  echo -e "deb https://repo.sparkylinux.org/ core main
deb-src https://repo.sparkylinux.org/ core main
deb https://repo.sparkylinux.org/ sisters main
deb-src https://repo.sparkylinux.org/ sisters main" | sudo tee -a /etc/apt/sources.list.d/sparky.list

  sudo apt update
  sudo apt full-upgrade
  sudo dpkg --configure -a
  sudo apt install -f

  sudo apt autoremove
  sudo apt clean
  sudo apt update
  sudo apt --fix-broken install
  sudo aptitude safe-upgrade -y

  # Move to testing
  clear
  sudo rm /etc/apt/sources.list -f
  echo -e "deb https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb https://security.debian.org/debian-security/ trixie-security/updates main contrib non-free non-free-firmware
deb-src https://security.debian.org/debian-security/ trixie-security/updates main contrib non-free non-free-firmware
deb https://deb.debian.org/debian testing-updates main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian testing-updates main contrib non-free non-free-firmware
deb https://deb-multimedia.org/ testing main non-free" | sudo tee -a /etc/apt/sources.list

  sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade
  sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
  sleep 3
  sudo nala update
  sudo nala fetch --auto --fetches 5 -y
  sudo nala update && sudo nala upgrade -y && sudo nala install -f && sudo apt --fix-broken install
  clear

fi
return

# Reiniciar el sistema
#sudo reboot
