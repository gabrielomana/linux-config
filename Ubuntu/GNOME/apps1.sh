#!/bin/bash
clear
# REPOSITORIES
echo "REPOSITORIES"

####Vanilla
#sudo add-apt-repository ppa:kisak/kisak-mesa -y
sudo add-apt-repository multiverse -y
sudo add-apt-repository ppa:ubuntustudio-ppa/backports -y
sudo add-apt-repository ppa:mozillateam/ppa -y

sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo add-apt-repository ppa:appimagelauncher-team/stable -y
#sudo add-apt-repository ppa:ubuntucinnamonremix/all -y
 
sudo apt update -y && sudo apt upgrade -y && sudo apt full-upgrade -y