#!/bin/bash
function grub-btrfs-snap{
     # Verificar si la partición root está en Btrfs
        if [[ $(df -T / | awk 'NR==2 {print $2}') == "btrfs" ]]; then
            # Obtener el UUID de la partición raíz
            ROOT_UUID=$(grep -E '/\s+btrfs\s+' "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p')

            # Obtener el UUID de la partición home
            HOME_UUID=$(grep -E '/home\s+btrfs\s+' "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p')

            # Modificar el archivo /etc/fstab para la partición raíz
            sudo sed -i -E "s|UUID=.*\s+/\s+btrfs.*|UUID=${ROOT_UUID} /               btrfs   defaults,noatime,space_cache=v2,compress=lzo,subvol=@ 0       1|" "/etc/fstab"

            # Modificar el archivo /etc/fstab para la partición home
            sudo sed -i -E "s|UUID=.*\s+/home\s+btrfs.*|UUID=${HOME_UUID} /home           btrfs   defaults,noatime,space_cache=v2,compress=lzo,subvol=@home 0       2|" "/etc/fstab"

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
                    echo "UUID=$ROOT_UUID /var/log btrfs defaults,noatime,space_cache=v2,compress=lzo,subvol=@log 0 2"
                    echo "UUID=$ROOT_UUID /var/cache btrfs defaults,noatime,space_cache=v2,compress=lzo,subvol=@cache 0 2"
                    echo "UUID=$ROOT_UUID /var/tmp btrfs defaults,noatime,space_cache=v2,compress=lzo,subvol=@tmp 0 2"
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
            sudo apt install timeshift build-essential git -y

            # Clonar el repositorio de grub-btrfs y compilar e instalar
            sudo git clone https://github.com/Antynea/grub-btrfs.git /git/grub-btrfs/
            (
                cd /git/grub-btrfs || exit
                sudo make install
            )

            # Instalar inotify-tools
            sudo apt install inotify-tools -y

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
            sudo systemctl restart grub-btrfsd
            sudo systemctl start grub-btrfsd
            sudo systemctl enable grub-btrfsd

            # Actualizar grub
            sudo update-grub

        else
            echo "La partición root no está montada en un volumen BTRFS."
        fi
}

function pipewire{
    # Obtener el codename de la última versión LTS de Ubuntu
        ubuntu_lts=$(curl -s https://changelogs.ubuntu.com/meta-release-lts | grep Dist: | tail -n1 | awk -F '[: ]+' '{print $NF}' | tr '[:upper:]' '[:lower:]')

        # Crear el archivo pipewire-upstream.list
        echo "deb http://ppa.launchpad.net/pipewire-debian/pipewire-upstream/ubuntu $ubuntu_lts main" | sudo tee /etc/apt/sources.list.d/pipewire-upstream.list > /dev/null

        # Crear el archivo wireplumber-upstream.list
        echo "deb http://ppa.launchpad.net/pipewire-debian/wireplumber-upstream/ubuntu $ubuntu_lts main" | sudo tee /etc/apt/sources.list.d/wireplumber-upstream.list > /dev/null

        # Instalar la llave
        sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 25088A0359807596

        # Actualizar el sistema
        sudo nala update
        sudo nala upgrade -y
        sudo nala full-upgrade -y

        # Instalar paquetes necesarios
        sudo nala install -y \
        libfdk-aac2 \
        libldacbt-{abr,enc}2 \
        libopenaptx0 \
        gstreamer1.0-pipewire \
        libpipewire-0.3-{0,dev,modules} \
        libspa-0.2-{bluetooth,dev,jack,modules} \
        pipewire{,-{audio-client-libraries,pulse,bin,locales,tests}} \
        pipewire-doc \
        libpipewire-module-x11-bell \
        wireplumber{,-doc} \
        gir1.2-wp-0.4 \
        libwireplumber-0.4-{0,dev} \
        wireplumber-locales

        # Desactivar PulseAudio
        systemctl --user --now disable pulseaudio.{socket,service}
        systemctl --user mask pulseaudio

        # Activar Pipewire
        sudo apt reinstall pipewire pipewire-bin pipewire-pulse -y
        systemctl --user --now enable pipewire pipewire-pulse
        systemctl --user --now enable pipewire{,-pulse}.{socket,service}
        systemctl --user --now enable wireplumber.service
}

function clean{
    sudo nala install -y bleachbit
        sudo bleachbit -c apt.autoclean apt.autoremove apt.clean system.tmp system.trash system.cache system.localizations system.desktop_entry
        sudo nala update
        sudo apt --fix-broken install
        sudo aptitude safe-upgrade -y
}

# Llama a las funciones
#grub_btrfs_snap
pipewire
#clean