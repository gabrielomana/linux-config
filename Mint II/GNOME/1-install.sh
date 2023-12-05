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
gnome="${dir}/sources/lists/gnome.list"
multimedia="${dir}/sources/lists/multimedia.list"
tools="${dir}/sources/lists/tools.list"
utilities="${dir}/sources/lists/utilities.list"
xfce="${dir}/sources/lists/xfce.list"
gnome_bloatware="${dir}/sources/lists/gnome_bloatware.list"
gnome_vanilla="${dir}/sources/lists/gnome_vanilla.list"
gnome_extra_apps="${dir}/sources/lists/gnome_extra_apps.list"


. "${dir}"/sources/functions/functions


###################### UNINSTALL XFCE ###############################
clear
echo "UNINSTALL XFCE"
sleep 3
uninstall_xfce
########################## REPOSITORIES ###############################
clear
echo "ADD REPOSITORIES"
sleep 3
add_repos
######################### KDE PLASMA ###############################
clear
echo "INSTALL GNOME: "
sleep 3
install_gnome
######################### CORE APPS ###############################
clear
echo "INSTALL SYSTEM CORE APPS: "
sleep 3
install_core_apps
#
# ######################### MULTIMEDIA ###############################
clear
echo "INSTALL MULTIMEDIA APPS: "
sleep 3
install_multimedia

# ######################### MULTIMEDIA ###############################
clear
echo "INSTALL NEMO: "
sleep 3
install_nemo


# #########################################_END_ #################################################
#
# ########## FULL UPDATE ##########################################
clear
echo "FULL UPDATE"
sudo nala clean
sleep 3
#echo -e "deb http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse" | sudo tee -a /etc/apt/sources.list.d/official-package-repositories.list
#echo -e "deb-src http://archive.ubuntu.com/ubuntu/ jammy-backports main restricted universe multiverse"| sudo tee -a /etc/apt/sources.list.d/official-source-repositories.list
##### CLEAN ANH GET MISSINGS KEYS ####
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
sudo nala update
clear
sudo nala upgrade -y; sudo nala install -f; sudo apt --fix-broken install
sudo aptitude safe-upgrade -y
sudo apt full-upgrade -y
sudo systemctl disable casper-md5check.service
reboot
