#!/bin/bash
# #FULL UPDATE
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
sudo dpkg-reconfigure locales
sudo chmod 777 linux-cnfig/Ubuntu/Gnome/*sh
sudo chmod 777 linux-cnfig/Ubuntu/KDE_PLASMA/*sh
reboot