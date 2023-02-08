#!/bin/bash

if command -v nala &> /dev/null; then
    sudo nala fetch --auto --fetches 5 -y
else
    if sudo apt install nala -y ; then
        sudo nala fetch --auto --fetches 5 -y
    fi
fi

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
######################### KDE PLASMA ###############################
clear
echo "INSTALL KDE PLASMA: "
sleep 3
install_kde
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


########################################## EXTRA APPS #########################################
clear
echo "EXTRA APPS: "
install_extra_apps

#########################################_END_ #################################################


########## CARGO & TOPGRADE #####################################
clear
echo "CARGO & TOPGRADE"
sleep 3
cargo install cargo-update
cargo install topgrade
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee -a ~/.bashrc
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee -a /root/.bashrc


########## KONSOLE #############################################
clear
echo "KONSOLE & DOTFILES"
sleep 3
sudo cp style/colors/* /usr/share/konsole/ -rf
cp -r files/konsole.profile ~/.local/share/konsole/konsole.profile
cp -r files/neofetch.conf ~/.config/neofetch/config.conf
cp -r files/topgrade.toml ~/.config/topgrade.toml

########## FULL UPDATE ##########################################
clear
echo "FULL UPDATE"
sudo nala clean
sleep 3
sudo nala update; sudo nala upgrade -y; sudo nala install -f; sudo dpkg --configure -a; sudo nala autoremove; sudo apt --fix-broken install
sudo apt full-upgrade -y
sudo aptitude safe-upgrade -y
sudo systemctl disable casper-md5check.service
reboot
