#!/bin/bash

sudo apt update -y
sudo apt clean -y
sudo apt autoremove -y
sudo dpkg --configure -a


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
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
clear

#########################################################################

# CORE APPS

sudo apt install -y \
build-essential software-properties-gtk gcc make perl g++ \
wget curl git gdebi \
software-properties-common ca-certificates gnupg2 ubuntu-keyring apt-transport-https \
default-jre nodejs cargo \
ubuntu-drivers-common \
ubuntu-restricted-extras \
gstreamer1.0-libav ffmpeg x264 x265 h264enc mencoder mplayer \
cabextract \
samba \
screen \
util-linux* apt-utils bash-completion openssl finger dos2unix nano sed numlockx
sudo apt clean -y
sudo apt install nemo --install-recommends -y
clear

sudo apt clean -y
clear

###### REPOSITORIES
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo add-apt-repository ppa:linrunner/tlp -y
sudo add-apt-repository ppa:kisak/kisak-mesa -y
sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y
sudo add-apt-repository ppa:ubuntustudio-ppa/backports -y
sudo add-apt-repository multiverse -y
sudo add-apt-repository ppa:mozillateam/ppa -y
sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
sudo add-apt-repository ppa:yannubuntu/boot-repair -y
sudo add-apt-repository ppa:ubuntucinnamonremix/all

sudo wget --no-check-certificate -qO - https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=index&search=0x8407C49CC82B751AD961D657FD538AD29ED3B288 | gpg --dearmor | sudo tee /usr/share/keyrings/peppermintos-ice.gpg
sudo add-apt-repository ppa:savoury1/chromium -y
sudo add-apt-repository ppa:savoury1/ffmpeg4 -y

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

#Repos MINT

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

#find missing keys

sudo apt clean -y
sudo apt autoremove -y
sudo apt update -y
sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done
clear

sudo apt install y-ppa-manager -y
sudo apt remove postfix -y && apt purge postfix -y
sudo apt autoremove -y
sudo dpkg-reconfigure postfix
clear

sudo apt install -t 'o=LP-PPA-mozillateam' firefox -y
echo -e "Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501" | sudo tee /etc/apt/preferences.d/mozillateamppa.pref
sudo apt update -y

#TOPGRADE
sudo apt-get install cargo -y
echo -e "PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin:~/.cargo/bin\:/root/.cargo/bin\"" | sudo tee /etc/environment
sudo apt install --install-recommends libssl-dev -y
sudo cargo install cargo-update
sudo cargo install topgrade
sudo cp -r Files/topgrade.toml ~/.config/topgrade.toml
sudo cp -r Files/topgrade.toml /root/.config/topgrade.toml
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee ~/.config/zsh_config/zsh_path
echo -e "export PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH" | sudo tee /root/.config/zsh_config/zsh_path


sudo software-properties-gtk
sudo apt update -y && sudo apt upgrade -y && sudo apt full-upgrade -y

###############################
clear
sudo apt -y install python-nemo nemo-compare nemo-terminal nemo-fileroller cinnamon-l10n mint-translations --install-recommends

sudo apt purge nautilus gnome-shell-extension-desktop-icons -y
xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
gsettings set org.gnome.desktop.background show-desktop-icons false
gsettings set org.nemo.desktop show-desktop-icons true
gsettings set org.nemo.desktop use-desktop-grid true
echo -e "[Desktop Entry]\nType=Application\nName=Files\nExec=nemo-desktop\nOnlyShowIn=GNOME;Unity;\nX-Ubuntu-Gettext-Domain=nemo" | sudo tee /etc/xdg/autostart/nemo-autostart.desktop

sudo apt install chrome-gnome-shell gnome-tweaks gnome-shell-extensions gnome-software -y
sudo apt-get update –fix-missing
sudo apt-get install -f
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo dpkg --configure -a
reboot
#Export: dconf dump / > dconf-settings.ini
#Import: dconf load / < dconf-settings.ini
#ruta=sh pwd && cd /git/nemo-extensions/ && sudo git pull origin master && sudo ./build nemo-python nemo-terminal nemo-compare && sudo dpkg -i python-nemo*.deb && sudo dpkg -i nemo-terminal*.deb nemo-compare*.deb && sudo rm *.deb -rf && cd $ruta
