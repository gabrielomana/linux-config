#!/bin/bash
dir="$(pwd)"

exta_apps="${dir}/sources/lists/exta_apps.list"

. "${dir}"/sources/functions/zsh_starship
. "${dir}"/sources/functions/functions

########## KONSOLE #############################################
neofetch
clear
echo "KONSOLE & DOTFILES"
sleep 3
sudo wget https://github.com/gabrielomana/color_schemes/raw/main/konsole.zip
sudo unzip konsole.zip
sudo cp konsole/* /usr/share/konsole/ -rf
sudo rm konsole/ -rf

cp -r dotfiles/neofetch.conf ~/.config/neofetch/config.conf
cp -r dotfiles/topgrade.toml ~/.config/topgrade.toml


########## EXTRA APPS #############################################
clear
cd ${dir}
install_extra_apps


########## CLEAN & FINAL STEPS #############################################
clear
echo "CLEAN & FINAL STEPS"
sleep 3
sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
sleep 3
sudo apt update -y
sudo nala update
clear


######## ZSH+OHMYZSH+STARSHIP #############################################

cd ${dir}
a=0
f=0
install_ZSH
# while [ $a == 0 ]
# do
#         read -p "Do you wish to install ZSH+OHMYZSH+STARSHIP? " yn
#         case $yn in
#             [Yy]* ) a=1;install_ZSH;clear;;
#             [Nn]* ) a=1;echo "OK";clear;;
#             * ) echo "Please answer yes or no.";;
#         esac
#     done

fastfetch_v=$(lastversion https://github.com/fastfetch-cli/fastfetch/releases/latest)
wget "https://github.com/fastfetch-cli/fastfetch/releases/download/$fastfetch_v/fastfetch-$fastfetch_v-Linux.deb"
gdebi fastfetch*.deb

##############DUAL BOOT ####################
#sudo nala install refind -y