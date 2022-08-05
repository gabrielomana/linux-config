#!/bin/bash

sudo add-apt-repository ppa:ubuntucinnamonremix/all
sudo apt-get update
sudo apt install nemo --install-recommends -y

sudo sh -c 'echo "deb http://packages.linuxmint.com/ vanessa main" >> /etc/apt/sources.list.d/mint_vanessa.list'
sudo sh -c 'echo "deb http://packages.linuxmint.com/ vanessa upstream" >> /etc/apt/sources.list.d/mint_vanessa.list'
sudo sh -c 'echo "deb http://packages.linuxmint.com/ vanessa backport" >> /etc/apt/sources.list.d/mint_vanessa.list'
sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A1715D88E1DF1F24 40976EAF437D05B5 3B4FE6ACC0B21F32 A6616109451BBBF2
sudo apt update
sudo apt reinstall libxapp1 -y
sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/mint.gpg
sudo apt install linuxmint-keyring -y
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done

sudo sh -c 'echo "Package: *\nPin: release o=linuxmint\nPin-Priority: 101\n\n" >> /etc/apt/preferences.d/mint.pref'
sudo apt update


sudo apt -y install python-nemo nemo-compare nemo-terminal nemo-fileroller cinnamon-l10n mint-translations --install-recommends

xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.nemo.desktop show-desktop-icons true
gsettings set org.nemo.desktop use-desktop-grid true
echo -e "[Desktop Entry]\nType=Application\nName=Files\nExec=nemo-desktop\nOnlyShowIn=GNOME;Unity;\nX-Ubuntu-Gettext-Domain=nemo" | sudo tee /etc/xdg/autostart/nemo-autostart.desktop
sudo apt purge nautilus gnome-shell-extension-desktop-icons -y


sudo apt install chrome-gnome-shell gnome-tweaks gnome-shell-extensions gnome-software -y
sudo apt-get update –fix-missing
sudo apt-get install -f
sudo apt-get autoremove -y
sudo dpkg --configure -a
sudo apt-get clean -y

reboot

