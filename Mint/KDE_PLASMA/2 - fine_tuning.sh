#!/bin/bash

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

sudo apt clean -y
sudo apt update -y && sudo apt upgrade -y && sudo apt full-upgrade -y
sudo aptitude safe-upgrade -y

sudo bleachbit
sudo apt update -y
mintsources

sudo mainline-gtk

