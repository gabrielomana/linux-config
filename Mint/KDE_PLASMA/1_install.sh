#!/bin/bash
#sudo apt install nala -y
#sudo nala fetch --auto --fetches 5 -y

clear
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
echo "UNINSTALL XFCE: "
sleep 3
#uninstall_xfce
# # ######################## REPOSITORIES ###############################
 clear
 echo "ADD REPOSITORIES"
 sleep 3
 #add_repos
# ######################## KDE PLASMA ###############################
 clear
 echo "INSTALL KDE PLASMA: "
 sleep 3
 install_kde
# ######################## CORE APPS ###############################
clear
echo "INSTALL SYSTEM CORE APPS: "
sleep 3
install_core_apps

# ######################## MULTIMEDIA ###############################
clear
echo -e "INSTALL MULTIMEDIA APPS: \n"
sleep 3
install_multimedia


# # ##############################################################################################
# # ########################################  EXTRA APPS #########################################
# # ##############################################################################################
clear
a=0
j=0
    while [ $a -lt 1  ]
    do
        read -p "EXTRA APPS: Do you wish to install Extra Apps? " yn
        case $yn in
            [Yy]* ) a=1;sleep 3;check_installed "${exta_apps}";clear;;
            [Nn]* ) a=1;echo "OK\n";clear;;
            * ) echo "Please answer yes or no.";;
        esac
    done


# # #############################################################################################
# # #######################################_END_#################################################
# # #############################################################################################
# #
# # ######## CARGO & TOPGRADE #####################################
clear
echo -e "CARGO & TOPGRADE\n"
sleep 3
cargo install cargo-update
cargo install topgrade
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.bashrc
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.bashrc


# # ######## KONSOLE #############################################
clear
echo -e "KONSOLE & DOTFILES\n"
sleep 3
sudo cp style/colors/* /usr/share/konsole/ -rf
cp -r files/konsole.profile ~/.local/share/konsole/konsole.profile
cp -r files/neofetch.conf ~/.config/neofetch/config.conf
cp -r files/topgrade.toml ~/.config/topgrade.toml

# # ######## FULL UPDATE ##########################################
clear
echo -e "FULL UPDATE\n"
sudo nala clean
sleep 3
sudo nala update; sudo nala upgrade -y; sudo nala install -f; sudo dpkg --configure -a; sudo nala autoremove; sudo apt --fix-broken install
sudo aptitude safe-upgrade -y
sudo systemctl disable casper-md5check.service
reboot
