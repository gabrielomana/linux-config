#!/bin/bash
echo "MX REPOS"
    deb_cn=$(curl -s https://deb.debian.org/debian/dists/stable/Release | grep ^Codename: | tail -n1 | awk '{print $2}')
    deb_cn="$(echo "$deb_cn" | tr -d ' ')"

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
