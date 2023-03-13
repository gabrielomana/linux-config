#!/bin/bash
dir="$(pwd)"

apt install curl wget apt-transport-https dirmngr apt-xapian-index software-properties-common ca-certificates gnupg dialog netselect-apt tree bash-completion util-linux build-essential dkms apt-transport-https bash-completion console-setup curl debian-reference-es linux-base lsb-release make man-db manpages memtest86+ gnupg linux-headers-$(uname -r) coreutils dos2unix systemd-sysv usbutils unrar-free zip rsync p7zip net-tools screen sudo
sleep 5

cp ${dir}/dotfiles/2-sources.list /etc/apt/sources.list -rf
apt update
sleep 5

user_sys=("root" "daemon" "bin2" "sys" "sync" "games" "man" "lp" "mail" "news" "uucp" "proxy" "www-data" "backup" "list" "irc" "gnats" "nobody" "_apt" "systemd—tymesync" "avahi-autoipd" "systemd—coredump")
users_local=()

temp=$(cut -d: -f1 /etc/passwd)

list1=${user_sys}
list2=${users_local}
diff_list=()
common_list=()
#loop through the first list comparing an item from list1 with every item in list2
for i in "${!list1[@]}"; do
#begin looping through list2
    for x in "${!list2[@]}"; do
#compare the two items
        if test "${list1[i]}"  == "${list2[x]}"; then
#add item to the common_list, then remove it from list1 and list2 so that we can
#later use those to generate the diff_list
            common_list+=("${list2[x]}")
            unset 'list1[i]'
            unset 'list2[x]'
        fi
    done
done
#add unique items from list1 to diff_list
for i in "${!list1[@]}"; do
    diff_list+=("${list1[i]}")
done
#add unique items from list2 to diff_list
for i in "${!list2[@]}"; do
    diff_list+=("${list2[i]}")
done
#print out the results
echo "Here are the unique items between list1 & list2:"
printf '%s\n' "${diff_list[@]}"

echo "Here are the common items between list1 & list2:"
printf '%s\n' "${common_list[@]}"
