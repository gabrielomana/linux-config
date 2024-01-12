#!/bin/bash

# Guarda el directorio actual en una variable
dir="$(pwd)"

# Importa funciones desde el directorio indicado
. "${dir}/KDE_PLASMA/sources/functions/functions"

# # Actualiza la fecha y hora del sistema usando la respuesta de Google
# date -s "$(wget --method=HEAD -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f2-7)"


# # Actualización del sistema
# sudo nala fetch --auto --fetches 5 -y
# sudo nala update
# sudo nala upgrade -y


# # Instalación y configuración de idioma y locales
# clear
# sudo nala install locales locales-all language-pack-es hunspell-es -y
# sudo locale-gen "es_ES.UTF-8"
# sudo localectl set-x11-keymap es,es
# sudo update-locale LANG=es_ES.UTF-8
# source /etc/default/locale

# # Instalación de paquetes básicos
# clear
# echo "BASIC PACKAGES"
# sleep 3
# dir="$(pwd)"
# sudo nala install aptitude curl wget apt-transport-https dirmngr lz4 sudo gpgv gnupg devscripts systemd-sysv software-properties-common ca-certificates dialog dkms cmake build-essential python3-pip pipx -y
# sleep 5
# clear

# # Instalación de Pipewire y Wireplumber
# # sudo apt install libfdk-aac2 libldacbt-{abr,enc}2 libopenaptx0 gstreamer1.0-pipewire libpipewire-0.3-{0,dev,modules} libspa-0.2-{bluetooth,dev,jack,modules} pipewire{,-{audio-client-libraries,pulse,bin,tests}} pipewire-doc libpipewire-* wireplumber{,-doc} gir1.2-wp-0.4 libwireplumber-0.4-{0,dev} pipewire pipewire-audio-client-libraries pipewire-media-session-* libspa-0.2-bluetooth -y
# # sudo touch /etc/pipewire/media-session.d/with-pulseaudio
# # sudo cp /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.* /etc/systemd/user/
# # systemctl --user --now disable pulseaudio.{socket,service}
# # systemctl --user mask pulseaudio
# # systemctl --user --now enable pipewire{,-pulse}.{socket,service}
# # systemctl --user --now enable wireplumber.service
# # sleep 5
# # clear

# # Instalación de otros paquetes básicos
# echo "OTHER BASIC PACKAGES"
# sleep 3
# sudo nala install apt-xapian-index netselect-apt tree bash-completion util-linux debian-reference-es linux-base lsb-release make man-db manpages memtest86+ coreutils dos2unix usbutils bleachbit python3-venv python3-pip unrar-free zip rsync p7zip net-tools screen neofetch -y
# sleep 5
# clear

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
while [ $a -lt 1 ]
do
        read -p "¿Quieres cambiar a la rama Rolling?" yn
        case $yn in
            [Yy]* ) a=1;f=1;clear;;
            [Nn]* ) a=1;echo "OK";clear;;
            * ) echo "Please answer yes or no.";;
        esac
    done

if [ $f == 1 ]; then

    DEPS="bash coreutils dialog grep iputils-ping sparky-info sudo"

    PINGTEST0=$(sudo ping -c 1 debian.org | grep [0-9])
    if [ "$PINGTEST0" = "" ]; then
        echo "Debian server is offline... exiting..."
        exit 1
    fi

    PINGTEST1=$(sudo ping -c 1 sparkylinux.org | grep [0-9])
    if [ "$PINGTEST1" = "" ]; then
        echo "Sparky server is offline... exiting..."
        exit 1
    fi

    OSCODE="`sudo cat /etc/lsb-release | grep Orion`"
    if [ "$OSCODE" = "" ]; then
        echo "This is not Sparky 7 Orion Belt... exiting..."
        exit 1
    fi

  # Update Debian and Sparky repositories
  sudo rm -f /etc/apt/sources.list

  echo -e "deb http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
  deb-src http://deb.debian.org/debian trixie main contrib non-free non-free-firmware
  deb http://security.debian.org/debian-security/ trixie-security/updates main contrib non-free non-free-firmware
  deb-src http://security.debian.org/debian-security/ trixie-security/updates main contrib non-free non-free-firmware
  deb http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
  deb-src http://deb.debian.org/debian trixie-updates main contrib non-free non-free-firmware
  deb http://deb-multimedia.org/ trixie main non-free" | sudo tee /etc/apt/sources.list


  sudo rm -f /etc/apt/sources.list.d/sparky.list

  echo -e "deb https://repo.sparkylinux.org/ core main
  deb-src https://repo.sparkylinux.org/ core main
  deb https://repo.sparkylinux.org/ sisters main
  deb-src https://repo.sparkylinux.org/ sisters main" | sudo tee /etc/apt/sources.list.d/sparky.list

  sudo apt update
  sudo apt full-upgrade -y
  sudo dpkg --configure -a
  sudo apt install -f
  sudo dpkg-reconfigure -a
  sudo apt install -f

  # Switch to testing
  sudo rm /etc/apt/sources.list
  
  echo -e "deb http://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
  deb-src http://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
  deb http://security.debian.org/debian-security testing-security main contrib non-free non-free-firmware
  deb-src http://security.debian.org/debian-security testing-security main contrib non-free non-free-firmware
  deb http://deb.debian.org/debian/ unstable main contrib non-free non-free-firmware
  deb-src http://deb.debian.org/debian/ unstable main contrib non-free non-free-firmware
  deb https://deb-multimedia.org/ testing main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list

  #Config Unstable Security Updates
    # Pre-requisitos e instalación
    sudo apt install -y debsecan
    set -ex
    curl -o - https://gist.githubusercontent.com/khimaros/21db936fa7885360f7bfe7f116b78daf/raw/698266fc043d6e906189b14e3428187ff0e7e7c8/00default-release | sudo tee /etc/apt/apt.conf.d/00default-release > /dev/null
    curl -o - https://gist.githubusercontent.com/khimaros/21db936fa7885360f7bfe7f116b78daf/raw/698266fc043d6e906189b14e3428187ff0e7e7c8/debsecan-apt-priority | sudo tee /usr/sbin/debsecan-apt-priority > /dev/null
    curl -o - https://gist.githubusercontent.com/khimaros/21db936fa7885360f7bfe7f116b78daf/raw/698266fc043d6e906189b14e3428187ff0e7e7c8/99debsecan | sudo tee /etc/apt/apt.conf.d/99debsecan > /dev/null
    sudo chmod 755 /usr/sbin/debsecan-apt-priority
    sudo ln -sf /var/lib/debsecan/apt_preferences /etc/apt/preferences.d/unstable-security-packages

    sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get full-upgrade -y && sudo apt-get dist-upgrade -y && sudo apt --fix-broken install && sudo aptitude safe-upgrade -y
    sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
    sleep 3
    sudo nala fetch --auto --fetches 5 -y
    sudo nala update
    clear

fi
sudo reboot
