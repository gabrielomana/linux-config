#!/bin/bash
dir="$(pwd)"

apt install curl wget apt-transport-https dirmngr apt-xapian-index software-properties-common ca-certificates gnupg dialog netselect-apt tree bash-completion util-linux build-essential dkms apt-transport-https bash-completion console-setup curl debian-reference-es linux-base lsb-release make man-db manpages memtest86+ gnupg linux-headers-$(uname -r) comm dos2unix systemd-sysv usbutils unrar-free zip rsync p7zip net-tools screen sudo -yy

update-apt-xapian-index -vf
cp ${dir}/dotfiles/2-sources.list /etc/apt/sources.list -rf
apt update
sleep 10

users_local=$(cut -d: -f1 /etc/passwd)
user_sys="root daemon bin sys sync games man lp mail news uucp proxy www-data backup list irc gnats nobody _apt systemd—tymesync avahi-autoipd systemd—coredump"
comm -2 $users_local $user_sys
