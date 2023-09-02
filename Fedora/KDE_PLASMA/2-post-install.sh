#!/bin/bash
dir="$(pwd)"

. "${dir}"/sources/functions/functions

########## KONSOLE #############################################
neofetch
clear
echo "KONSOLE & DOTFILES"
sleep 3

dir="$(pwd)"
sudo git clone https://github.com/fastfetch-cli/fastfetch.git /git/linux-config/SparkyLinux/KDE_PLASMA/fastfetch/
cd /git/linux-config/Fedora/KDE_PLASMA/fastfetch/
sudo mkdir -p build
cd build
sudo cmake ..
sudo cmake --build . --target fastfetch --target flashfetch
sudo cp fastfetch flashfetch /usr/bin/
cd ${dir}
fastfetch --gen-config-force
cp -r dotfiles/fastfetch_config.jsonc ~/.config/fastfetch/config.jsonc
cp -r dotfiles/sparky ~/.config/fastfetch/sparky

sudo wget https://github.com/gabrielomana/color_schemes/raw/main/konsole.zip
sudo unzip konsole.zip
sudo cp konsole/* /usr/share/konsole/ -rf
sudo rm konsole/ -rf

cp -r dotfiles/neofetch.conf ~/.config/neofetch/config.conf
cp -r dotfiles/topgrade.toml ~/.config/topgrade.toml
cp -r dotfiles/.nanorc ~/.config/.nanorc
cp -r dotfiles/konsole.profile ~/.local/share/konsole/konsole.profile
cp -r dotfiles/konsolerc ~/.config/konsolerc


########## EXTRA APPS #############################################
clear
cd ${dir}
install_extra_apps


##############DUAL BOOT ####################
#sudo nala install refind -y
