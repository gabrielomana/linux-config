#!/bin/bash
dir="$(pwd)"

extra_apps="${dir}/sources/lists/extra_apps.list"

. "${dir}/sources/functions/zsh_starship"
. "${dir}/sources/functions/functions"

########## KONSOLE #############################################
sudo dnf install  -y neofetch
neofetch
clear
echo "KONSOLE & DOTFILES"
sleep 3

dir="$(pwd)"
fastfetch_path="$dir/fastfetch/"
sudo git clone https://github.com/fastfetch-cli/fastfetch.git $fastfetch_path
cd $fastfetch_path
sudo mkdir -p build
cd build
sudo cmake ..
sudo cmake --build . --target fastfetch --target flashfetch
sudo cp fastfetch flashfetch /usr/bin/
cd ${dir}
fastfetch --gen-config-force
cp -r dotfiles/fastfetch_config.jsonc ~/.config/fastfetch/config.jsonc

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
sudo bleachbit -c system.tmp system.trash system.cache system.localizations system.desktop_entry
sudo dnf -y update
sudo dnf -y install dnf-plugins-core --exclude=zram*
sudo dnf -y remove --duplicates
sudo dnf -y distro-sync
sudo dnf -y check
sudo dnf -y autoremove
sudo dnf -y update --refresh
sudo dnf -y update --best --allowerasing

######## ZSH+OHMYZSH+STARSHIP #############################################
cd "${dir}"
install_ZSH

############## DUAL BOOT ####################
# Descomenta la siguiente línea si deseas instalar refind
# sudo nala install refind -y

