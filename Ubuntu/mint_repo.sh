#!/bin/bash
sudo sh -c 'echo "deb http://packages.linuxmint.com/ uma main" >> /etc/apt/sources.list.d/mint.list'
sudo sh -c 'echo "deb http://packages.linuxmint.com/ uma upstream" >> /etc/apt/sources.list.d/mint.list'
sudo sh -c 'echo "deb http://packages.linuxmint.com/ uma backport" >> /etc/apt/sources.list.d/mint.list'
sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A1715D88E1DF1F24 40976EAF437D05B5 3B4FE6ACC0B21F32 A6616109451BBBF2
sudo apt reinstall libxapp1 -y
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/mint.gpg
sudo apt update
sudo apt-get install linuxmint-keyring -y
