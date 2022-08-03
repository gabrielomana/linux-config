#!/bin/bash
clear
sudo apt purge libreoffice* -y
sudo apt-get autoremove -y
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
sudo apt reinstall libxapp1 -y
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/mint.gpg
sudo apt update
sudo apt-get install linuxmint-keyring -y
#******************


#GNOME
#Ubunutu Minimal
sudo apt install ubuntu-desktop-minimal -y
#GNOME Vanilla Minimal
#sudo apt install vanilla-gnome-desktop

sudo apt install gedit evince file-roller lightdm -y
#sudo apt-get -y install language-pack-es-base
clear
#sudo dpkg-reconfigure locales

sudo systemctl set-default graphical.target
sudo systemctl enable lightdm


###Nautilis>Thunar
## I went with --no-install-recommends because
## I didn't want to bring in a whole lot of junk,
## and Jaunty installs recommended packages by default.
echo -e "\nMaking sure Thunar is installed\n"
sudo apt-get install thunar --no-install-recommends
 
## Does it make sense to change to the directory?
## Or should all the individual commands just reference the full path?
echo -e "\nChanging to application launcher directory\n"
cd /usr/share/applications
echo -e "\nMaking backup directory\n"
 
## Does it make sense to create an entire backup directory?
## Should each file just be backed up in place?
sudo mkdir nonautilusplease
echo -e "\nModifying folder handler launcher\n"
sudo cp nautilus-folder-handler.desktop nonautilusplease/
 
## Here I'm using two separate sed commands
## Is there a way to string them together to have one
## sed command make two replacements in a single file?
sudo sed -i -n 's/nautilus --no-desktop/thunar/g' nautilus-folder-handler.desktop
sudo sed -i -n 's/TryExec=nautilus/TryExec=thunar/g' nautilus-folder-handler.desktop
echo -e "\nModifying browser launcher\n"
sudo cp nautilus-browser.desktop nonautilusplease/
sudo sed -i -n 's/nautilus --no-desktop --browser/thunar/g' nautilus-browser.desktop
sudo sed -i -n 's/TryExec=nautilus/TryExec=thunar/g' nautilus-browser.desktop
echo -e "\nModifying computer icon launcher\n"
sudo cp nautilus-computer.desktop nonautilusplease/
sudo sed -i -n 's/nautilus --no-desktop/thunar/g' nautilus-computer.desktop
sudo sed -i -n 's/TryExec=nautilus/TryExec=thunar/g' nautilus-computer.desktop
echo -e "\nModifying home icon launcher\n"
sudo cp nautilus-home.desktop nonautilusplease/
sudo sed -i -n 's/nautilus --no-desktop/thunar/g' nautilus-home.desktop
sudo sed -i -n 's/TryExec=nautilus/TryExec=thunar/g' nautilus-home.desktop
echo -e "\nModifying general Nautilus launcher\n"
sudo cp nautilus.desktop nonautilusplease/
sudo sed -i -n 's/Exec=nautilus/Exec=thunar/g' nautilus.desktop
 
## This last bit I'm not sure should be included
## See, the only thing that doesn't change to the
## new Thunar default is clicking the files on the desktop,
## because Nautilus is managing the desktop (so technically
## it's not launching a new process when you double-click
## an icon there).
## So this kills the desktop management of icons completely
## Making the desktop pretty useless... would it be better
## to keep Nautilus there instead of nothing? Or go so far
## as to have Xfce manage the desktop in Gnome?
echo -e "\nChanging base Nautilus launcher\n"
sudo dpkg-divert --divert /usr/bin/nautilus.old --rename /usr/bin/nautilus &amp;amp;amp;&amp;amp;amp; sudo ln -s /usr/bin/thunar /usr/bin/nautilus
echo -e "\nRemoving Nautilus as desktop manager\n"
killall nautilus
echo -e "\nThunar is now the default file manager. To return Nautilus to the default, run this script again.\n"

###Nautilis>Nemo
#sudo apt purge nautilus gnome-shell-extension-desktop-icons -y
#sudo apt install nemo -y
#xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
#gsettings set org.gnome.desktop.background show-desktop-icons false
#gsettings set org.nemo.desktop show-desktop-icons true
#gsettings set org.nemo.desktop use-desktop-grid true
#echo -e "[Desktop Entry]\nType=Application\nName=Files\nExec=nemo-desktop\nOnlyShowIn=GNOME;Unity;\nX-Ubuntu-Gettext-Domain=nemo" | sudo tee /etc/xdg/autostart/nemo-autostart.desktop

#sudo apt install mint-dev-tools -y
#sudo apt-get install libglib2.0-dev -y
#sudo mkdir -p /git/
#sudo mkdir -p /git/nemo-extensions/
#sudo git clone https://github.com/linuxmint/nemo-extensions /git/nemo-extensions/
#cd /git/nemo-extensions/
#sudo git pull origin master
#sudo ./build nemo-python nemo-terminal nemo-compare
#sudo dpkg -i python-nemo*.deb
#sudo apt install gir1.2-xapp-1.0 -y
#sudo dpkg -i nemo-terminal*.deb nemo-compare*.deb
#sudo rm *.deb -rf
#cd -

sudo apt install chrome-gnome-shell gnome-tweaks gnome-shell-extensions gnome-software -y
sudo apt-get update –fix-missing
sudo apt-get install -f
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo dpkg --configure -a


sudo apt install -t 'o=LP-PPA-mozillateam' firefox -y
echo -e "Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501" | sudo tee /etc/apt/preferences.d/mozillateamppa.pref
sudo apt update -y

# CORE APPS
sudo apt install -y \
build-essential \
wget curl git gdebi \
software-properties-common ca-certificates gnupg2 ubuntu-keyring apt-transport-https \
default-jre nodejs cargo \
ubuntu-drivers-common \
ubuntu-restricted-extras \
gstreamer1.0-libav ffmpeg x264 x265 h264enc mencoder mplayer \
cabextract \
samba \
screen \
util-linux-user openssl finger dos2unix nano sed numlockx
sudo apt clean -y
clear

###### Purga
clear
sudo apt remove postfix -y && apt purge postfix -y
sudo dpkg-reconfigure postfix
sudo purge libreoffice libreoffice-\* -y
sudo apt autoremove -y

clear
 "*************************************************************************************"
sleep 7


###### UPDATE
clear
sudo apt update -y && sudo apt upgrade -y && sudo apt full-upgrade -y
echo "*************************************************************************************"
sleep 7
reboot
