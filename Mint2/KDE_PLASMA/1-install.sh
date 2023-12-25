#!/bin/bash
cp ~/.bashrc ~/.bashrc_original

if command -v nala &> /dev/null; then
    sudo nala fetch --auto --fetches 5 -y
else
    if sudo apt install nala -y ; then
        sudo nala fetch --auto --fetches 5 -y
    fi
fi
sudo nala update

dir="$(pwd)"

codecs="${dir}/sources/lists/codecs.list"
extra_apps="${dir}/sources/lists/exta_apps.list"
kde_plasma="${dir}/sources/lists/kde_plasma.list"
kde_plasma_apps="${dir}/sources/lists/kde_plasma_apps.list"
multimedia="${dir}/sources/lists/multimedia.list"
tools="${dir}/sources/lists/tools.list"
utilities="${dir}/sources/lists/utilities.list"
xfce="${dir}/sources/lists/xfce.list"
kde_bloatware="${dir}/sources/lists/kde_bloatware.list"

. "${dir}"/sources/functions/functions


####################### UNINSTALL XFCE ###############################
clear
echo "UNINSTALL XFCE"
sleep 3
uninstall_xfce
########################## REPOSITORIES ###############################
clear
echo "ADD REPOSITORIES"
sleep 3
add_repos
######################### KDE PLASMA ###############################
clear
echo "INSTALL KDE PLASMA: "
sleep 3
install_kde
######################### CORE APPS ###############################
clear
echo "INSTALL SYSTEM CORE APPS: "
sleep 3
install_core_apps

######################### MULTIMEDIA ###############################
clear
echo "INSTALL MULTIMEDIA APPS: "
sleep 3
install_multimedia


#########################################_END_ #################################################
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

    # Crear subvolúmenes adicionales
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

    # Desmontar la partición /mnt
    sudo umount /mnt
    echo "La partición /mnt ha sido desmontada."

    # Instalar Timeshift
    sudo apt install timeshift -y

    # Instalar herramientas de compilación y git
    sudo apt install build-essential git -y

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


########## FULL UPDATE ##########################################
clear
echo "FULL UPDATE"
sudo nala clean
sleep 3
sudo nala update; sudo nala upgrade -y; sudo nala install -f; sudo apt --fix-broken install
sudo aptitude safe-upgrade -y
sudo apt full-upgrade -y
sudo systemctl disable casper-md5check.service
sudo reboot
