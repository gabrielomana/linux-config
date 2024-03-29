#!/bin/bash
cp ~/.bashrc ~/.bashrc_original

if command -v nala &> /dev/null; then
    sudo nala fetch --auto --fetches 5 -y
else
    if sudo apt install nala -y ; then
        sudo nala fetch --auto --fetches 5 -y
    fi
fi


sudo nala update

dir="$(pwd)"

codecs="${dir}/sources/lists/codecs.list"
exta_apps="${dir}/sources/lists/exta_apps.list"
kde_plasma="${dir}/sources/lists/kde_plasma.list"
kde_plasma_apps="${dir}/sources/lists/kde_plasma_apps.list"
multimedia="${dir}/sources/lists/multimedia.list"
tools="${dir}/sources/lists/tools.list"
utilities="${dir}/sources/lists/utilities.list"
xfce="${dir}/sources/lists/xfce.list"
kde_bloatware="${dir}/sources/lists/kde_bloatware.list"

. "${dir}"/sources/functions/functions


########################## REPOSITORIES ###############################
clear
echo "ADD REPOSITORIES"
sleep 3
add_repos
######################### KDE PLASMA ###############################
clear
echo "INSTALL KDE PLASMA: "
sleep 3
install_kde
# ######################### CORE APPS ###############################
clear
echo "INSTALL SYSTEM CORE APPS: "
sleep 3
install_core_apps

######################### MULTIMEDIA ###############################
clear
echo "INSTALL MULTIMEDIA APPS: "
sleep 3
install_multimedia

################################### FULL UPDATE ##########################################
clear
echo "FULL UPDATE"
sleep 3
sudo apt update
sudo apt full-upgrade -y
sudo dpkg --configure -a
sudo apt install -f
sudo apt autoremove
sudo apt clean
sudo apt update
sudo apt --fix-broken install
sudo aptitude safe-upgrade -y
sudo nala update; sudo nala upgrade -y; sudo nala install -f; sudo apt --fix-broken install
sudo reboot
