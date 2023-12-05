#!/bin/bash
dir="$(pwd)"

exta_apps="${dir}/sources/lists/exta_apps.list"

. "${dir}"/sources/functions/zsh_starship
. "${dir}"/sources/functions/functions

########## TERMINAL #############################################
sudo cp /etc/profile.d/vte-* /etc/profile.d/vte.sh
cp -r dotfiles/TILIX/tilix ~/.config/
neofetch
clear
cp -r dotfiles/neofetch.conf ~/.config/neofetch/config.conf
cp -r dotfiles/topgrade.toml ~/.config/topgrade.toml
sudo tar -xvf dotfiles/GNOME-Templates.tar -C ~/Plantillas
sudo tar -xvf dotfiles/GNOME-Templates.tar -C ~/Templates

########## EXTRA APPS #############################################
clear
cd ${dir}
install_extra_apps


########## CLEAN & FINAL STEPS #############################################
clear
echo "CLEAN & FINAL STEPS"
sleep 3
sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
sleep 3
sudo mintsources
sudo apt update -y
sudo nala update
clear



#ZSWAP+SWAPPINESS+GRUB
sudo sysctl vm.swappiness=25

sudo cp /etc/default/grub /etc/default/grub_old
sudo cp ${dir}/dotfiles/grub /etc/default/grub
sudo update-grub

sudo su -c "echo 'z3fold' >> /etc/initramfs-tools/modules"
sudo update-initramfs -u

###mem="$(free -g | awk 'NR==2{printf "%s\n", $2}')"

#KERNEL UPDATE
clear
a=0
k=0
while [ $a -lt 1 ]
do
        read -p "Do you wish to install XANMOD KERNEL? " yn
        case $yn in
            [Yy]* ) a=1;install_kernel;k=1;clear;;
            [Nn]* ) a=1;echo "OK";k=0;clear;;
            * ) echo "Please answer yes or no.";;
        esac
    done

if [ $k == 1 ]; then
wget -qO - https://dl.xanmod.org/archive.key | sudo gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list
sudo nala update
SCRIPT_PATH="${dir}/check_xanmod.sh"
# or
kernel=$("$SCRIPT_PATH")
get_kernel="sudo nala install $kernel -y"
eval $get_kernel
fi

######## ZSH+OHMYZSH+STARSHIP #############################################
clear
echo "ZSH+OHMYZSH+STARSHIP"
sleep 3

cd ${dir}
a=0
f=0
install_ZSH
install_ZSH_ROOT

############## DUAL BOOT ####################
clear
echo "DUAL BOOT"
sleep 3

a=0
r=0
while [ $a -lt 1 ]
do
        read -p "Do you wish to install DUAL BOOT SYSTEM? " yn
        case $yn in
            [Yy]* ) a=1;r=1;clear;;
            [Nn]* ) a=1;echo "OK";k=0;clear;;
            * ) echo "Please answer yes or no.";;
        esac
    done

     if [ $r == 1 ]; then
     ##rEFInd PPA
     sudo add-apt-repository sudo add-apt-repository ppa:rodsmith/refind -y
     ##Fix deprecated Key MINT issue
     sudo mv /etc/apt/trusted.gpg /etc/apt/refind.gpg
     sudo ln -s /etc/apt/refind.gpg /etc/apt/trusted.gpg.d/refind.gpg

     sudo nala install refind -y
    fi
done


############## GRUB-BTRFS ####################
clear
echo "GRUB-BTRFS"
sleep 3

SCRIPT_PATH="${dir}/check_filesystem.sh"
# or
file_sys=$("$SCRIPT_PATH")
get_fs="$file_sys"
eval "$get_fs"
#collect result in $r
fs=$(eval "$?")

     if [ $fs == "btrfs" ]; then
        sudo git clone https://github.com/Antynea/grub-btrfs.git /git/grub-btrfs/
        cd /git/grub-btrfs/
        sudo make install
    fi

############## EXTENSIONS ####################

firefox dotfiles/extensions.html
