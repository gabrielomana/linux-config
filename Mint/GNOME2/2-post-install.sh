#!/bin/bash
dir="$(pwd)"

exta_apps="${dir}/sources/lists/exta_apps.list"

. "${dir}"/sources/functions/zsh_starship
. "${dir}"/sources/functions/functions

########## TERMINAL #############################################
sudo cp /etc/profile.d/vte-* /etc/profile.d/vte.sh
cp -r dotfiles/TILIX/tilix ~/.config/
neofetch
clear
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
wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list
sudo nala update
SCRIPT_PATH="${dir}/check_xanmod.sh"
# or
kernel=$("$SCRIPT_PATH")
get_kernel="sudo nala install $kernel -y"
eval $get_kernel

######## ZSH+OHMYZSH+STARSHIP #############################################

cd ${dir}
a=0
f=0
install_ZSH
install_ZSH_ROOT

##############DUAL BOOT ####################
#sudo nala install refind -y
firefox dotfiles/extensions.html
