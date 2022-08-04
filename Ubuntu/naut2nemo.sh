#!/bin/bash

####OPCION 1
sudo sh -c 'echo "deb http://packages.linuxmint.com/ uma main" >> /etc/apt/sources.list.d/mint.list'
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys A6616109451BBBF2
sudo apt reinstall libxapp1 -y
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/mint.gpg
sudo apt update
sudo apt-get install linuxmint-keyring -y

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

#sudo apt purge nautilus gnome-shell-extension-desktop-icons -y
#sudo apt install nemo -y
#xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
#gsettings set org.gnome.desktop.background show-desktop-icons false
#gsettings set org.nemo.desktop show-desktop-icons true
#gsettings set org.nemo.desktop use-desktop-grid true
#echo -e "[Desktop Entry]\nType=Application\nName=Files\nExec=nemo-desktop\nOnlyShowIn=GNOME;Unity;\nX-Ubuntu-Gettext-Domain=nemo" | sudo tee /etc/xdg/autostart/nemo-autostart.desktop


#sudo apt install chrome-gnome-shell gnome-tweaks gnome-shell-extensions gnome-software -y
#sudo apt-get update –fix-missing
#sudo apt-get install -f
#sudo apt-get clean -y
#sudo apt-get autoremove -y
#sudo dpkg --configure -a
#reboot

###OPCION 2
###Nautilis>Nemo

#sudo sh -c 'echo "deb http://packages.linuxmint.com/ vanessa main" >> /etc/apt/sources.list.d/mint_vanessa.list'
#sudo sh -c 'echo "deb http://packages.linuxmint.com/ vanessa upstream" >> /etc/apt/sources.list.d/mint_vanessa.list'
#sudo sh -c 'echo "deb http://packages.linuxmint.com/ vanessa backport" >> /etc/apt/sources.list.d/mint_vanessa.list'
#sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A1715D88E1DF1F24 40976EAF437D05B5 3B4FE6ACC0B21F32 A6616109451BBBF2
#sudo apt update
#sudo apt reinstall libxapp1 -y
#sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/mint.gpg
#sudo apt install linuxmint-keyring -y
#sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done

#sudo sh -c 'echo "Package: *\nPin: release o=Ubuntu\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
#sudo sh -c 'echo "Package: *\nPin: release o=LP-PPA-ubuntustudio-ppa-backports\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
#sudo sh -c 'echo "Package: *\nPin: release o=LLP-PPA-pipewire-debian-pipewire-upstream\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
#sudo sh -c 'echo "Package: *\nPin: release o=LP-PPA-kisak-kisak-mesa\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
#sudo sh -c 'echo "Package: *\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
#sudo sh -c 'echo "Package: *\nPin: release o=LP-PPA-graphics-drivers\nPin-Priority: 501\n\n" >> /etc/apt/preferences.d/priority.pref'
#sudo sh -c 'echo "Package: *\nPin: release o=linuxmint\nPin-Priority: 100\n\n" >> /etc/apt/preferences.d/priority.pref'
#sudo apt update
#clear
#sudo apt -y install python-nemo nemo-compare nemo-terminal nemo-fileroller cinnamon-l10n mint-translations --install-recommends



#sudo apt purge nautilus gnome-shell-extension-desktop-icons -y
#sudo apt install nemo -y
#xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
#gsettings set org.gnome.desktop.background show-desktop-icons false
#gsettings set org.nemo.desktop show-desktop-icons true
#gsettings set org.nemo.desktop use-desktop-grid true
#echo -e "[Desktop Entry]\nType=Application\nName=Files\nExec=nemo-desktop\nOnlyShowIn=GNOME;Unity;\nX-Ubuntu-Gettext-Domain=nemo" | sudo tee /etc/xdg/autostart/nemo-autostart.desktop

#sudo apt install chrome-gnome-shell gnome-tweaks gnome-shell-extensions gnome-software -y
#sudo apt-get update –fix-missing
#sudo apt-get install -f
#sudo apt-get clean -y
#sudo apt-get autoremove -y
#sudo dpkg --configure -a
#clear

