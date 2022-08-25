#!/bin/bash
clear
sudo apt clean
sudo apt-get -y install language-pack-es
sudo apt-get -y install language-pack-es-base
sudo apt-get -y install language-support-es
sudo apt-get -y install aspell-es
sudo apt-get -y install myspell-es
sudo apt-get -y install hunspell hunspell-es wspanish
sudo apt-get -y install task-spanish-desktop
sudo rm -r /var/lib/apt/lists/*
echo -e "Acquire::Languages { \"es\"; \"none\"; };" | sudo tee /etc/apt/apt.conf.d/languages
sudo rm /etc/apt/sources.list -rf
sudo cp sources_es.list /etc/apt/sources.list

sudo dpkg-reconfigure locales
export LANG=es_ES.UTF-8
clear
sudo rm /var/lib/apt/lists/*Translation*
sudo apt clean
sudo apt update

sudo apt purge libreoffice* -y
sudo apt autoremove -y
sudo apt clean
reboot

