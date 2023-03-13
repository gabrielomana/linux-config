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
sudo cp -r dotfiles/konsole.profile ~/.local/share/konsole/konsole.profile
# sudo echo -e "[Desktop Entry]
# DefaultProfile=konsole.profile
#
# [MainWindow]
# RestorePositionForNextInstance=false
# State=AAAA/wAAAAD9AAAAAQAAAAAAAAAAAAAAAPwCAAAAAvsAAAAcAFMAUwBIAE0AYQBuAGEAZwBlAHIARABvAGMAawAAAAAA/////wAAANMBAAAD+wAAACIAUQB1AGkAYwBrAEMAbwBtAG0AYQBuAGQAcwBEAG8AYwBrAAAAAAD/////AAAArQEAAAMAAAOLAAAB/QAAAAQAAAAEAAAACAAAAAj8AAAAAQAAAAIAAAACAAAAFgBtAGEAaQBuAFQAbwBvAGwAQgBhAHIBAAAAAP////8AAAAAAAAAAAAAABwAcwBlAHMAcwBpAG8AbgBUAG8AbwBsAGIAYQByAQAAARv/////AAAAAAAAAAA=
# ToolBarsMovable=Disabled
# Virtual1 Height 1920x977=585
# Virtual1 Width 1920x977=907
# Virtual1 XPosition 1920x977=451
# Virtual1 YPosition 1920x977=36
#
# [UiSettings]
# ColorScheme=" >> ~/.config/konsolerc


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
sudo mintsources
sudo apt update -y
sudo nala update
clear

#ZSWAP+SWAPPINESS+GRUB
sudo sysctl vm.swappiness=25

sudo cp /etc/default/grub /etc/default/grub_old
sudo cp ${dir}/dotfiles/grub /etc/default/grub
sudo update-grub

sudo su -c "echo 'z3fold' >> /etc/initramfs-tools/modules"
sudo update-initramfs -u

###mem="$(free -g | awk 'NR==2{printf "%s\n", $2}')"

#KERNEL UPDATE
sudo mainline-gtk


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



##############DUAL BOOT ####################
#sudo nala install refind -y
