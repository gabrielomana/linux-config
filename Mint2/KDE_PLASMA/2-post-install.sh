#!/bin/bash
dir="$(pwd)"
extra_apps="${dir}/sources/lists/extra_apps.list"

# Incluir funciones
. "${dir}/sources/functions/zsh_starship"
. "${dir}/sources/functions/functions"

########## KONSOLE #############################################
neofetch
clear
echo "KONSOLE & DOTFILES"
sleep 3

dir="$(pwd)"
sudo git clone https://github.com/fastfetch-cli/fastfetch.git /tmp/fastfetch/
cd /tmp/fastfetch/
sudo mkdir -p build
cd build
sudo cmake ..
sudo cmake --build . --target fastfetch --target flashfetch
sudo cp fastfetch flashfetch /usr/bin/
cd ${dir}
mkdir ~/.config/fastfetch/
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


##################### GRUB-BTRFS ####################################
# Verificar si la partición root está en Btrfs
if [[ $(df -T / | awk 'NR==2 {print $2}') == "btrfs" ]]; then
    # Obtener el UUID de la partición raíz
    ROOT_UUID=$(grep -E '/\s+btrfs\s+' "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p')

    # Obtener el UUID de la partición home
    HOME_UUID=$(grep -E '/home\s+btrfs\s+' "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p')

    # Modificar el archivo /etc/fstab para la partición raíz
    #sudo sed -i -E "s|UUID=.*\s+/\s+btrfs.*|UUID=${ROOT_UUID} /               btrfs   defaults,noatime,space_cache=v2,compress=zstd:3 0       1|" "/etc/fstab"
    sudo sed -i -E "s|UUID=.*\s+/\s+btrfs.*|UUID=${ROOT_UUID} /               btrfs   defaults,noatime,space_cache=v2,compress=lzo 0       1|" "/etc/fstab"


    # Modificar el archivo /etc/fstab para la partición home
    #sudo sed -i -E "s|UUID=.*\s+/home\s+btrfs.*|UUID=${HOME_UUID} /home           btrfs   defaults,noatime,space_cache=v2,compress=zstd:3,subvol=@home 0       2|" "/etc/fstab"
    sudo sed -i -E "s|UUID=.*\s+/home\s+btrfs.*|UUID=${HOME_UUID} /home           btrfs   defaults,noatime,space_cache=v2,compress=lzo,subvol=@home 0       2|" "/etc/fstab"

    # Limpiar la pantalla
    clear
    cat /etc/fstab

    # Desfragmentar el sistema de archivos Btrfs
    #sudo btrfs filesystem defragment / -r -czstd
    sudo btrfs filesystem defragment / -r -clzo
    
    # Crear subvolúmenes adicionales
    sudo btrfs subvolume create /mnt/@log
    sudo btrfs subvolume create /mnt/@cache
    sudo btrfs subvolume create /mnt/@tmp

    # Función para manejar errores
    handle_error() {
        echo "Ocurrió un error durante la transferencia. No se realizaron eliminaciones."
    }

    # Definir directorios de origen y destino
    SOURCE_CACHE_DIR="/var/cache"
    DEST_CACHE_DIR="/mnt/@cache"
    SOURCE_LOG_DIR="/var/log"
    DEST_LOG_DIR="/mnt/@log"

    # Verificar si hay archivos en el directorio de origen
    if [ -n "$(ls -A $SOURCE_CACHE_DIR)" ]; then
        # Intentar mover el contenido de /var/cache a /@cache
        if sudo rsync -avP $SOURCE_CACHE_DIR/* $DEST_CACHE_DIR/; then
            # Si el primer rsync es exitoso, intentar el segundo rsync
            if sudo rsync -avP $SOURCE_LOG_DIR/* $DEST_LOG_DIR/; then
                # Si ambos rsync son exitosos, eliminar los datos originales
                sudo rm -rf $SOURCE_CACHE_DIR/*
                sudo rm -rf $SOURCE_LOG_DIR/*
            else
                # Si el segundo rsync falla, manejar el error
                handle_error
            fi
        else
            # Si el primer rsync falla, manejar el error
            handle_error
        fi
    else
        echo "El directorio $SOURCE_CACHE_DIR está vacío. No se realizaron operaciones."
    fi

    # Verificar si el archivo fstab existe
    fstab="/etc/fstab"
    if [ -e "$fstab" ]; then
        # Ajustar compresión en /etc/fstab con los nuevos subvolúmenes
        echo "# Adding New Subvolumes" | sudo tee -a "$fstab"
        echo "UUID=$ROOT_UUID /var/log btrfs defaults,noatime,space_cache=v2,compress=zstd:3,subvol=@log 0 2" | sudo tee -a "$fstab"
        echo "UUID=$ROOT_UUID /var/cache btrfs defaults,noatime,space_cache=v2,compress=zstd:3,subvol=@cache 0 2" | sudo tee -a "$fstab"
        echo "UUID=$ROOT_UUID /var/tmp btrfs defaults,noatime,space_cache=v2,compress=zstd:3,subvol=@tmp 0 2" | sudo tee -a "$fstab"
    else
        echo "El archivo $fstab no existe. Verifica la ruta del archivo."
    fi

    # Instalar Timeshift
    sudo apt install timeshift -y

    # Instalar herramientas de compilación y git
    sudo apt install build-essential git -y

    # Clonar el repositorio de grub-btrfs y compilar e instalar
    sudo git clone https://github.com/Antynea/grub-btrfs.git /git/grub-btrfs/
    cd /git/grub-btrfs
    sudo make install

    # Instalar inotify-tools
    sudo apt install inotify-tools -y

    # Modificar el archivo del servicio para agregar --timeshift-auto
    SERVICE_FILE="/etc/systemd/system/grub-btrfsd.service"
    sudo sed -i 's|^ExecStart=/usr/bin/grub-btrfsd --syslog /.snapshots|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' "$SERVICE_FILE"

    # Recargar la configuración de systemd
    sudo systemctl daemon-reload

    # Reiniciar el servicio
    sudo systemctl restart grub-btrfsd
    sudo systemctl start grub-btrfsd
    sudo systemctl enable grub-btrfsd

    # Actualizar grub
    sudo update-grub

else
    echo "La partición root no está montada en un volumen BTRFS."
fi

######## ZSH+OHMYZSH+STARSHIP #############################################
cd "${dir}"
install_ZSH

############## DUAL BOOT ####################
# Descomenta la siguiente línea si deseas instalar refind
# sudo nala install refind -y
