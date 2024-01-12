#!/bin/bash

# Guarda el directorio actual en una variable
dir="$(pwd)"

# Importa funciones desde el directorio indicado
. "${dir}/KDE_PLASMA/sources/functions/functions"

# # Actualiza la fecha y hora del sistema usando la respuesta de Google
# date -s "$(wget --method=HEAD -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f2-7)"

# # SUDO
# # Instala sudo si no está instalado
# if ! command -v sudo &> /dev/null; then
#     echo "sudo not found. Installing sudo..."
#     apt update
#     apt install sudo -y
# fi

# # Agrega el usuario actual al archivo sudoers
# echo "$USER ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

# # Verifica si se agregó la línea correctamente
# grep -q "$USER" /etc/sudoers && echo "User $USER successfully added to the sudoers list." || echo "Error adding user $USER to the sudoers list."

# # Instalación y configuración de idioma y locales
# clear
# sudo nala install locales locales-all language-pack-es hunspell-es -y
# sudo locale-gen "es_ES.UTF-8"
# sudo localectl set-x11-keymap es,es
# sudo update-locale LANG=es_ES.UTF-8
# source /etc/default/locale

# # Actualización del sistema
# sudo apt update
# sudo apt full-upgrade -y
# sudo dpkg --configure -a
# sudo apt install -f
# sudo apt clean
# sudo apt --fix-broken install
# sudo aptitude safe-upgrade -y
# sudo apt install linux-headers-$(uname -r) -y

# # Instalación y actualización de NALA (si es necesario)
# if ! command -v nala &> /dev/null; then
#     echo "NALA not found. Installing NALA..."
#     sudo apt install nala -y
# fi

# # Actualiza NALA si está instalado
# if command -v nala &> /dev/null; then
#     echo "Updating NALA..."
#     sudo nala fetch --auto --fetches 5 -y
#     sudo nala update
#     sudo nala upgrade -y
#     sudo nala install -f
# else
#     echo "NALA not installed. Skipping update."
# fi

# # Instalación de paquetes básicos
# clear
# echo "BASIC PACKAGES"
# sleep 3
# dir="$(pwd)"
# sudo nala install aptitude curl wget apt-transport-https dirmngr lz4 sudo gpgv gnupg devscripts systemd-sysv software-properties-common ca-certificates dialog dkms cmake build-essential python3-pip pipx -y
# sleep 5
# clear

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
        [Yy]* )
            a=1
            f=1
            clear
            ;;
        [Nn]* )
            a=1
            echo "OK"
            clear
            ;;
        * )
            echo "Please answer yes or no."
            ;;
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
  # Resto del código para cambiar a la rama "Rolling"
  clear
  echo "Cambiando a la rama Rolling..."
  sleep 3

  DEPS="bash coreutils dialog grep iputils-ping sparky-info sudo"

  # Verifica la conectividad a los servidores
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

  # Verifica que estás en Sparky 7 Orion Belt
  OSCODE="`sudo cat /etc/lsb-release | grep Orion`"
  if [ "$OSCODE" = "" ]; then
      echo "This is not Sparky 7 Orion Belt... exiting..."
      exit 1
  fi

  # Actualiza el archivo sources.list para cambiar a la rama "Rolling"
  sudo cp /etc/apt/sources.list /etc/apt/sources.list.bak  # Respaldamos el archivo original

  sudo rm /etc/apt/sources.list 
  echo -e "deb http://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
  deb-src http://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
  deb http://security.debian.org/debian-security testing-security main contrib non-free non-free-firmware
  deb-src http://security.debian.org/debian-security testing-security main contrib non-free non-free-firmware
  deb http://deb.debian.org/debian/ unstable main contrib non-free non-free-firmware
  deb-src http://deb.debian.org/debian/ unstable main contrib non-free non-free-firmware
  deb https://deb-multimedia.org/ testing main non-free" | sudo tee /etc/apt/sources.list

  sudo rm -f /etc/apt/sources.list.d/sparky.list
  echo -e "deb https://repo.sparkylinux.org/ core main
  deb-src https://repo.sparkylinux.org/ core main
  deb https://repo.sparkylinux.org/ sisters main
  deb-src https://repo.sparkylinux.org/ sisters main" | sudo tee /etc/apt/sources.list.d/sparky.list
  sudo apt update
  sudo mv /etc/apt/trusted.gpg "/etc/apt/trusted.gpg.d/sparky.gpg"
  sudo ln -s "/etc/apt/sparky.gpg" "/etc/apt/trusted.gpg.d/sparky.gpg"

  # Función para buscar y reemplazar en el archivo nala.list
    file_path="/etc/apt/sources.list.d/nala-sources.list"
    codename=$(curl -sL https://deb.debian.org/debian/dists/testing/InRelease | grep "^Codename:" | cut -d' ' -f2)
    if [ -f "$file_path" ]; then
        # Usa grep para verificar si la expresión ya existe en el archivo
        if grep -q "$codename" "$file_path"; then
            sudo sed -i "s/$codename/testing/g" "$file_path"
        else
            echo "La expresión no existe en el archivo $file_path."
        fi
    else
        echo "El archivo $file_path no existe."
    fi

  sudo curl -o /etc/apt/apt.conf.d/00default-release https://gist.githubusercontent.com/khimaros/21db936fa7885360f7bfe7f116b78daf/raw/698266fc043d6e906189b14e3428187ff0e7e7c8/00default-release

  sudo nala update
  sudo nala upgrade -y
  # sudo apt full-upgrade -y
  # sudo apt dist-upgrade -y
  # sudo dpkg --configure -a
  # sudo apt install -f
  # sudo apt autoremove -y
  # sudo aptitude safe-upgrade -y

  # Puedes agregar más comandos según sea necesario.
fi

# Comentario final
# sudo reboot
