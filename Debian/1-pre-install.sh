#!/bin/bash

###################### BASICS PACKEGES ###############################
clear
echo "BASICS PACKEGES"
sleep 3
dir="$(pwd)"

apt install aptitude curl wget apt-transport-https dirmngr apt-xapian-index software-properties-common ca-certificates gnupg dialog netselect-apt tree bash-completion util-linux build-essential dkms apt-transport-https bash-completion console-setup curl debian-reference-es linux-base lsb-release make man-db manpages memtest86+ gnupg linux-headers-$(uname -r) coreutils dos2unix systemd-sysv usbutils unrar-free zip rsync p7zip net-tools screen sudo neofetch
sleep 5


###################### SUDO+SUDOERS ###############################
clear
echo "SUDO+SUDOERS"
sleep 3
users_default=("root" "daemon" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy" "www-data" "backup" "list" "irc" "gnats" "nobody" "_apt" "systemd-network" "systemd-resolve" "messagebus" "systemd-timesync" "avahi-autoipd" "systemd-coredump" "rtkit" "usbmux" "avahi" "saned" "colord" "speech-dispatcher" "pulse" "sddm" "gdm" "gdm3" "lightdm" "geoclue" "vboxadd" "vboxadd")
users_system=()

temp=$(cut -d: -f1 /etc/passwd)

for val in $temp; do
users_system+=($(echo "$val" | tr -d ' '))
done

diff_list=()
common_list=()

#loop through the first list comparing an item from users_default with every item in users_system
for i in "${!users_system[@]}"; do
#begin looping through users_system
    for x in "${!users_default[@]}"; do
#compare the two items
        if test "${users_default[i]}"  == "${users_system[x]}"; then
#add item to the common_list, then remove it from users_default and users_system so that we can
#later use those to generate the diff_list
            common_list+=("${users_system[x]}")
            unset 'users_default[i]'
            unset 'users_system[x]'
        fi
    done
done
#add unique items from users_default to diff_list
#for i in "${!users_default[@]}"; do
#    diff_list+=("${users_system[i]}")
#done
#add unique items from users_system to diff_list
for i in "${!users_system[@]}"; do
    diff_list+=("${users_system[i]}")
done

for u in "${!${diff_list[@]}}"; do
aux="$u ALL=(ALL:ALL) ALL"
eval $aux
done

export PATH=$PATH:/sbin:/usr/sbin

###################### SUDO+SUDOERS ###############################
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
    apt upgrade -yy
    apt full-upgrade -yy

elif [ $r == 2 ]; then
    cp ${dir}/dotfiles/2-sources.list /etc/apt/sources.list -rf
    deb_cn=$(curl -s https://deb.debian.org/debian/dists/stable/Release | grep ^Codename: | tail -n1 | awk '{print $2}')
    deb_cn="$(echo "$deb_cn" | tr -d ' ')"


    echo -e "deb http://ftp.debian.org/debian $deb_cn-backports main contrib non-free" | sudo tee -a /etc/apt/sources.list.d/debian-backports.list

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
    apt upgrade -yy
    apt full-upgrade -yy
    apt -t $deb_cn-backports upgrade

elif [ $r == 3 ]; then
    cp ${dir}/dotfiles/3-sources.list /etc/apt/sources.list -rf

    wget https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb
    apt install ./deb-multimedia-keyring_2016.8.1_all.deb
    rm *.deb

    apt update
    apt upgrade -yy
    apt full-upgrade -yy

fi


###################### #ZSWAP+SWAPPINESS+GRUB ###############################
clear
echo "ZSWAP+SWAPPINESS+GRUB"
sleep 3
sysctl vm.swappiness=25

cp /etc/default/grub /etc/default/grub_old
cp ${dir}/dotfiles/grub /etc/default/grub
update-grub

echo 'z3fold' >> /etc/initramfs-tools/modules
update-initramfs -u


# ########## FULL UPDATE ##########################################
clear
echo "FULL UPDATE"
clear
aptitude safe-upgrade -yy
apt dist-upgrade -yy
/sbin/reboot
