#!/bin/bash
dir="$(pwd)"
extra_apps="${dir}/sources/lists/extra_apps.list"

# Incluir funciones
. "${dir}/sources/functions/zsh_starship"
. "${dir}/sources/functions/functions"


 sudo chmod 1777 /var/tmp/
 sudo chmod 1777 /var/cache/
 sudo chmod 1777 /var/log/

########## KONSOLE #############################################
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
# Limpiar y actualizar el sistema
sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
sleep 3
sudo mintsources
sudo apt update -y
sudo nala update
clear

#ZSWAP+SWAPPINESS+GRUB
sudo sysctl vm.swappiness=25

sudo cp /etc/default/grub /etc/default/grub_old
sudo cp "${dir}/dotfiles/grub" /etc/default/grub
sudo update-grub
sudo su -c "echo 'z3fold' >> /etc/initramfs-tools/modules"
sudo update-initramfs -u

# Actualizar el kernel usando Xanmod
wget -qO - https://dl.xanmod.org/archive.key | gpg --yes --dearmor | sudo tee /usr/share/keyrings/xanmod-archive-keyring.gpg > /dev/null
echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | sudo tee /etc/apt/sources.list.d/xanmod-release.list > /dev/null
sudo apt update
sudo sh -c 'echo "APT::Periodic::Update-Package-Lists \"1\";\nAPT::Periodic::Download-Upgradeable-Packages \"0\";\nAPT::Periodic::AutocleanInterval \"0\";\nAPT::Periodic::Unattended-Upgrade \"1\";" > /etc/apt/apt.conf.d/10periodic'
sudo sh -c 'echo "Unattended-Upgrade::Allowed-Origins {\n\t\"${distro_id}:${distro_codename}-security\";\n\t\"${distro_id}:${distro_codename}-updates\";\n\t\"${distro_id}ESM:${distro_codename}\";\n};" > /etc/apt/apt.conf.d/50unattended-upgrades'

awk_script='
    BEGIN {
        while (!/flags/) if (getline < "/proc/cpuinfo" != 1) exit 1
        if (/lm/&&/cmov/&&/cx8/&&/fpu/&&/fxsr/&&/mmx/&&/syscall/&&/sse2/) level = 1
        if (level == 1 && /cx16/&&/lahf/&&/popcnt/&&/sse4_1/&&/sse4_2/&&/ssse3/) level = 2
        if (level == 2 && /avx/&&/avx2/&&/bmi1/&&/bmi2/&&/f16c/&&/fma/&&/abm/&&/movbe/&&/xsave/) level = 3
        if (level == 3 && /avx512f/&&/avx512bw/&&/avx512cd/&&/avx512dq/&&/avx512vl/) level = 4
        if (level > 0) { print "v" level; exit level + 1 }
        exit 1
    }
'

# Ejecuta el script AWK y guarda la salida en una variable
ver=$(awk "$awk_script")

# Instala el kernel XanMod utilizando la variable ver
sudo apt install linux-xanmod-lts-x64$ver -y
sudo update-initramfs -u

######## ZSH+OHMYZSH+STARSHIP #############################################
cd "${dir}"
install_ZSH

############## DUAL BOOT ####################
# Descomenta la siguiente línea si deseas instalar refind
# sudo nala install refind -y


############## EXTENSIONS ####################

firefox dotfiles/extensions.html
