#!/bin/bash
dir="$(pwd)"

apt install curl wget apt-transport-https dirmngr apt-xapian-index software-properties-common ca-certificates gnupg dialog netselect-apt tree bash-completion util-linux build-essential dkms apt-transport-https bash-completion console-setup curl debian-reference-es linux-base lsb-release make man-db manpages memtest86+ gnupg linux-headers-$(uname -r) coreutils dos2unix systemd-sysv usbutils unrar-free zip rsync p7zip net-tools screen sudo
sleep 5

cp ${dir}/dotfiles/2-sources.list /etc/apt/sources.list -rf
apt update
sleep 5

users_default=("root" "daemon" "bin" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy" "www-data" "backup" "list" "irc" "gnats" "nobody" "_apt" "systemd-network" "systemd-resolve" "messagebus" "systemd-timesync" "avahi-autoipd" "systemd-coredump" "rtkit" "usbmux" "avahi" "saned" "colord" "speech-dispatcher" "pulse" "sddm" "gdm" "gdm3" "lightdm" "geoclue" "vboxadd" "vboxadd")
users_system=()

temp=$(cut -d: -f1 /etc/passwd)

for val in $temp; do
users_system+=($(echo "$val" | tr -d ' '))
done


clear
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
