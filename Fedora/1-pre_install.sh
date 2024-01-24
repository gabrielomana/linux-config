#!/bin/bash
function configure-dnf {
    clear
    sudo echo -e "[main]\ngpgcheck=1\ninstallonly_limit=3\nclean_requirements_on_remove=True\nbest=False\nskip_if_unavailable=True\n#Speed\nfastestmirror=True\nmax_parallel_downloads=10\ndefaultyes=True\nkeepcache=True\ndeltarpm=True" | sudo tee /etc/dnf/dnf.conf
    sudo dnf clean all
    sleep 3
    sudo dnf update -y
    sudo dnf upgrade -y
}

function change-hostname {
    clear
    cp ~/.bashrc ~/.bashrc_original
    read -p "Introduce el nuevo nombre para el sistema: " new_hostname
    sudo hostnamectl set-hostname "$new_hostname"
    echo "El nombre del sistema se ha cambiado a: $new_hostname"
    sudo systemctl restart systemd-hostnamed
}

function configure-repositories {
    sudo dnf clean all
    sudo dnf makecache --refresh
    sudo dnf -y install fedora-workstation-repositories
    sudo dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf -y groupupdate core
    sudo dnf clean all
    sudo dnf makecache --refresh
    sudo dnf update -y
    sudo dnf upgrade -y
}

function install-essential-packages {
    sudo dnf install @development-tools git -y
    sudo dnf -y install util-linux-user dnf-plugins-core openssl finger dos2unix nano sed sudo numlockx wget curl git nodejs cargo
}

function configure-flatpak-repositories {
    clear
    echo "Configurando repositorios de Flatpak..."
    sleep 3
    sudo dnf -y install flatpak
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak remote-add --if-not-exists elementary https://flatpak.elementary.io/repo.flatpakrepo
    flatpak remote-add --if-not-exists kde https://distribute.kde.org/kdeapps.flatpakrepo
    flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org

    flatpak remote-modify --system --prio=1 kde
    flatpak remote-modify --system --prio=2 flathub
    flatpak remote-modify --system --prio=3 elementary
    flatpak remote-modify --system --prio=4 fedora

    sudo dnf update -y
}

function configure-zswap {
    # Actualiza los módulos del kernel
    sudo dnf update -y

    # Activa el soporte para lz4hc
    sudo modprobe lz4hc lz4hc_compress

    # Crea el archivo de configuración de dracut
    sudo touch /etc/dracut.conf.d/lz4hc.conf

    # Agrega lz4hc a la lista de módulos en el archivo de configuración de dracut
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
    sudo cp "${dir}/dotfiles/grub" /etc/default/grub

    # Genera la configuración de grub
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg
}

function set-btrfs {
    # Verificar si la partición root está en Btrfs
    if [[ $(df -T / | awk 'NR==2 {print $2}') == "btrfs" ]]; then
        # Obtener el UUID de la partición raíz
        ROOT_UUID=$(grep -E '/\s+btrfs\s+' "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p')

        # Obtener el UUID de la partición home
        HOME_UUID=$(grep -E '/home\s+btrfs\s+' "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p')

        # Modificar el archivo /etc/fstab para la partición raíz
        sudo sed -i -E "s|UUID=.*\s+/\s+btrfs.*|UUID=${ROOT_UUID} /               btrfs   rw,noatime,space_cache=v2,compress=lzo,subvol=@ 0       1|" "/etc/fstab"

        # Modificar el archivo /etc/fstab para la partición home
        sudo sed -i -E "s|UUID=.*\s+/home\s+btrfs.*|UUID=${HOME_UUID} /home           btrfs   rw,noatime,space_cache=v2,compress=lzo,subvol=@home 0       2|" "/etc/fstab"

        # Limpiar la pantalla
        clear
        cat /etc/fstab
        sudo cp /etc/fstab /etc/fstab_old

        # Desfragmentar el sistema de archivos Btrfs
        sudo btrfs filesystem defragment / -r -clzo

        # Montar el dispositivo Btrfs
        root_partition=$(df -h / | awk 'NR==2 {print $1}')
        echo "La raíz está montada en la partición: $root_partition"

        # Creamos el directorio /mnt si no existe
        sudo mkdir -p /mnt

        # Montamos la partición raíz en /mnt
        sudo mount $root_partition /mnt

        # Crear subvolúmenes adicionales
        sudo btrfs subvolume create /mnt/@log
        sudo btrfs subvolume create /mnt/@cache
        sudo btrfs subvolume create /mnt/@tmp

        # Mover los contenidos existentes de /var/cache y /var/log a los nuevos subvolúmenes
        sudo mv /var/cache/* /mnt/@cache/
        sudo mv /var/log/* /mnt/@log/

        # Balanceo para duplicar metadatos y sistema
        sudo btrfs balance start -m /mnt

        # Balanceo para configurar datos y reserva global como no duplicados
        sudo btrfs balance start -d -s /mnt

        # Verificar si el archivo fstab existe
        fstab="/etc/fstab"
        if [ -e "$fstab" ]; then
            # Ajustar compresión en /etc/fstab con los nuevos subvolúmenes
            {
                echo "# Adding New Subvolumes"
                echo "UUID=$ROOT_UUID /var/log btrfs rw,noatime,space_cache=v2,compress=lzo,subvol=@log 0 2"
                echo "UUID=$ROOT_UUID /var/cache btrfs rw,noatime,space_cache=v2,compress=lzo,subvol=@cache 0 2"
                echo "UUID=$ROOT_UUID /var/tmp btrfs rw,noatime,space_cache=v2,compress=lzo,subvol=@tmp 0 2"
            } | sudo tee -a "$fstab" > /dev/null
        else
            echo "El archivo $fstab no existe. Verifica la ruta del archivo."
        fi

        # Desmontar el dispositivo Btrfs
        sudo umount /mnt

        # Establecer permisos para /var/tmp, /var/cache y /var/log
        sudo chmod 1777 /var/tmp/
        sudo chmod 1777 /var/cache/
        sudo chmod 1777 /var/log/

        # Instalar Timeshift
        sudo dnf install timeshift -y

        # Instalar el repositorio de grub-btrfs
        sudo dnf copr enable kylegospo/grub-btrfs
        sudo dnf update -y
        sudo dnf install grub-btrfs
        sudo dnf install grub-btrfs-timeshift

        # Instalar inotify-tools
        sudo dnf install inotify-tools -y

        # Modificar el archivo del servicio para agregar --timeshift-auto
        SERVICE_FILE="/lib/systemd/system/grub-btrfsd.service"
        sudo sed -i 's|^ExecStart=/usr/bin/grub-btrfsd --syslog /.snapshots|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' "$SERVICE_FILE"

        # Recargar la configuración de systemd
        sudo systemctl daemon-reload

        # Cambia el nombre del archivo timeshift-gtk en /usr/bin/
        sudo mv /usr/bin/timeshift-gtk /usr/bin/timeshift-gtk-back

        # Crea un nuevo archivo timeshift-gtk con el contenido dado
        echo -e '#!/bin/bash\n/bin/pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY /usr/bin/timeshift-gtk-back' | sudo tee /usr/bin/timeshift-gtk > /dev/null

        # Otorga permisos de ejecución al nuevo archivo
        sudo chmod +x /usr/bin/timeshift-gtk

        sudo timeshift --create --comments "initial"

        sudo systemctl stop timeshift && sudo systemctl disable timeshift
        sudo chmod +s /usr/bin/grub-btrfsd

        # Reiniciar el servicio
        sudo systemctl restart grub-btrfs.path
        sudo systemctl start grub-btrfs.path
        sudo systemctl enable --now grub-btrfs.path

        # Actualizar grub
        sudo grub2-mkconfig -o /boot/grub2/grub.cfg

    else
        echo "La partición root no está montada en un volumen BTRFS."
    fi
}


configure-dnf
change-hostname
configure-repositories
configure-flatpak-repositories
install-essential-packages
configure-zswap
set-btrfs

