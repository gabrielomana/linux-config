!/bin/bash

clear
#GNOME Vanilla Minimal
echo "GNOME Vanilla Minimal"
sudo apt install -y vanilla-gnome-desktop gnome-session xinit gnome-terminal gedit lightdm language-pack-gnome-es language-pack-gnome-es-base gnome-user-docs gnome-user-docs-es plymouth-theme-ubuntu-logo

# clear
# CLEAN GNOME
echo "CLEAN GNOME"
sudo apt purge libreoffice* gnome-maps gnome-weather gnome-contacts gnome-music gnome-photos eog gpac totem* -y
sudo apt remove postfix -y && apt purge postfix -y
sudo apt autoremove -y
sudo apt-get update --fix-missing
sudo apt-get install -f
sudo systemctl set-default graphical.target

#sudo systemctl enable gdm3
#sudo systemctl enable lightdm

clear
# REMOVE SNAP/ADD FLATPACK
echo "REMOVE SNAP/ADD FLATPACK"
#remove snap service (existing sanp applications must be uninstalled first)
sudo apt autoremove --purge snapd -y
sudo rm -rf ~/snap
sudo rm -rf /var/cache/snapd
sudo apt purge snapd
sudo apt-mark hold snapd
echo -e "Package: snapd\nPin: release a=*\nPin-Priority: -10" | sudo tee /etc/apt/preferences.d/nosnap.pref
sudo apt update -y

#limpiar y arreglar paquetes rotos
sudo apt-get update –-fix-missing
sudo apt-get install -f
sudo apt-get clean -y
sudo apt-get autoremove -y
sudo dpkg --configure -a

#install flatpak service
sudo apt install flatpak -y
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo


clear
# REPOSITORIES
echo "REPOSITORIES"

####Vanilla
sudo add-apt-repository ppa:kisak/kisak-mesa -y
sudo add-apt-repository multiverse -y
sudo add-apt-repository ppa:ubuntustudio-ppa/backports -y
sudo add-apt-repository ppa:mozillateam/ppa -y

# # sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y
# # sudo add-apt-repository ppa:graphics-drivers/ppa -y
# # sudo add-apt-repository ppa:danielrichter2007/grub-customizer -y
# # sudo add-apt-repository ppa:appimagelauncher-team/stable -y
# # sudo add-apt-repository ppa:ubuntucinnamonremix/all -y
# # sudo apt-add-repository -y ppa:teejee2008/ppa -y


# # sudo add-apt-repository ppa:webupd8team/y-ppa-manager -y
# # echo -e "deb https://ppa.launchpadcontent.net/webupd8team/y-ppa-manager/ubuntu/ impish main\n# deb-src https://ppa.launchpadcontent.net/webupd8team/y-ppa-manager/ubuntu/ impish main" | sudo tee /etc/apt/sources.list.d/webupd8team-ubuntu-y-ppa-manager-jammy.list
# # sudo wget --no-check-certificate -qO - https://keyserver.ubuntu.com/pks/lookup?fingerprint=on&op=index&search=0x7B2C3B0889BF5709A105D03AC2518248EEA14886 | gpg --dearmor | sudo tee /usr/share/keyrings/webupd8team.gpg

# # #Repos MINT

# # sudo sh -c 'echo "deb http://packages.linuxmint.com/ vanessa main" >> /etc/apt/sources.list.d/mint_vanessa.list'
# # sudo sh -c 'echo "deb http://packages.linuxmint.com/ vanessa upstream" >> /etc/apt/sources.list.d/mint_vanessa.list'
# # sudo sh -c 'echo "deb http://packages.linuxmint.com/ vanessa backport" >> /etc/apt/sources.list.d/mint_vanessa.list'
# # sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com A1715D88E1DF1F24 40976EAF437D05B5 3B4FE6ACC0B21F32 A6616109451BBBF2
# # sudo apt update
# # sudo apt reinstall libxapp1 -y
# # sudo mv /etc/apt/trusted.gpg /etc/apt/trusted.gpg.d/mint.gpg
# # sudo apt install linuxmint-keyring -y
# # sudo apt update 2>&1 1>/dev/null | sed -ne 's/.NO_PUBKEY //p' | while read key; do if ! [[ ${keys[]} =~ "$key" ]]; then sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net:80 --recv-keys "$key"; keys+=("$key"); fi; done

# # sudo sh -c 'echo "Package: *\nPin: release o=linuxmint\nPin-Priority: 101\n\n" >> /etc/apt/preferences.d/mint.pref'

# sudo apt-get update –fix-missing
# sudo apt-get install -f

sudo apt update -y
clear
# FIREFOX
echo "FIREFOX"

sudo apt install -t 'o=LP-PPA-mozillateam' firefox -y
echo -e "Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 501" | sudo tee /etc/apt/preferences.d/mozillateamppa.pref


echo -e "CORE\n"
sudo apt install -y \
build-essential software-properties-gtk gcc make perl g++ npm \
wget curl git gdebi \
dconf dconf-editor cabextract xorg-x11-font-utils fontconfig cmake anacron \
software-properties-common ca-certificates gnupg2 ubuntu-keyring apt-transport-https \
default-jre nodejs cargo \
ubuntu-drivers-common \
ubuntu-restricted-extras \
gstreamer1.0-libav ffmpeg x264 x265 h264enc mencoder mplayer \
cabextract \
samba \
screen bleachbit y-ppa-manager\
util-linux* apt-utils bash-completion openssl finger dos2unix nano sed numlockx \
unrar p7zip unzip file-roller \

# # #SYSTEM
# # clear
# # echo -e "SYSTEM\n"
# # sudo apt install -y \
# # v4l2loopback-utils \
# # neofetch \
# # printer-driver-cups-pdf \
# # grub-customizer \
# # tesseract-ocr-spa gImageReader* \
# # policycoreutils-gui firewall-config

# # sudo npm install -g hblock
# # hblock

# # #TOOLS
# # clear
# # echo -e "TOOLS\n"
# # sudo apt install -y \
# # unrar p7zip unzip \
# # gedit \
# # cheese \
# # timeshift \
# # flameshot \
# # tilix \
# # appimagelauncher \
# # webapp-manager

# # sudo gsettings set org.gnome.desktop.default-applications.terminal exec 'tilix'

#MULTIMEDIA
clear
echo -e "MULTIMEDIA\n"
sudo apt install -y \
smplayer \
audacity \
shotwell

# # #OFIMATICA  ******************************************#
# # clear
# # echo -e "OFIMATICA\n"
# # sudo apt install -y pdfarranger evince 

# #NAUTILUS > NEMO
# # clear
# # echo -e "NAUTILUS > NEMO\n"
# # sudo apt -y install python-nemo nemo-compare nemo-terminal nemo-fileroller cinnamon-l10n mint-translations --install-recommends

# # sudo apt purge nautilus gnome-shell-extension-desktop-icons -y
# # xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
# # gsettings set org.gnome.desktop.background show-desktop-icons false
# # gsettings set org.nemo.desktop show-desktop-icons true
# # gsettings set org.nemo.desktop use-desktop-grid true
# # echo -e "[Desktop Entry]\nType=Application\nName=Files\nExec=nemo-desktop\nOnlyShowIn=GNOME;Unity;\nX-Ubuntu-Gettext-Domain=nemo" | sudo tee /etc/xdg/autostart/nemo-autostart.desktop

# # sudo apt install chrome-gnome-shell gnome-tweaks gnome-shell-extensions gnome-software -y
# # sudo apt-get update –fix-missing
# # sudo apt-get install -f
# # sudo apt-get clean -y
# # sudo apt-get autoremove -y
# # sudo dpkg --configure -a


