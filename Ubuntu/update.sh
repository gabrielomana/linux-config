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
sudo chmod 777 linux-cnfig/Ubuntu/Gnome/*sh
sudo chmod 777 linux-cnfig/Ubuntu/KDE_PLASMA/*sh
dos2unix linux-cnfig/Ubuntu/Gnome/*sh
dos2unix linux-cnfig/Ubuntu/KDE_PLASMA/*sh
reboot 
