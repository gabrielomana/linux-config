#!/bin/bash
# Verificación de permisos de root
if [ "$UID" -ne 0 ]; then
  echo 'Debe ejecutar este script como root.'
  exit 1
fi

echo "+-----------------------------------------------------+"
echo "| Refresh                                              |"
echo "+-----------------------------------------------------+"
    sudo zypper -n refresh
    sudo zypper -n up
    sudo zypper -n install cmake automake zlibrary gcc-c++ VirtualGL patterns-devel-base-devel_basis
    sleep 5
    clear

echo "+-----------------------------------------------------+"
echo "| Respositories                                         |"
echo "+-----------------------------------------------------+"

    # Packman
    sudo zypper ar -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ Packman
    sudo zypper ar -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/ Packman-Essentials
    sudo zypper ar -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Multimedia/ Packman-Multimedia
    sudo zypper ar -cfp 90 https://download.opensuse.org/repositories/games/openSUSE_Tumbleweed Packman-Games
    sudo zypper ar -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Extra/ Packman-Extra
    sudo zypper ar -cfp 90 https://opensuse-guide.org/repo/openSUSE_Tumbleweed/ libdvdcss

    # Mozilla
    sudo zypper ar -cfp 90 https://download.opensuse.org/repositories/mozilla/openSUSE_Tumbleweed Mozilla
    # Google
    wget https://dl.google.com/linux/linux_signing_key.pub
    sudo rpm --import linux_signing_key.pub
    sudo rm linux_signing_key.pub
    sudo zypper ar -cfp 90 https://dl.google.com/linux/rpm/stable/x86_64 Google

    # Extra
    sudo zypper ar -cfp 90 http://download.opensuse.org/repositories/M17N:/fonts/openSUSE_Tumbleweed/ M17N-fonts
    sudo zypper ar -cfp 90 https://download.opensuse.org/repositories/games/openSUSE_Tumbleweed/ Games
    sudo zypper ar -cfp 90 http://codecs.opensuse.org/openh264/openSUSE_Tumbleweed openh264
    sudo zypper ar -cfp 90 https://download.nvidia.com/opensuse/tumbleweed/ Nvidia

    # Importación automática de claves GPG y actualización de repositorios
    sudo zypper --gpg-auto-import-keys ref

    # Actualización del sistema
    sudo zypper -n refresh
    sudo zypper -n up
    sudo zypper -n dist-upgrade
    sudo zypper -n dist-upgrade --from packman


echo "+-----------------------------------------------------+"
echo "| FlatPack                                            |"
echo "+-----------------------------------------------------+"
    # Activar Flatpak
    flatpak --version 2>&1 >/dev/null
    if [ $? -ne 0 ]; then
        echo "Instalando Flatpak..."
        sudo zypper -n install flatpak
    fi

    # Añadir repositorios Flatpak
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    sudo flatpak remote-add --if-not-exists elementary https://flatpak.elementary.io/repo.flatpakrepo
    sudo flatpak remote-add --if-not-exists kde https://distribute.kde.org/kdeapps.flatpakrepo
    sudo flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org

    # Modificar prioridades
    sudo flatpak remote-modify --system --prio=1 kde
    sudo flatpak remote-modify --system --prio=2 flathub
    sudo flatpak remote-modify --system --prio=3 elementary
    sudo flatpak remote-modify --system --prio=4 fedora


echo "+-----------------------------------------------------+"
echo "| Codecs & Basic Packages                             |"
echo "+-----------------------------------------------------+"
    sudo zypper -n install ffmpeg lame gstreamer-*
    sudo zypper -n install opi
    sudo opi codecs


echo "+-----------------------------------------------------+"
echo "| Fonts                                               |"
echo "+-----------------------------------------------------+"

# Directorio temporal para descargar las fuentes
temp_dir="/tmp/nerd_fonts"
# Crear directorio temporal si no existe
mkdir -p "$temp_dir"

# Obtener las URL de descarga para las últimas versiones
font_names=("JetBrainsMono" "Ubuntu" "Mononoki" "Hack")
for font_name in "${font_names[@]}"; do
    latest_release_url="https://github.com/ryanoasis/nerd-fonts/releases/latest"
    font_download_url=$(curl -sL -I -o /dev/null -w '%{url_effective}' "$latest_release_url" | sed "s/tag/download/")"/$font_name.zip"
    # Descargar la fuente
    wget -O "$temp_dir/$font_name.zip" "$font_download_url"
    # Descomprimir la fuente
    unzip "$temp_dir/$font_name.zip" -d "$temp_dir/$font_name"
done

# Directorio de instalación para las fuentes en el sistema
install_dir="/usr/share/fonts/nerd_fonts"
# Crear directorio de instalación si no existe
sudo mkdir -p "$install_dir"

# Mover las fuentes al directorio de instalación
for font_name in "${font_names[@]}"; do
    sudo mv "$temp_dir/$font_name"/*.{ttf,otf} "$install_dir"
done

# Limpieza: Eliminar directorio temporal
rm -rf "$temp_dir"

# Instalar fuentes adicionales y configuración
sudo zypper -n install google-noto-fonts fetchmsttfonts

# Copiar configuración de fuentes
sudo cp ../dotfiles/fonts.conf /etc/fonts/fonts.conf -rf

# Actualizar la caché de fuentes
sudo fc-cache -f -v

# echo "+-----------------------------------------------------+"
# echo "| Configuración de Zswap completada en openSUSE       |"
# echo "+-----------------------------------------------------+"
#     # Directorio temporal para realizar copias de seguridad
#     backup_dir="/tmp/zswap_backup"
#     mkdir -p "$backup_dir"

#     # Copia de seguridad del archivo sysctl.conf
#     sudo cp /etc/sysctl.conf "$backup_dir/sysctl.conf_backup"

#     # Añadir configuración de Zswap a sysctl.conf
#     echo "vm.swappiness=25" | sudo tee -a /etc/sysctl.conf
#     echo "vm.vfs_cache_pressure=50" | sudo tee -a /etc/sysctl.conf
#     echo "vm.zswap.enabled=1" | sudo tee -a /etc/sysctl.conf
#     echo "vm.zswap.zpool=z3fold" | sudo tee -a /etc/sysctl.conf
#     echo "vm.zswap.compressor=lz4" | sudo tee -a /etc/sysctl.conf

#     # Actualizar la configuración del kernel
#     sudo sysctl -p

#     # Actualizar GRUB
#     sudo cp /etc/default/grub /etc/default/grub_backup
#     echo 'GRUB_CMDLINE_LINUX_DEFAULT="quiet zswap.enabled=1 zswap.zpool=z3fold zswap.compressor=lz4"' | sudo tee -a /etc/default/grub
#     sudo grub2-mkconfig -o /boot/grub2/grub.cfg


# Cambio de nombre del host
echo "+------------------------------------------------------------------+"
echo "| Cambio de nombre del host                                     |"
echo "+------------------------------------------------------------------+"
    nuevo_nombre="nuevo_nombre_del_host"
    sudo hostnamectl set-hostname $nuevo_nombre
    echo "Hostname cambiado a $nuevo_nombre"


echo "+-----------------------------------------------------+"
echo "| Configuración predeterminada de YAST para archivos RPM |"
echo "+-----------------------------------------------------+"
    echo "/usr/sbin/yast2" | sudo tee /usr/bin/rpm > /dev/null
    sudo chmod +x /usr/bin/rpm


