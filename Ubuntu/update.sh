#!/bin/bash
clear
echo -e "FULL UPDATE\n"
sudo apt clean -y
sudo apt update -y && sudo apt upgrade -y && sudo apt full-upgrade -y
clear
# LANGUAGE
echo "LANGUAGE"
sudo apt clean
sudo apt-get -y install language-pack-es
sudo apt-get -y install language-pack-es-base
echo -e "LANG=\"es_ES.UTF-8\"\nLC_ALL=\"es_ES.UTF-8\"\nLANGUAGE=\"es_ES\"" | sudo tee /etc/environment
echo -e "LANG=\"es_ES.UTF-8\"\nLC_ALL=\"es_ES.UTF-8\"\nLANGUAGE=\"es_ES\"" | sudo tee /etc/default/locale
echo -e "es_ES.UTF-8 UTF-8\nen_US.UTF-8 UTF-8" | sudo tee /var/lib/locales/supported.d/local
sudo dpkg-reconfigure locales
sudo apt install -y dos2unix
sudo chmod 777 ~/linux-config/Ubuntu/GNOME/*.sh
sudo chmod 777 ~/linux-config/Ubuntu/KDE_PLASMA/*.sh
dos2unix ~/linux-config/Ubuntu/GNOME/*.sh
dos2unix ~/linux-config/Ubuntu/KDE_PLASMA/*.sh

#SUDO
me="$(whoami)"
clear
echo -e "RUN THIS COMMAND: usermod -aG sudo "$me"\n"
sudo su



