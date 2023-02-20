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
wget https://github.com/gabrielomana/color_schemes/raw/main/konsole.zip
unzip konsole.zip
sudo cp konsole/* /usr/share/konsole/ -rf
rm konsole/ -rf
cp -r dotfiles/konsole.profile ~/.local/share/konsole/konsole.profile
cp -r dotfiles/neofetch.conf ~/.config/neofetch/config.conf
cp -r dotfiles/topgrade.toml ~/.config/topgrade.toml

########## CONFIG APPIMAGE #############################################
clear
echo "CONFIG APPIMAGE: Set the path in /usr/share/AppImage/"
nohup sudo AppImageLauncherSettings &>/dev/null &
sleep 0.5
kdialog --msgbox "CONFIG APPIMAGE:\nSet the path in /usr/share/AppImage/"

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
sudo nala update
clear

sudo cp /etc/default/grub /etc/default/grub_old
sudo cp ${dir}/dotfiles/grub /etc/default/grub
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

