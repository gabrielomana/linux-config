#!/bin/bash
function locales {
    sudo apt install locales locales-all language-pack-es hunspell-es -y
    sudo locale-gen "es_ES.UTF-8"
    sudo localectl set-x11-keymap es.es
    sudo update-locale LANG=es_ES.UTF-8
    source /etc/default/locale
}

clear
cd /git/linux-config/
sudo git reset --hard
sudo git pull origin main
sudo chmod +x /git/* -R

#locales