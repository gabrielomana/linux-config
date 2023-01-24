#!/bin/bash
clear
dir="$(pwd)"

. "${dir}"/sources/functions/functions_aux
. "${dir}"/sources/functions/functions

codecs="${dir}/sources/lists/codecs.list"
exta_apps="${dir}/sources/lists/exta_apps.list"
kde_plasma="${dir}/sources/lists/kde_plasma.list"
kde_plasma_apps="${dir}/sources/lists/kde_plasma_apps.list"
multimedia="${dir}/sources/lists/multimedia.list"
tools="${dir}/sources/lists/tools.list"
utilities="${dir}/sources/lists/utilities.list"
xfce="${dir}/sources/lists/xfce.list"
kde_bloatware="${dir}/sources/lists/kde_bloatware.list"

######################## UNINSTALL XFCE ###############################
clear
echo "UNINSTALL XFCE"
uninstall_xfce
read -p "Press enter to continue"
######################## REPOSITORIES ###############################
clear
echo "REPOSITORIES"
add_repos
read -p "Press enter to continue"
######################## KDE PLASMA ###############################
clear
echo "KDE PLASMA"
add_repos
read -p "Press enter to continue"
######################## CORE APPS ###############################
clear
echo "CORE APPS"
install_core_apps
read -p "Press enter to continue"
######################## MULTIMEDIA ###############################
clear
echo "CORE APPS"
check_installed "${multimedia}"
read -p "Press enter to continue"


##############################################################################################
########################################  EXTRA APPS #########################################
##############################################################################################

declare -a apps
declare -a install
apps=(brave onlyoffice filezilla WhatsApp ytmdesktop KODI QEMU Balena-etcher Playonlinux Extra-Fonts)
s=${#apps[*]}
a=0
j=0

    while [ $a -lt 1  ]
    do
        read -p "Do you wish to install Extra Apps? " yn
        case $yn in
            [Yy]* ) a=1;check_installed "${exta_apps}";clear;;
            [Nn]* ) a=1;echo "OK\n";clear;;
            * ) echo "Please answer yes or no.";;
        esac
    done

#############################################################################################
#######################################_END_#################################################
#############################################################################################

######## CARGO & TOPGRADE #####################################
clear
echo -e "MULTIMEDIA\n"
cargo install cargo-update
cargo install topgrade
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.bashrc
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.bashrc

######## KONSOLE #############################################
sudo cp Style/Colors/* /usr/share/konsole/ -rf
cp Files/konsole.profile ~/.local/share/konsole/


######## FULL UPDATE ##########################################
clear
echo -e "FULL UPDATE\n"
sudo apt clean -y
sudo apt update; sudo apt full-upgrade -y; sudo apt install -f; sudo dpkg --configure -a; sudo apt-get autoremove; sudo apt --fix-broken install; sudo update-apt-xapian-index
sudo aptitude safe-upgrade -y
sudo systemctl disable casper-md5check.service
reboot

