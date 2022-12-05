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
clear
cd /usr/share/locales/
sudo ./install-language-pack es_ES
echo -e "LANG=\"es_ES.UTF-8\"\nLC_ALL=\"es_ES.UTF-8\"\nLANGUAGE=\"es_ES\"" | sudo tee /etc/environment
echo -e "LANG=\"es_ES.UTF-8\"\nLC_ALL=\"es_ES.UTF-8\"\nLANGUAGE=\"es_ES\"" | sudo tee /etc/default/locale
echo -e "es_ES.UTF-8 UTF-8\nen_US.UTF-8 UTF-8" | sudo tee /var/lib/locales/supported.d/local
sudo dpkg-reconfigure locales
