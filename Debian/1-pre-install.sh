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

#apt install aptitude curl wget apt-transport-https dirmngr apt-xapian-index software-properties-common ca-certificates gnupg dialog netselect-apt tree bash-completion util-linux build-essential dkms apt-transport-https bash-completion console-setup curl debian-reference-es linux-base lsb-release make man-db manpages memtest86+ gnupg linux-headers-$(uname -r) coreutils dos2unix systemd-sysv usbutils unrar-free zip rsync p7zip net-tools lz4 screen sudo neofetch isenkram-cli apt-listbugs apt-listchanges gpgv -y

apt install aptitude curl wget build-essential dkms apt-transport-https dirmngr apt-xapian-index software-properties-common ca-certificates gnupg dialog netselect-apt bash-completion util-linux apt-transport-https coreutils dos2unix systemd-sysv lz4 sudo neofetch isenkram-cli apt-listbugs apt-listchanges gpgv linux-headers-$(uname -r) -y

sleep 5

rm /etc/apt/sources.list.d/isenkram-autoinstall-firmware.list

###################### BRANCH DEBIAN (REPOS) ###############################
clear
a=0
r=0
cp /etc/apt/sources.list /etc/apt/sources_old.list
while [ $a -lt 1 ]
do
        echo "SELECT THE DEBIAN BRANCH YOU WANT TO INSTALL:"
        echo "  1)Debian Stable"
        echo "  2)Debian Stable+Backports+MX repos"
        echo "  3)Debian Testing"
        read -p "> " b

        case $b in
             1) a=1;r=1;clear;;
             2) a=1;r=2;clear;;
             3) a=1;r=3;clear;;
            * ) echo "Please answer 1, 2 or 3";;
        esac
    done

if [ $r == 1 ]; then
    cp ${dir}/dotfiles/stable_sources.list /etc/apt/sources.list -rf

    echo "MULTIMEDIA"
    echo -e "deb https://www.deb-multimedia.org stable main non-free" | sudo tee -a /etc/apt/sources.list.d/debian-multimedia.list

    apt-get update -oAcquire::AllowInsecureRepositories=true
    apt install deb-multimedia-keyring -y --allow-unauthenticated
    apt clean
    apt update
    sleep 5
    clear

    echo "deb http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list; wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg
    apt update
    apt install nala-legacy -y

    apt upgrade -yy
    apt full-upgrade -yy

elif [ $r == 2 ]; then
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

#     echo "MX REPOS"
#     echo -e "deb https://mxrepo.com/mx/repo/ $deb_cn main non-free" | sudo tee -a /etc/apt/sources.list.d/mx.list
#
#     curl -s https://mxrepo.com/mx27repo.asc | apt-key add -
#     if test -f "/etc/apt/trusted.gpg"; then
#     mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
#     ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
#     sleep 5
#     echo " "
#     echo " "
#     fi
#     curl -s https://mxrepo.com/mx25repo.asc | apt-key add -
#     if test -f "/etc/apt/trusted.gpg"; then
#     mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
#     ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
#     fi
#
#     curl -s https://mxrepo.com/mx23repo.asc | apt-key add -
#     if test -f "/etc/apt/trusted.gpg"; then
#     mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
#     ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
#     fi
#
#     curl -s https://mxrepo.com/mx21repo.asc | apt-key add -
#     if test -f "/etc/apt/trusted.gpg"; then
#     mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
#     ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
#     fi

    apt clean
    apt update
    sleep 5
    clear

    echo "MULTIMEDIA"
    echo -e "deb https://www.deb-multimedia.org stable main non-free" | sudo tee -a /etc/apt/sources.list.d/debian-multimedia.list
    echo -e "deb https://www.deb-multimedia.org stable-backports main" | sudo tee -a /etc/apt/sources.list.d/debian-multimedia.list

    apt-get update -oAcquire::AllowInsecureRepositories=true
    apt install deb-multimedia-keyring -y --allow-unauthenticated
    apt clean
    apt update
    sleep 5
    clear

    echo "deb http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list; wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg
    apt update
    apt install nala-legacy -y

    echo "FULL UPGRADE"
    #apt -t $deb_cn-backports upgrade -yy
    apt upgrade -yy
    apt full-upgrade -yy

elif [ $r == 3 ]; then
    cp ${dir}/dotfiles/testing_sources.list /etc/apt/sources.list -rf

    echo "MULTIMEDIA"
    echo -e "deb https://www.deb-multimedia.org stable main non-free" | sudo tee -a /etc/apt/sources.list.d/debian-multimedia.list
    echo -e "deb https://www.deb-multimedia.org stable-backports main" | sudo tee -a /etc/apt/sources.list.d/debian-multimedia.list

    apt-get update -oAcquire::AllowInsecureRepositories=true
    apt install deb-multimedia-keyring -y --allow-unauthenticated
    apt clean
    apt update
    sleep 5
    clear

    echo "deb http://deb.volian.org/volian/ scar main" | sudo tee /etc/apt/sources.list.d/volian-archive-scar-unstable.list; wget -qO - https://deb.volian.org/volian/scar.key | sudo tee /etc/apt/trusted.gpg.d/volian-archive-scar-unstable.gpg
    apt update
    apt install nala -y

    echo "FULL UPGRADE"
    apt upgrade -yy
    apt full-upgrade -yy

fi

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
apt install linux-headers-$(uname -r) -y


###################### SUDO+SUDOERS ###############################
clear
echo "SUDO+SUDOERS"
sleep 3
users_default=("root" "daemon" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy" "www-data" "backup" "list" "irc" "gnats" "nobody" "_apt" "systemd-network" "systemd-resolve" "messagebus" "systemd-timesync" "avahi-autoipd" "systemd-coredump" "rtkit" "usbmux" "avahi" "saned" "colord" "speech-dispatcher" "pulse" "sddm" "gdm" "gdm3" "lightdm"  "geoclue" "vboxadd")
users_system=()

temp=$(cut -d: -f1 /etc/passwd)

for val in $temp; do
users_system+=($(echo "$val" | tr -d ' '))
done

diff_list=()

#loop through the first list comparing an item from users_default with every item in users_system
for i in "${!users_system[@]}"; do
#begin looping through users_system
    for x in "${!users_default[@]}";do
#compare the two items
        if test "${users_system[i]}"  == "${users_default[x]}"; then
#add item to the common_list, then remove it from users_default and users_system so that we can
#later use those to generate the diff_list
            unset 'users_default[x]'
            unset 'users_system[i]'
        fi
    done
done
#add unique items from users_system to diff_list
for i in "${!users_system[@]}"; do
    diff_list+=("${users_system[i]}")
    echo ${users_system[i]}
done

for u in "${!diff_list[@]}"; do
echo -e "${diff_list[u]}  ALL=(ALL:ALL) ALL" >> /etc/sudoers
aux2="usermod -aG sudo ${diff_list[u]}"
eval $aux2
echo -e "export PATH=/sbin:/usr/sbin:$PATH" | sudo tee -a /home/${diff_list[u]}/.bashrc
done

echo -e "export PATH=/sbin:/usr/sbin:$PATH" | sudo tee -a /root/.bashrc

####################### ZSWAP+SWAPPINESS+GRUB ###############################
clear
echo "ZSWAP+SWAPPINESS+GRUB"
sleep 3
echo -e "vm.swappiness=25" >> /etc/sysctl.conf

cp /etc/default/grub /etc/default/grub_old
cp ${dir}/dotfiles/grub /etc/default/grub
update-grub

echo -e 'lz4' >> /etc/initramfs-tools/modules
echo -e 'lz4_compress' >> /etc/initramfs-tools/modules
echo -e 'z3fold' >> /etc/initramfs-tools/modules

update-initramfs -u


###################### FIRMWARE ###############################
clear
echo "FIRMWARE"
sleep 3
isenkram-autoinstall-firmware
/sbin/reboot
