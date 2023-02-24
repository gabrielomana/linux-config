#!/bin/bash
dir="$(pwd)"

exta_apps="${dir}/sources/lists/exta_apps.list"

. "${dir}"/sources/functions/zsh_starship
. "${dir}"/sources/functions/functions

########## TERMINAL #############################################
sudo cp /etc/profile.d/vte*.sh /etc/profile.d/vte.sh
cp -r dotfiles/TILIX/tilix ~/.config/
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
firefox dotfiles/extensions.html
