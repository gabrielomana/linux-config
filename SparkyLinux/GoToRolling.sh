#!/bin/bash
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
  echo -e "deb http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ trixie main contrib non-free non-free-firmware
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

  # Switch to testing
  sudo rm /etc/apt/sources.list
  echo -e "deb https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb https://security.debian.org/debian-security/ trixie-security/updates main contrib non-free non-free-firmware
deb-src https://security.debian.org/debian-security/ trixie-security/updates main contrib non-free non-free-firmware
deb https://deb.debian.org/debian testing-updates main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian testing-updates main contrib non-free non-free-firmware
deb https://deb-multimedia.org/ testing main non-free" | sudo tee /etc/apt/sources.list

  sudo apt-get update && sudo apt-get upgrade -y && sudo apt-get full-upgrade -y && sudo apt-get dist-upgrade -y && && sudo apt --fix-broken install && sudo aptitude safe-upgrade -y
  sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
  sleep 3
  sudo nala fetch --auto --fetches 5 -y
  sudo nala update
  clear

fi
sudo reboot
