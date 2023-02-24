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


####################### UNINSTALL XFCE ###############################
clear
echo "UNINSTALL XFCE"
sleep 3
uninstall_xfce
########################## REPOSITORIES ###############################
clear
echo "ADD REPOSITORIES"
sleep 3
add_repos

########## FULL UPDATE ##########################################
clear
echo "FULL UPDATE"
sudo nala clean
sleep 3
sudo nala update; sudo nala upgrade -y; sudo nala install -f; sudo apt --fix-broken install
sudo aptitude safe-upgrade -y
sudo apt full-upgrade -y
sudo systemctl disable casper-md5check.service
reboot
