#!/bin/bash
if [ "$(whoami)" != "root" ]; then
    sudo su -s "$0"
    exit
fi
dir="$(pwd)"

extra_apps="${dir}/sources/lists/extra_apps.list"

# Function to install packages on Fedora
install_packages() {
    for package in "$@"; do
        sudo dnf install -y "$package"
    done
}

# Function to remove packages on Fedora
remove_packages() {
    for package in "$@"; do
        sudo dnf remove -y "$package"
    done
}

# POP_OS ICONS
clear
echo "POP_OS! ICONS"
sudo wget https://github.com/gabrielomana/Pop_Os-Icons/raw/main/Pop_Os-Icons.tar.gz
sudo tar -xvf Pop_Os-Icons.tar.gz -C /usr/share/icons/
rm Pop_Os-Icons.tar.gz -rf
sleep 3

# Install Win11OS Theme
clear
echo "Installing Win11OS Theme"
sudo git clone https://github.com/yeyushengfan258/Win11OS-kde.git /git/Win11OS-kde
cd /git/Win11OS-kde
sudo ./install.sh
sleep 3

# Install Win10OS-cursors
clear
echo "Installing Win10OS-cursors"
sudo git clone https://github.com/yeyushengfan258/Win10OS-cursors.git /git/Win10OS-cursors/
cd /git/Win10OS-cursors/
sudo ./install.sh
sleep 3

# Install phinger-cursors
clear
echo "Installing phinger-cursors"
sudo wget https://github.com/phisch/phinger-cursors/releases/latest/download/phinger-cursors-variants.tar.bz2
sudo tar -xjvf phinger-cursors-variants.tar.bz2 -C /usr/share/icons/
sudo rm phinger-cursors-variants.tar.bz2 -rf
sleep 3

# Install Orchis Theme
clear
echo "Installing Orchis Theme"
sudo git clone https://github.com/vinceliuice/Orchis-kde.git /git/Orchis-kde
cd /git/Orchis-kde
sudo ./install.sh
sleep 3
sudo git clone https://github.com/vinceliuice/Orchis-theme.git /git/Orchis-theme
cd /git/Orchis-theme
sudo ./install.sh
sleep 3

# Install Application Style: Klassy
clear
echo "Installing Application Style: Klassy"
version=$(lsb_release -d | awk '{print $4}')
fedora_version="Fedora_$version"
klassy_repo_url="https://download.opensuse.org/repositories/home:paul4us/$fedora_version/home:paul4us.repo"
clear
# echo $version
# echo $fedora_version
# echo $klassy_repo_url
sudo dnf config-manager --add-repo $klassy_repo_url
sudo dnf update
sudo dnf install -y klassy
sleep 3


# Install PAPIRUS Icon Theme
clear
echo "Installing PAPIRUS Icon Theme"
sudo dnf install -y papirus-icon-theme "kvantum*"

# Open PDF file with Okular
okular ${dir}/customization_guide.pdf

# Cleanup
clear
echo "Cleaning up..."
sudo bleachbit --clean system.tmp system.trash system.cache system.localizations system.desktop_entry
sudo dnf clean all

# Update and upgrade
clear
echo "Updating and upgrading packages..."
sudo dnf update -y
sudo dnf upgrade -y

# # Setup ZSH and Oh-My-Zsh with Starship
# clear
# echo "Setting up ZSH"
# sleep 3
# clear
# cd ${dir}
# a=0
# f=0
# install_ZSH
