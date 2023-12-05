#!/bin/bash
dir="$(pwd)"
exta_apps="${dir}/sources/lists/exta_apps.list"

# Incluir funciones
. "${dir}/sources/functions/zsh_starship"
. "${dir}/sources/functions/functions"

########## KONSOLE #############################################
neofetch
clear
echo "KONSOLE & DOTFILES"
sleep 3

# Descargar y configurar esquemas de colores para Konsole
sudo wget -q https://github.com/gabrielomana/color_schemes/raw/main/konsole.zip -P /tmp
sudo unzip -q /tmp/konsole.zip -d /tmp
sudo cp -r /tmp/konsole/* /usr/share/konsole/
sudo rm -rf /tmp/konsole/

# Configurar perfil de Konsole
cp -r dotfiles/konsole.profile ~/.local/share/konsole/konsole.profile

# Configurar neofetch y topgrade
cp -r dotfiles/neofetch.conf ~/.config/neofetch/config.conf
cp -r dotfiles/topgrade.toml ~/.config/topgrade.toml

########## EXTRA APPS #############################################
clear
cd "${dir}"
install_extra_apps

########## CLEAN & FINAL STEPS #############################################
clear
echo "CLEAN & FINAL STEPS"
sleep 3

# Limpiar y actualizar el sistema
sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
sudo mintsources
sudo apt update -y
sudo nala update

# Configurar swappiness, GRUB y actualizar el kernel
sudo sysctl vm.swappiness=25
sudo cp /etc/default/grub /etc/default/grub_old
sudo cp "${dir}/dotfiles/grub" /etc/default/grub
sudo update-grub
sudo su -c "echo 'z3fold' >> /etc/initramfs-tools/modules"
sudo update-initramfs -u

# Actualizar el kernel usando mainline-gtk
sudo mainline-gtk

######## ZSH+OHMYZSH+STARSHIP #############################################
cd "${dir}"
install_ZSH

############## DUAL BOOT ####################
# Descomenta la siguiente línea si deseas instalar refind
# sudo nala install refind -y
