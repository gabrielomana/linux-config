#!/bin/bash
# Verificación de permisos de root
if [ "$UID" -ne 0 ]; then
  echo 'Debe ejecutar este script como root.'
  exit 1
fi

# Función para actualizar el sistema
function actualizar-sistema() {
  clear
  echo "+-----------------------------------------------------+"
  echo "| Refresh y Actualización del Sistema                 |"
  echo "+-----------------------------------------------------+"
  ZYPPER='zypper --no-cd'
  $ZYPPER refresh
  $ZYPPER update
  $ZYPPER patch
  sudo $ZYPPER -n install cmake automake zlibrary* gcc-c++ VirtualGL patterns-devel-base-devel_basis lz4
  sleep 5
  clear
}

function configurar-repositorios() {
  echo "+-----------------------------------------------------+"
  echo "| Repositorios                                         |"
  echo "+-----------------------------------------------------+"
    # Packman
    sudo zypper ar -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/ Packman
    #sudo zypper ar -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/ Packman-Essentials
    #sudo zypper ar -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Multimedia/ Packman-Multimedia
    #sudo zypper ar -cfp 90 https://download.opensuse.org/repositories/games/openSUSE_Tumbleweed Packman-Games
    #sudo zypper ar -cfp 90 https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Extra/ Packman-Extra
    sudo zypper ar -cfp 90 https://opensuse-guide.org/repo/openSUSE_Tumbleweed/ libdvdcss

    # Mozilla
    #sudo zypper ar -cfp 90 https://download.opensuse.org/repositories/mozilla/openSUSE_Tumbleweed Mozilla
    # Google
    wget https://dl.google.com/linux/linux_signing_key.pub
    sudo rpm --import linux_signing_key.pub
    sudo rm linux_signing_key.pub
    sudo zypper ar -cfp 90 https://dl.google.com/linux/rpm/stable/x86_64 Google

    # Extra
    #sudo zypper ar -cfp 90 http://download.opensuse.org/repositories/M17N:/fonts/openSUSE_Tumbleweed/ M17N-fonts
    #sudo zypper ar -cfp 90 https://download.opensuse.org/repositories/games/openSUSE_Tumbleweed/ Games
    #sudo zypper ar -cfp 90 http://codecs.opensuse.org/openh264/openSUSE_Tumbleweed openh264
    #sudo zypper ar -cfp 90 https://download.nvidia.com/opensuse/tumbleweed/ Nvidia

    # Importación automática de claves GPG y actualización de repositorios
   

    # Actualización del sistema
    sudo zypper -n --gpg-auto-import-keys ref
    sudo zypper -n up
}

# Función para configurar Flatpak
function configurar-flatpak() {
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

}

# Función para instalar codecs y paquetes básicos
function instalar-codecs-y-paquetes() {
  echo "+-----------------------------------------------------+"
  echo "| Codecs & Basic Packages                             |"
  echo "+-----------------------------------------------------+"
    sudo zypper -n install opi
    sudo opi codecs
    sudo zypper -n install ffmpeg lame gstreamer-*
}

# Función para instalar fuentes
function instalar-fuentes() {
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
}

# Función para cambiar el nombre del host
function cambiar-nombre-host() {
  echo "+------------------------------------------------------------------+"
  echo "| Cambio de nombre del host                                     |"
  echo "+------------------------------------------------------------------+"
  nuevo_nombre="nuevo_nombre_del_host"
  sudo hostnamectl set-hostname $nuevo_nombre
  echo "Hostname cambiado a $nuevo_nombre"
}


# Función para configurar YAST para archivos RPM
function configurar-yast-rpm() {
  echo "+-----------------------------------------------------+"
  echo "| Configuración predeterminada de YAST para archivos RPM |"
  echo "+-----------------------------------------------------+"
  echo "/usr/sbin/yast2" | sudo tee /usr/bin/rpm > /dev/null
  sudo chmod +x /usr/bin/rpm
}


# Función para configurar microcode y VAAPI
function configurar-microcode-vaapi() {
  echo "+-----------------------------------------------------+"
  echo "| Microcode  & VAAPI                                  |"
  echo "+-----------------------------------------------------+"
    # Obtiene el nombre del fabricante de la GPU.
    gpu_vendor=$(lspci | grep -i "3D controller" | awk '{print $3}')

    # Instala los controladores de la GPU.
    case "$gpu_vendor" in
    Intel*)
        echo "Instalando controladores para la GPU Intel..."
        sudo zypper install -y intel-media-driver intel-hybrid-driver
        ;;
    AMD*)
        echo "Instalando controladores para la GPU AMD..."
        sudo zypper install -y kernel-firmware-amdgpu xf86-video-amdgpu Mesa-drivers libva-vdpau-driver
        ;;
    NVIDIA*)
        echo "Instalando controladores para la GPU NVIDIA..."
        sudo zypper ar -cfp 90 https://download.nvidia.com/opensuse/tumbleweed/ Nvidia
        sudo zypper -n --gpg-auto-import-keys ref
        zypper install-new-recommends --repo NVIDIA
        # Determinar la versión del controlador según la información del hardware
        gpu_info=$(lspci | grep -i "VGA" | grep -Ei "NVIDIA|GPU")
        if echo "$gpu_info" | grep -qi "GeForce 600\|GeForce 700"; then
        driver_version="G05"
        elif echo "$gpu_info" | grep -qi "GeForce 400\|GeForce 500"; then
        driver_version="G04"
        else
        driver_version="G06"
        fi
        # Instalar el controlador según la versión determinada
        sudo zypper in x11-video-nvidia${driver_version} nvidia-gl${driver_version} nvidia-compute${driver_version}
        ;;
    esac

    # Configuración del procesador
    # Obtiene el nombre del procesador.
    cpu_name=$(lscpu | grep -Ei "Model name|Nombre del modelo" | awk '{print $0}')

    # Instala los controladores y microcódigos apropiados.
    if echo "$cpu_name" | grep -qi "intel"; then
    echo "Instalando controladores y microcódigos para el procesador Intel..."
    sudo zypper install -y ucode-intel iucode-tool
    elif echo "$cpu_name" | grep -qi "amd"; then
    echo "Instalando controladores y microcódigos para el procesador AMD..."
    sudo zypper install -y ucode-amd
    else
    echo "No se pudo identificar el procesador."
    fi
    # Configuración de los controladores de máquinas virtuales
    # Verifica si la máquina es un host de máquinas virtuales.
    if [[ "$(cat /sys/class/dmi/id/chassis_type)" != "Machine" && "$(cat /sys/class/dmi/id/chassis_type)" != "Maquina" ]]; then
    # Obtiene el nombre del hypervisor.
    hypervisor=$(sudo dmidecode -s system-product-name)
}

# Función para configurar ZSWAP
function configurar-zswap() {
  echo "+-----------------------------------------------------+"
  echo "| ZSWAP                                               |"
  echo "+-----------------------------------------------------+"
    # Actualiza los módulos del kernel
    sudo zypper ref
    # Activa el soporte para lz4hc
    sudo modprobe lz4hc lz4hc_compress
    # Crea el archivo de configuración de dracut
    sudo touch /etc/dracut.conf.d/lz4hc.conf
    # Agrega lz4hc a la lista de módulos
    echo "add_drivers+=\"lz4hc lz4hc_compress\"" | sudo tee -a /etc/dracut.conf.d/lz4hc.conf
    # Regenera los archivos initramfs
    sudo dracut --regenerate-all --force
    # Establece el compresor de zswap a lz4hc
    echo "lz4hc" | sudo tee /sys/module/zswap/parameters/compressor
    # Establece el tamaño máximo del pool de memoria comprimida al 25% de la RAM
    echo "25" | sudo tee /sys/module/zswap/parameters/max_pool_percent
    # Activa zswap
    echo "1" | sudo tee /sys/module/zswap/parameters/enabled


   # Respaldar la configuración de grub
    sudo cp /etc/default/grub /etc/default/grub_old
    # Copiar el nuevo archivo de configuración de grub que contiene la configuración de lz4
    sudo cp "${dir}/KDE_PLASMA/dotfiles/grub" /etc/default/grub
    # Genera la configuración de grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg

}

# Invocar funciones
dir="$(pwd)"
actualizar-sistema
cambiar-nombre-host
configurar-microcode-vaapi
configurar-zswap
configurar-yast-rpm
#configurar-repositorios
configurar-flatpak
#instalar-codecs-y-paquetes
instalar-fuentes

