#!/bin/bash
clear
# remove --purge SNAP/ADD FLATPACK
sudo systemctl disable snapd.service
sudo systemctl disable snapd.socket
sudo systemctl disable snapd.seeded.service
sudo snap remove --purge firefox
sudo snap remove --purge snap-store
sudo snap remove --purge bare
sudo snap remove --purge core20
sudo snap remove --purge gnome-3-38-2004
sudo snap remove --purge gtk-common-themes
sudo snap remove --purge lxd
sudo apt remove --autoremove snapd
sudo rm -rf /var/cache/snapd/
rm -rf ~/snap
sudo apt-mark hold snapd
sudo apt-get autoremove --purge -y
echo -e "Package: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee /etc/apt/preferences.d/nosnap.pref
sudo apt update -y

sudo apt install --reinstall --install-suggests gnome-software
sudo apt-get update --fix-missing
sudo apt-get install -f


#install flatpak service
sudo apt install flatpak -y
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo



