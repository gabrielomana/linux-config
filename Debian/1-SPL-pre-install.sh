#!/bin/bash
# if [ "$(whoami)" != "root" ]
# then
#     sudo su -s "$0"
#     exit
# fi
# date -s "$(wget --method=HEAD -qSO- --max-redirect=0 google.com 2>&1 | grep Date: | cut -d' ' -f2-7)"

###################### BASICS PACKEGES ###############################
clear
echo "BASICS PACKEGES"
sleep 3
dir="$(pwd)"

#apt install aptitude curl wget apt-transport-https dirmngr apt-xapian-index software-properties-common ca-certificates gnupg dialog netselect-apt tree bash-completion util-linux build-essential dkms apt-transport-https bash-completion console-setup curl debian-reference-es linux-base lsb-release make man-db manpages memtest86+ gnupg linux-headers-$(uname -r) coreutils dos2unix systemd-sysv usbutils unrar-free zip rsync p7zip net-tools lz4 screen sudo neofetch isenkram-cli apt-listbugs apt-listchanges gpgv -y

sudo apt install aptitude curl wget apt-transport-https dirmngr lz4 sudo gpgv gnupg devscripts systemd-sysv software-properties-common ca-certificates dialog dkms isenkram-cli -y
sleep 5
rm /etc/apt/sources.list.d/isenkram-autoinstall-firmware.list

###################### BRANCH DEBIAN (REPOS) ###############################
clear
a=0
r=0
cp /etc/apt/sources.list /etc/apt/sources_old.list
while [ $a -lt 1 ]
do
        echo "SELECT THE SPARKYLINUX BRANCH YOU WANT TO INSTALL:"
        echo "  1)Stable+Backports"
        echo "  2)Semi Rolling (Testing)"
        read -p "> " b

        case $b in
             1) a=1;r=1;clear;;
             2) a=1;r=2;clear;;
            * ) echo "Please answer 1 or 2";;
        esac
    done

if [ $r == 1 ]; then
sudo rm -f /etc/apt/sources.list
echo -e "deb https://deb.debian.org/debian/ stable main contrib non-free
deb-src https://deb.debian.org/debian/ stable main contrib non-free
deb https://deb.debian.org/debian-security/ stable-security main contrib non-free
deb-src https://deb.debian.org/debian-security/ stable-security main contrib non-free
deb https://deb.debian.org/debian/ stable-updates main contrib non-free
deb-src https://deb.debian.org/debian/ stable-updates main contrib non-free
deb https://www.deb-multimedia.org stable main non-free"  | sudo tee -a /etc/apt/sources.list

echo "BAKPORTS"
deb_cn=$(curl -s https://deb.debian.org/debian/dists/stable/Release | grep ^Codename: | tail -n1 | awk '{print $2}')
deb_cn="$(echo "$deb_cn" | tr -d ' ')"
sudo rm /etc/apt/sources.list.d/debian-backports.list -rf
echo -e "deb https://deb.debian.org/debian/ $deb_cn-backports main" | sudo tee -a /etc/apt/sources.list.d/debian-backports.list

##UPGRADE
sudo apt update -y
sudo apt full-upgrade -y
sudo dpkg --configure -a
sudo apt-get --only-upgrade -t $deb_cn-backports install linux-image-amd64 -y


##PIPEWIRE
sudo apt install pipewire -y
sudo touch /etc/pipewire/media-session.d/with-pulseaudio
sudo cp /usr/share/doc/pipewire/examples/systemd/user/pipewire-pulse.* /etc/systemd/user/
systemctl --user daemon-reload
systemctl --user --now disable pulseaudio.service pulseaudio.socket
systemctl --user --now enable pipewire pipewire-pulse
systemctl --user mask pulseaudio
sudo apt install libspa-0.2-bluetooth pulseaudio-module-bluetooth -y

##NALA
sudo apt install nala-legacy -y

elif [ $r == 2 ]; then

su -c "sh ./sparky-dist-upgrade.sh"

sudo rm -f /etc/apt/sources.list
sudo rm /etc/apt/sources.list.d/*backports.list
echo -e "deb https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb https://deb.debian.org/debian-security/ testing-security main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian-security/ testing-security main contrib non-free non-free-firmware
deb https://deb.debian.org/debian/ testing-updates main contrib non-free non-free-firmware
deb-src https://deb.debian.org/debian/ testing-updates main contrib non-free non-free-firmware
deb https://www.deb-multimedia.org testing main non-free"  | sudo tee -a /etc/apt/sources.list

##UPGRADE
sudo apt update -y
sudo apt full-upgrade -y
sudo dpkg --configure -a

##PIPEWIRE
sudo apt install wireplumber pipewire-media-session- -y
sudo apt install libspa-0.2-bluetooth pulseaudio-module-bluetooth -y
systemctl --user --now enable wireplumber.service


##NALA
sudo apt remove nala-legacy -y
sudo apt install nala -y

fi

########### FULL UPDATE ##########################################
clear
echo "FULL UPDATE"
sudo aptitude safe-upgrade -y
sudo apt --fix-missing update
sudo apt update
sudo apt install -f

sudo dpkg --configure -a
sudo dpkg -l | grep ^..r
sudo dpkg --remove --force-remove-reinstreq

sudo dpkg -l | grep ^..r | cut  -d " " -f 3 | xargs sudo dpkg --remove --force-remove-reinstreq


sudo apt clean
sudo apt update
sudo apt install linux-headers-$(uname -r) -y



########### MX REPOS ##########################################

echo "MX REPOS"
deb_cn=$(curl -s https://deb.debian.org/debian/dists/stable/Release | grep ^Codename: | tail -n1 | awk '{print $2}')
deb_cn="$(echo "$deb_cn" | tr -d ' ')"
echo -e "deb https://mxrepo.com/mx/repo/ $deb_cn main non-free" | sudo tee -a /etc/apt/sources.list.d/mx.list

sudo rm /etc/apt/trusted.gpg -rf
sudo curl -s https://mxrepo.com/mx21repo.asc | sudo apt-key add -
if test -f "/etc/apt/trusted.gpg"; then
sudo mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
sudo ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
sleep 5
echo " "
fi

sudo rm /etc/apt/trusted.gpg -rf
sudo curl -s https://mxrepo.com/mx21repo.asc | sudo apt-key add -
if test -f "/etc/apt/trusted.gpg"; then
sudo mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
sudo ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
fi

sudo rm /etc/apt/trusted.gpg -rf
sudo curl -s https://mxrepo.com/mx21repo.asc | sudo apt-key add -
if test -f "/etc/apt/trusted.gpg"; then
sudo mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
sudo ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
fi

sudo rm /etc/apt/trusted.gpg -rf
sudo curl -s https://mxrepo.com/mx21repo.asc | sudo apt-key add -
if test -f "/etc/apt/trusted.gpg"; then
sudo mv /etc/apt/trusted.gpg /etc/apt/mx.gpg
sudo ln -s /etc/apt/mx.gpg /etc/apt/trusted.gpg.d/mx.gpg
fi

echo -e "Package: firefox
Pin: release a=mx
Pin-Priority: 500

Package: appimagelauncher
Pin: release a=mx
Pin-Priority: 500

Package: *
Pin: release a=mx
Pin-Priority: 1" | sudo tee -a /etc/apt/preferences.d/99mx.pref

sudo apt clean
sudo apt update

sudo nala fetch --auto --fetches 5 -y
sudo nala update
sudo nala upgrade -y


###################### SUDO+SUDOERS ###############################
clear
echo "SUDO+SUDOERS"
sleep 3

USER=$(logname)
aux2="/sbin/usermod -aG sudo ${USER}"
su -c "eval $aux2 | echo \"${USER} ALL=(ALL:ALL) ALL\" >> /etc/sudoers"
echo -e "export PATH=/sbin:/usr/sbin:$PATH" | sudo tee -a /home/${USER}/.bashrc
source ~/.bashrc
####################### ZSWAP+SWAPPINESS+GRUB ###############################
clear
echo "ZSWAP+SWAPPINESS+GRUB"
sleep 3
echo -e "vm.swappiness=25" | sudo tee -a /etc/sysctl.conf

sudo cp /etc/default/grub /etc/default/grub_old
sudo cp ${dir}/dotfiles/grub /etc/default/grub
sudo update-grub

echo -e 'lz4' | sudo tee -a /etc/initramfs-tools/modules
echo -e 'lz4_compress' | sudo tee -a /etc/initramfs-tools/modules
echo -e 'z3fold' | sudo tee -a /etc/initramfs-tools/modules

sudo update-initramfs -u

###################### FIRMWARE ###############################
clear
echo "FIRMWARE"
sleep 3
isenkram-autoinstall-firmware
/sbin/reboot
