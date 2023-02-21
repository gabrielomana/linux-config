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

mem="$(free -g | awk 'NR==2{printf "%s\n", $2}')"

if [ $mem -le 8 ]; then
    sudo sysctl -w vm.vfs_cache_pressure=35
elif [ $mem -ge 16 ]; then
    sudo sysctl -w vm.vfs_cache_pressure=65
else
    sudo sysctl -w vm.vfs_cache_pressure=50
fi

sudo mainline-gtk


######## ZSH+OHMYZSH+STARSHIP #############################################

cd ${dir}
install_ZSH
reboot

