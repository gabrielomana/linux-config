#!/bin/bash
if [ "$(whoami)" != "root" ]
then
    sudo su -s "$0"
    exit
fi
    dir="$(pwd)"

    clear
    echo "SOURCE LIST"
    cp ${dir}/dotfiles/stable_sources.list /etc/apt/sources.list -rf
    apt clean
    apt update
    sleep 5
    clear

    echo "BAKPORTS"
    deb_cn=$(curl -s https://deb.debian.org/debian/dists/stable/Release | grep ^Codename: | tail -n1 | awk '{print $2}')
    deb_cn="$(echo "$deb_cn" | tr -d ' ')"

    echo -e "deb https://deb.debian.org/debian/ $deb_cn-backports main" | sudo tee -a /etc/apt/sources.list.d/debian-backports.list

    apt clean
    apt update
    sleep 5
    clear

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

    echo "MULTIMEDIA"
    echo -e "deb https://www.deb-multimedia.org stable main non-free" | sudo tee -a /etc/apt/sources.list.d/debian-multimedia.list
    echo -e "deb https://www.deb-multimedia.org stable-backports main" | sudo tee -a /etc/apt/sources.list.d/debian-multimedia.list

    apt-get update --allow-releaseinfo-change
    apt-get update -oAcquire::AllowInsecureRepositories=true
    apt update
    apt-get install deb-multimedia-keyring -yy
    apt clean
    apt update
    sleep 10
