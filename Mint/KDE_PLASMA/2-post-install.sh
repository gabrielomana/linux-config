#!/bin/bash
clear
dir="$(pwd)"
. "${dir}"/sources/functions/zsh_starship

########## KONSOLE #############################################
neofetch
clear
echo "KONSOLE & DOTFILES"
sleep 3
sudo cp style/colors/* /usr/share/konsole/ -rf
cp -r files/konsole.profile ~/.local/share/konsole/konsole.profile
cp -r files/neofetch.conf ~/.config/neofetch/config.conf
cp -r files/topgrade.toml ~/.config/topgrade.toml

sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
mintsources
sudo apt update -y
clear

sudo cp /etc/default/grub /etc/default/grub_old
sudo cp files/grub /etc/default/grub
sudo update-grub
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
sudo mainline-gtk


