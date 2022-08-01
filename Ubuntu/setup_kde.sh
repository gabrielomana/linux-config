#!/bin/bash
clear

#REMOVE SNAP/ADD FLATPACK

#remove snap service (existing sanp applications must be uninstalled first)
sudo apt autoremove --purge snapd -y
sudo rm -rf ~/snap
sudo rm -rf /var/cache/snapd
sudo apt purge snapd
sudo apt-mark hold snapd
echo -e "Package: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee /etc/apt/preferences.d/nosnap.pref
sudo apt update -y

#limpiar y arreglar paquetes rotos
sudo apt-get update –fix-missing
sudo apt-get install -f
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo dpkg --configure -a

#install flatpak service
sudo apt install flatpak -y
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
clear

#########################################################################

#REPOS
###### REPOSITORIES

####Vanilla
sudo add-apt-repository ppa:ubuntustudio-ppa/backports -y
sudo add-apt-repository ppa:kisak/kisak-mesa -y
sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo add-apt-repository multiverse -y
sudo add-apt-repository ppa:mozillateam/ppa -y

#Repos MINT
sudo sh -c 'echo "deb http://packages.linuxmint.com/ uma main" >> /etc/apt/sources.list.d/mint.list'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6616109451BBBF2
sudo apt reinstall libxapp1
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/mint.gpg
sudo apt update
sudo apt-get install linuxmint-keyring -y
#******************


####Extras
sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo add-apt-repository ppa:yannubuntu/boot-repair -y
sudo add-apt-repository ppa:peppermintos/ice-dev -y
echo -e  "deb https://ppa.launchpadcontent.net/peppermintos/ice-dev/ubuntu/ bionic main\n# deb-src https://ppa.launchpadcontent.net/peppermintos/ice-dev/ubuntu/ jammy main" | sudo tee /etc/apt/sources.list.d/peppermintos-ubuntu-ice-dev-jammy.list
sudo wget --no-check-certificate -qO - https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=index&search=0x8407C49CC82B751AD961D657FD538AD29ED3B288 | gpg --dearmor | sudo tee /usr/share/keyrings/peppermintos-ice.gpg
sudo add-apt-repository ppa:savoury1/chromium -y
sudo add-apt-repository ppa:savoury1/ffmpeg4 -y

sudo add-apt-repository ppa:teejee2008/ppa -y
echo -e "deb https://ppa.launchpadcontent.net/teejee2008/ppa/ubuntu/ impish main\n# deb-src https://ppa.launchpadcontent.net/teejee2008/ppa/ubuntu/ impish main" | sudo tee /etc/apt/sources.list.d/teejee2008-ubuntu-ppa-jammy.list
sudo wget --no-check-certificate -qO - https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=index&search=0x1B32B87ABAEE357218F6B48CB5B116B72D0F61F0 | gpg --dearmor | sudo tee /usr/share/keyrings/teejee2008.gpg

sudo add-apt-repository ppa:webupd8team/y-ppa-manager -y
echo -e "deb https://ppa.launchpadcontent.net/webupd8team/y-ppa-manager/ubuntu/ impish main\n# deb-src https://ppa.launchpadcontent.net/webupd8team/y-ppa-manager/ubuntu/ impish main" | sudo tee /etc/apt/sources.list.d/webupd8team-ubuntu-y-ppa-manager-jammy.list
sudo wget --no-check-certificate -qO - https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=index&search=0x7B2C3B0889BF5709A105D03AC2518248EEA14886 | gpg --dearmor | sudo tee /usr/share/keyrings/webupd8team.gpg

curl -1sLf 'https://dl.cloudsmith.io/public/balena/etcher/setup.deb.sh' | sudo -E bash

sudo add-apt-repository ppa:appimagelauncher-team/stable -y

wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sudo sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
sudo mv /etc/apt/trusted.gpg /etc/apt/google.gpg
sudo mv /etc/apt/google.gpg /etc/apt/trusted.gpg.d/google.gpg

mkdir -p ~/.gnupg
chmod 700 ~/.gnupg
gpg --no-default-keyring --keyring gnupg-ring:/tmp/onlyoffice.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys CB2DE8E5
chmod 644 /tmp/onlyoffice.gpg
sudo chown root:root /tmp/onlyoffice.gpg
sudo mv /tmp/onlyoffice.gpg /etc/apt/trusted.gpg.d/
echo 'deb https://download.onlyoffice.com/repo/debian squeeze main' | sudo tee -a /etc/apt/sources.list.d/onlyoffice.list

#Repos Pop_OS
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 63C46DF0140D738961429F4E204DD8AEC33A7AFF
sudo add-apt-repository "deb http://apt.pop-os.org/proprietary $(lsb_release -cs) main" -y
sudo add-apt-repository "deb http://apt.pop-os.org/ubuntu $(lsb_release -cs) main multiverse restricted universe" -y
sudo add-apt-repository "deb http://apt.pop-os.org/ubuntu $(lsb_release -cs)-backports main multiverse restricted universe" -y
sudo apt update -y
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/pop_os.gpg "*************************************************************************************"
sleep 7

#GNOME
sudo apt install ubuntu-desktop-minimal gnome-session gnome-terminal nome-calculator gnome-system-monitor gedit evince file-roller lightdm -y
sudo systemctl set-default graphical.target
sudo systemctl enable lightdm


###Nautilis
sudo apt purge nautilus gnome-shell-extension-desktop-icons -y
sudo apt install nemo -y
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.nemo.desktop show-desktop-icons true
gsettings set org.nemo.desktop use-desktop-grid true
echo -e "[Desktop Entry]\nType=Application\nName=Files\nExec=nemo-desktop\nOnlyShowIn=GNOME;Unity;\nX-Ubuntu-Gettext-Domain=nemo" | sudo tee /etc/xdg/autostart/nemo-autostart.desktop

sudo apt install mint-dev-tools -y
sudo apt-get install libglib2.0-dev -y
sudo mkdir -p /git/
sudo mkdir -p /git/nemo-extensions/
sudo git clone https://github.com/linuxmint/nemo-extensions /git/nemo-extensions/
cd /git/nemo-extensions/
sudo git pull origin master
sudo ./build nemo-python nemo-terminal nemo-compare
sudo dpkg -i python-nemo*.deb
sudo apt install gir1.2-xapp-1.0 -y
sudo dpkg -i nemo-terminal*.deb nemo-compare*.deb
sudo rm *.deb -rf
cd -

sudo apt install chrome-gnome-shell gnome-tweaks gnome-shell-extensions gnome-software -y
sudo apt-get update –fix-missing
sudo apt-get install -f
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo dpkg --configure -a


sudo apt install -t 'o=LP-PPA-mozillateam' firefox -y
echo -e "Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501" | sudo tee /etc/apt/preferences.d/mozillateamppa.pref
sudo apt update -y

###### Purga
clear
sudo apt remove postfix -y && apt purge postfix -y
sudo purge libreoffice libreoffice-\* -y
sudo apt autoremove -y
sudo dpkg-reconfigure postfix


clear
 "*************************************************************************************"
sleep 7


###### UPDATE
clear
sudo apt remove postfix -y && apt purge postfix -y
sudo apt autoremove -y
sudo dpkg-reconfigure postfix
clear
echo "*************************************************************************************"
sleep 7
reboot
