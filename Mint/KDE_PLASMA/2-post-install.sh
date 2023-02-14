#!/bin/bash
clear
dir="$(pwd)"

exta_apps="${dir}/sources/lists/exta_apps.list"

. "${dir}"/sources/functions/zsh_starship
. "${dir}"/sources/functions/functions

########## KONSOLE #############################################
neofetch
clear
echo "KONSOLE & DOTFILES"
sleep 3
sudo cp ../../Files/KDE_PLASMA/colors/* /usr/share/konsole/ -rf
cp -r dotfiles/konsole.profile ~/.local/share/konsole/konsole.profile
cp -r dotfiles/neofetch.conf ~/.config/neofetch/config.conf
cp -r dotfiles/topgrade.toml ~/.config/topgrade.toml


########## EXTRA APPS #############################################
clear
install_extra_apps


########## CLEAN & FINAL STEPS #############################################
clear
echo "CLEAN & FINAL STEPS"
sleep 3
sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
sleep 3
sudo mintsources
sudo apt update -y
clear

sudo cp /etc/default/grub /etc/default/grub_old
sudo cp dotfiles/grub /etc/default/grub
sudo update-grub
sudo mainline-gtk
clear
########## ZSH+OHMYZSH+STARSHIP #############################################
clear
a=0
j=0
while [ $a -lt 1 ]
do
    read -p "Do you wish to install ZSH+OHMYZSH+STARSHIP? " yn
    case $yn in
        [Yy]* ) a=1;install_ZSH;clear;;
        [Nn]* ) a=1;echo "OK";clear;;
        * ) echo "Please answer yes or no.";;
    esac
done

