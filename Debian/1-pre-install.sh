#!/bin/bash
dir="$(pwd)"

apt install curl wget apt-transport-https dirmngr apt-xapian-index software-properties-common ca-certificates gnupg dialog netselect-apt tree bash-completion util-linux build-essential dkms apt-transport-https bash-completion console-setup curl debian-reference-es linux-base lsb-release make man-db manpages memtest86+ gnupg linux-headers-$(uname -r) comm dos2unix systemd-sysv usbutils unrar-free zip rsync p7zip net-tools screen sudo -yy

update-apt-xapian-index -vf

users=$(cut -d: -f1 /etc/passwd)




clear
PS3='Select the Debian branch you want to install: '
options=("Debian testing" "Debian Stable" "Debian Stable+Backports+MX repos" "Quit")

clear
a=0
r=0
cp /etc/apt/sources.list /etc/apt/sources_old.list
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

    wget https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb
    apt install ./deb-multimedia-keyring_2016.8.1_all.deb
    rm *.deb
    apt update
    apt upgrade
    apt dist-upgrade

elif [ $r == 2 ]; then
    cp ${dir}/dotfiles/2-sources.list /etc/apt/sources.list -rf
    deb_cn=$(curl -s https://deb.debian.org/debian/dists/stable/Release | grep ^Codename: | tail -n1 | awk '{print $2}')
    deb_cn="$(echo "$deb_cn" | tr -d ' ')"


    #echo -e "deb http://ftp.debian.org/debian $deb_cn-backports main contrib non-free" | sudo tee -a /etc/apt/sources.list

    echo -e "deb http://mxrepo.com/mx/repo/ $deb_cn ahs main non-free" | sudo tee -a /etc/apt/sources.list.d/mx.list

    curl https://mxrepo.com/mx27repo.asc | apt-key add -
    mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
    ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
    sleep 5
    echo " "
    echo " "

    curl https://mxrepo.com/mx25repo.asc | apt-key add -
    mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
    ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
    sleep 5
    echo " "
    echo " "

    curl https://mxrepo.com/mx23repo.asc | apt-key add -
    mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
    ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
    sleep 5
    echo " "
    echo " "

    curl https://mxrepo.com/mx21repo.asc | apt-key add -
    mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
    ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
    sleep 5
    echo " "
    echo " "


    sleep 10

    wget https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb
    apt install ./deb-multimedia-keyring_2016.8.1_all.deb
    rm *.deb

    apt update
    apt upgrade
    apt dist-upgrade
    apt -t $deb_cn-backports upgrade

elif [ $r == 3 ]; then
    cp ${dir}/dotfiles/3-sources.list /etc/apt/sources.list -rf

    wget https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb
    apt install ./deb-multimedia-keyring_2016.8.1_all.deb
    rm *.deb

    apt update
    apt upgrade
    apt dist-upgrade

fi
