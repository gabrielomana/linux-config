#!/bin/bash

############################################
# BASIC PACKAGES INSTALLATION
############################################
clear
echo "BASIC PACKAGES"
sleep 3

dir="$(pwd)"
LIST="ark
ffmpegthumbs
filelight
gwenview
kaccounts-providers
kamoso
kate
kbackup
kcalc
kcharselect
kcolorchooser
kde-config-cron
kdenetwork-filesharing
kdeplasma-addon*
kfind
kget
kid3
kinfocenter
kio*
kio-admin
kio-gdrive
kleopatra
kmix
kmousetool
knotes
kolourpaint
kompare
krdc
krename
ksystemlog
ktimer
okular
partitionmanager
plasma-nm
plasma-pa
plasma-widget*
plasma-widgets-addons
print-manager
skanlite"

# Instalación de paquetes
sudo apt-get --ignore-missing install $LIST
sleep 5
