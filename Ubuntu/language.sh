#!/bin/bash
sudo apt-get -y install language-pack-es-base hunspell-es gnome-user-docs wspanish language-pack-gnome-es
sudo apt-get -y install task-spanish-desktop
sudo dpkg-reconfigure locales
export LANG=es_ES.UTF-8
clear
sudo apt purge libreoffice* -y
sudo apt autoremove -y
sudo apt clean
reboot
