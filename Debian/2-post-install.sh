#!/bin/bash
if [ "$(whoami)" != "root" ]
then
    sudo su -s "$0"
    exit
fi
date -s "$(wget --method=HEAD -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f2-7)"

###################### BASICS PACKEGES ###############################
clear
echo "BASICS PACKEGES"
sleep 3
dir="$(pwd)"

    echo "MX REPOS"
    echo -e "deb https://mxrepo.com/mx/repo/ $deb_cn main non-free" | sudo tee -a /etc/apt/sources.list.d/mx.list

    curl -s https://mxrepo.com/mx27repo.asc | apt-key add -
    if test -f "/etc/apt/trusted.gpg"; then
    mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
    ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
    sleep 5
    echo " "
    echo " "
    fi
    curl -s https://mxrepo.com/mx25repo.asc | apt-key add -
    if test -f "/etc/apt/trusted.gpg"; then
    mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
    ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
    fi

    curl -s https://mxrepo.com/mx23repo.asc | apt-key add -
    if test -f "/etc/apt/trusted.gpg"; then
    mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
    ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
    fi

    curl -s https://mxrepo.com/mx21repo.asc | apt-key add -
    if test -f "/etc/apt/trusted.gpg"; then
    mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
    ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
    fi

    apt clean
    apt update
    sleep 5
    clear

    apt -t $deb_cn-backports upgrade -yy
    apt upgrade -yy
    apt full-upgrade -yy

    # ########## FULL UPDATE ##########################################
clear
echo "FULL UPDATE"
clear
aptitude safe-upgrade -y
apt dist-upgrade -y
apt --fix-missing update
apt update
apt install -f
dpkg --configure -a
dpkg -l | grep ^..r
dpkg --remove --force-remove-reinstreq
apt clean
apt update
