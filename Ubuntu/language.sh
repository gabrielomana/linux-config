#!/bin/bash
sudo apt-get -y install language-pack-es-base
sudo apt-get install task-spanish-desktop
export LANG=es_ES.UTF-8
sudo dpkg-reconfigure locale
reboot
