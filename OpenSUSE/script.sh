#!/bin/bash

echo "+-----------------------------------------------------+"
echo "| openSUSE Tumbleweed Apps Installation Script        |"
echo "+-----------------------------------------------------+"

# Verificación de permisos de root
if [ "$UID" -ne 0 ]; then
  echo 'Debe ejecutar este script como root.'
  exit 1
fi

# Repositorios Oficiales de Tumbleweed
oss_repo="http://download.opensuse.org/tumbleweed/repo/oss/"
non_oss_repo="http://download.opensuse.org/tumbleweed/repo/non-oss/"
update_repo="http://download.opensuse.org/update/tumbleweed/"
src_oss_repo="http://download.opensuse.org/tumbleweed/repo/src-oss"
src_non_oss_repo="http://download.opensuse.org/tumbleweed/repo/src-non-oss"
debug_oss_repo="http://download.opensuse.org/debug/tumbleweed/repo/oss/"
backports_repo="http://download.opensuse.org/update/tumbleweed/backports/"
backports_debug_repo="http://download.opensuse.org/update/tumbleweed/backports_debug/"

# Repositorios Packman adicionales
packman_complete_repo="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/"
packman_essentials_repo="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/"
packman_multimedia_repo="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Multimedia/"
packman_games_repo="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Games/"
packman_extra_repo="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Extra/"
libdvdcss_repo="https://opensuse-guide.org/repo/openSUSE_Tumbleweed/"
nvidia_repo="https://download.nvidia.com/opensuse/tumbleweed/"
google_repo="https://www.google.com/linuxrepositories/"

# Repositorios adicionales de fuentes y juegos
m17n_fonts_repo="http://download.opensuse.org/repositories/M17N:/fonts/openSUSE_Tumbleweed/"
games_repo="http://download.opensuse.org/repositories/games/openSUSE_Tumbleweed/"

# Configuración de repositorios
zypper ar -cfp 99 $oss_repo oss
zypper ar -cfp 99 $non_oss_repo non-oss
zypper ar -cfp 99 $update_repo update
zypper ar -cfp 99 $src_oss_repo src-oss
zypper ar -cfp 99 $src_non_oss_repo src-non-oss
zypper ar -cfp 99 $debug_oss_repo debug-oss
zypper ar -cfp 95 $backports_repo backports
zypper ar -cfp 95 $backports_debug_repo backports-debug

# Repositorios Packman
zypper ar -cfp 90 $packman_complete_repo packman-complete
zypper ar -cfp 90 $packman_essentials_repo packman-essentials
zypper ar -cfp 90 $packman_multimedia_repo packman-multimedia
zypper ar -cfp 90 $packman_games_repo packman-games
zypper ar -cfp 90 $packman_extra_repo packman-extra
zypper ar -cfp 90 $libdvdcss_repo libdvdcss
zypper ar -cfp 90 $nvidia_repo nvidia
zypper ar -cfp 90 $google_repo google

# Repositorios adicionales
zypper ar -cfp 90 $m17n_fonts_repo m17n-cfp 90onts
zypper ar -cfp 90 $games_repo games

# Importación automática de claves GPG y actualización de repositorios
sudo zypper --gpg-auto-import-keys ref

# Actualización del sistema
sudo zypper -n refresh
sudo zypper -n up
sudo zypper -n dist-upgrade
sudo zypper -n dist-upgrade --from packman


echo "+-----------------------------------------------------+"
echo "| FlatPack  |"
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
echo "| Descarga e instalación de Codecs KDE para openSUSE  |"
echo "+-----------------------------------------------------+"


# URL del archivo YMP
ymp_url="https://www.opensuse-community.org/codecs-kde.ymp"

# Directorio temporal para descargar el archivo
temp_dir=$(mktemp -d)

# Descargar el archivo YMP
wget "$ymp_url" -P "$temp_dir"

# Verificar si la descarga fue exitosa
if [ $? -eq 0 ]; then
  echo "Descarga exitosa. Iniciando la instalación."

  # Ejecutar YAST con el archivo YMP
  sudo yast2 sw_single "$temp_dir/codecs-kde.ymp"

  # Limpiar el directorio temporal
  rm -r "$temp_dir"
else
  echo "Error al descargar el archivo. Verifica la URL e inténtalo nuevamente."
fi
sudo zypper -n install ffmpeg lame gstreamer-plugins-bad gstreamer-plugins-ugly gstreamer-plugins-ugly-orig-addon gstreamer-plugins-libav libdvdcss2 --auto-agree-with-licenses
sudo zypper -n install opi
sudo opi codecs

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

# Instalación de otras herramientas y apps
sudo zypper -n install cmake automake fetchmsttfonts zlibrary gcc-c++ VirtualGL VirtualGL-32bit
