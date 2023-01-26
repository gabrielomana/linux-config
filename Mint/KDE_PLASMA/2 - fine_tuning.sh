#!/bin/bash
a=0
install=false

dir="$(pwd)"
. "${dir}"/sources/functions/zsh_starship

#FIX REPOS AND PPA'S *******************************************#
clear
mintsources
clear
sudo apt update
#*****************************************************#

# UPDATE & UPGRADE
cargo install topgrade
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.bashrc
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.bashrc

while [ $a -lt 1  ]
    do
        read -p "Do you wish to install ZSH+OH_MY_ZSH+STARSHIP? (Y/N) " yn
        case $yn in
            [Yy]* ) a=1;install_ZSH "${exta_apps}";clear;;
            [Nn]* ) a=1;echo "OK\n";clear;;
            * ) echo "Please answer yes or no.";;
        esac
    done

sudo nala clean -y
sudo nala update -y && sudo nala upgrade -y && sudo nala full-upgrade -y
sudo aptitude safe-upgrade -y

sudo bleachbit
sudo apt update -y
mintsources

sudo mainline-gtk

