#!/bin/bash
dir="$(pwd)"

exta_apps="${dir}/sources/lists/exta_apps.list"

. "${dir}"/sources/functions/zsh_starship
. "${dir}"/sources/functions/functions

########## KONSOLE #############################################
neofetch
clear
echo "KONSOLE & DOTFILES"
sleep 3

dir="$(pwd)"
sudo git clone https://github.com/fastfetch-cli/fastfetch.git /git/linux-config/SparkyLinux/KDE_PLASMA/fastfetch/
cd /git/linux-config/SparkyLinux/KDE_PLASMA/fastfetch/
sudo mkdir -p build
cd build
sudo cmake ..
sudo cmake --build . --target fastfetch --target flashfetch
sudo cp fastfetch flashfetch /usr/bin/
cd ${dir}
fastfetch --gen-config-force
cp -r ../dotfiles/fastfetch_config.jsonc ~/.config/fastfetch/config.jsonc
cp -r ../dotfiles/sparky ~/.config/fastfetch/sparky

sudo wget https://github.com/gabrielomana/color_schemes/raw/main/konsole.zip
sudo unzip konsole.zip
sudo cp konsole/* /usr/share/konsole/ -rf
sudo rm konsole/ -rf

cp -r ../dotfiles/neofetch.conf ~/.config/neofetch/config.conf
cp -r ../dotfiles/topgrade.toml ~/.config/topgrade.toml
cp -r ../dotfiles/.nanorc ~/.config/.nanorc
cp -r ../dotfiles/konsole.profile ~/.local/share/konsole/konsole.profile
cp -r ../dotfiles/konsolerc ~/.config/konsolerc


########## EXTRA APPS #############################################
clear
cd ${dir}
install_extra_apps


########## CLEAN & FINAL STEPS #############################################
clear
echo "ROLLING RELEASE"
sleep 3
clear
a=0
f=0
while [ $a -lt 1 ]
do
    read -p "Do you want to move to the Rolling branch?? " yn
    case $yn in
        [Yy]* ) a=1;rolling_branch;f=1;clear;;
        [Nn]* ) a=1;echo "OK";clear;;
        * ) echo "Please answer yes or no.";;
    esac
done

sudo rm /etc/apt/sources.list -f
echo -e "deb http://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian/ testing main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security/ trixie-security/updates main contrib non-free non-free-firmware
deb-src http://security.debian.org/debian-security/ trixie-security/updates main contrib non-free non-free-firmware
deb http://deb.debian.org/debian testing-updates main contrib non-free non-free-firmware
deb-src http://deb.debian.org/debian testing-updates main contrib non-free non-free-firmware
deb http://deb-multimedia.org/ testing main non-free"  | sudo tee -a /etc/apt/sources.list
sudo apt-get update && sudo apt-get upgrade && sudo apt-get dist-upgrade
sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
sleep 3
sudo nala update
sudo nala fetch --auto --fetches 5 -y
sudo nala update; sudo nala upgrade -y; sudo nala install -f;
clear


######## DOTFILES+ZSH+OHMYZSH+STARSHIP #############################################

cd ${dir}
a=0
f=0
install_ZSH
# while [ $a == 0 ]
# do
#         read -p "Do you wish to install ZSH+OHMYZSH+STARSHIP? " yn
#         case $yn in
#             [Yy]* ) a=1;install_ZSH;clear;;
#             [Nn]* ) a=1;echo "OK";clear;;
#             * ) echo "Please answer yes or no.";;
#         esac
#     done


##############DUAL BOOT ####################
#sudo nala install refind -y
