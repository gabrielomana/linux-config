#!/bin/bash
cp ~/.bashrc ~/.bashrc_original

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
#add_repos
######################### KDE PLASMA ###############################
clear
echo "INSTALL KDE PLASMA: "
sleep 3
#install_kde
######################### CORE APPS ###############################
clear
echo "INSTALL SYSTEM CORE APPS: "
sleep 3
install_core_apps

######################### MULTIMEDIA ###############################
clear
echo "INSTALL MULTIMEDIA APPS: "
sleep 3
install_multimedia


#########################################_END_ #################################################


########## FULL UPDATE ##########################################
clear
echo "FULL UPDATE"
sudo dnf clean all
sleep 3
sudo dnf update -y
sudo dnf upgrade -y
sudo dnf install -f -y

sudo reboot
