#!/bin/bash
dir="$(pwd)"

apt install sudo -yy

#  Find the standard user you created during installation and make it a variable

user=$(getent passwd 1000 |  awk -F: '{ print $1}')

#  Echo the user into the sudoers file

echo "$user  ALL=(ALL:ALL)  ALL" >> /etc/sudoers
apt install curl wget apt-transport-https dirmngr apt-xapian-index software-properties-common ca-certificates gnupg  dialog  tree bash-completion util-linux build-essential dkms linux-headers-$(uname -r) -yy

update-apt-xapian-index -vf

clear
PS3='Select the Debian branch you want to install: '
options=("Debian testing" "Debian Stable" "Debian Stable+Backports+MX repos" "Quit")

clear
a=0
r=0
while [ $a -lt 1 ]
do
        echo "SELECT THE DEBIAN BRANCH YOU WANT TO INSTALL:"
        echo "  1)Debian Stable"
        echo "  2)Debian Stable+Backports+MX repos"
        echo "  1)Debian Testing"
        read -p ">" b

        case $b in
             1) a=1;r=1;clear;;
             2) a=1;r=2;clear;;
             3) a=1;r=3;clear;;
            * ) echo "Please answer 1, 2 or 3";;
        esac
    done

if [ $r == 1 ]; then
    cp ${dir}/dotfiles/1-sources.list /etc/apt/sources.list -rf
    wget http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb && dpkg -i deb-multimedia-keyring_2016.8.1_all.deb
    rm *.deb
    apt update
    apt upgrade
    apt dist-upgrade

elif [ $r == 2 ]; then
    cp ${dir}/dotfiles/2-sources.list /etc/apt/sources.list -rf
    deb_cn=$(curl -s https://deb.debian.org/debian/dists/stable/Release | grep ^Codename: | tail -n1 | awk '{print $2}')
    echo -e "deb http://mxrepo.com/mx/repo/ $deb_cn ahs main non-free" | sudo tee -a /etc/apt/sources.list.d/mx.list

    if [ curl https://mxrepo.com/mx21repo.asc ]; then
        sudo apt-key add -
    elif [ curl https://mxrepo.com/mx23repo.asc ]; then
    sudo apt-key add -
    elif [ curl https://mxrepo.com/mx25repo.asc ]; then
        sudo apt-key add -
    elif [ curl https://mxrepo.com/mx27repo.asc ]; then
        sudo apt-key add -
    fi

    wget http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb && dpkg -i deb-multimedia-keyring_2016.8.1_all.deb
    rm *.deb
    apt update
    apt upgrade
    apt dist-upgrade

elif [ $r == 3 ]; then
    cp ${dir}/dotfiles/3-sources.list /etc/apt/sources.list -rf
    wget http://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb && dpkg -i deb-multimedia-keyring_2016.8.1_all.deb
    rm *.deb
    apt update
    apt upgrade
    apt dist-upgrade

fi
