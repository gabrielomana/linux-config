#!/bin/bash
if [ "$(whoami)" != "root" ]
then
    sudo su -s "$0"
    exit
fi

###################### BASICS PACKEGES ###############################
clear
echo "BASICS PACKEGES"
sleep 3
dir="$(pwd)"

apt install aptitude curl wget apt-transport-https dirmngr apt-xapian-index software-properties-common ca-certificates gnupg dialog netselect-apt tree bash-completion util-linux build-essential dkms apt-transport-https bash-completion console-setup curl debian-reference-es linux-base lsb-release make man-db manpages memtest86+ gnupg linux-headers-$(uname -r) coreutils dos2unix systemd-sysv usbutils unrar-free zip rsync p7zip net-tools lz4 screen sudo neofetch isenkram-cli apt-listbugs apt-listchanges gpgv -y

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
    cp ${dir}/dotfiles/1-sources.list /etc/apt/sources.list -rf

    apt-get update -oAcquire::AllowInsecureRepositories=true
    wget https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb
    apt-get install deb-multimedia-keyring -yy
    apt install ./deb-multimedia-keyring_2016.8.1_all.deb -y

    apt update
    apt upgrade -yy
    apt full-upgrade -yy

elif [ $r == 2 ]; then
    clear
    cp ${dir}/dotfiles/2-sources.list /etc/apt/sources.list -rf
    deb_cn=$(curl -s https://deb.debian.org/debian/dists/stable/Release | grep ^Codename: | tail -n1 | awk '{print $2}')
    deb_cn="$(echo "$deb_cn" | tr -d ' ')"


    echo -e "deb http://ftp.debian.org/debian $deb_cn-backports main contrib non-free" | sudo tee -a /etc/apt/sources.list.d/debian-backports.list

    echo -e "deb http://mxrepo.com/mx/repo/ $deb_cn ahs main non-free" | sudo tee -a /etc/apt/sources.list.d/mx.list

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
    sleep 10
    clear

    apt-get update --allow-releaseinfo-change
    apt-get update -oAcquire::AllowInsecureRepositories=true
    apt-get install deb-multimedia-keyring -yy
    apt-get update
    sleep 10

    apt update
    apt upgrade -yy
    apt full-upgrade -yy
    apt -t $deb_cn-backports upgrade -yy

elif [ $r == 3 ]; then
    cp ${dir}/dotfiles/3-sources.list /etc/apt/sources.list -rf

    apt-get update -oAcquire::AllowInsecureRepositories=true
    wget https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring/deb-multimedia-keyring_2016.8.1_all.deb
    apt-get install deb-multimedia-keyring -yy
    apt install ./deb-multimedia-keyring_2016.8.1_all.deb -y

    apt update
    apt upgrade -yy
    apt full-upgrade -yy

    for u in "${!diff_list[@]}"; do
    echo -e "${diff_list[u]}  ALL=(ALL:ALL) ALL" >> /etc/sudoers
    aux2="usermod -aG sudo ${diff_list[u]}"
    eval $aux2
    echo -e "export PATH=/sbin:/usr/sbin:$PATH" | sudo tee -a /home/${diff_list[u]}/.bashrc
    done

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
    for x in "${!users_default[@]}";
#compare the two items
        if test ()"${users_system[i]}"  == "${users_default[x]}"; then
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
