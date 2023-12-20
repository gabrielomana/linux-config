#!/bin/bash
# Verificar si la partición root está montada en un volumen BTRFS
if [[ $(df -T / | awk 'NR==2 {print $2}') == "btrfs" ]]; then
    # Ajustar compresión en /etc/fstab
    sudo sed -i 's|defaults,noatime,space_cache=v2|defaults,noatime,space_cache=v2,compress=zstd:3|g' /etc/fstab

    # Defragmentar y comprimir datos existentes
    sudo btrfs filesystem defragment / -r -czstd

    # Crear subvolúmenes adicionales
    sudo btrfs subvolume create /@log
    sudo btrfs subvolume create /@cache
    sudo btrfs subvolume create /@tmp

    # Mover contenidos a nuevos subvolúmenes
    sudo mv /@/var/cache/* /@cache/
    sudo mv /@/var/log/* /@log/
    
    # Obtener el UUID del volumen BTRFS
    UUID=$(lsblk -o UUID / | sed -n 2p)

    # Ajustar compresión en /etc/fstab con los nuevos subvolúmenes
    sudo echo "UUID=$UUID /var/log btrfs defaults,noatime,space_cache=v2,compress=zstd:3,subvol=@log 0 2" >> /etc/fstab
    sudo echo "UUID=$UUID /var/cache btrfs defaults,noatime,space_cache=v2,compress=zstd:3,subvol=@cache 0 2" >> /etc/fstab
    sudo echo "UUID=$UUID /var/tmp btrfs defaults,noatime,space_cache=v2,compress=zstd:3,subvol=@tmp 0 2" >> /etc/fstab

    # Automatizar el proceso de modificación en grub-btrfsd
    sudo sed -i 's|ExecStart=/usr/bin/grub-btrfsd --syslog /.snapshots|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' /etc/systemd/system/grub-btrfsd.service

    # Instalar Timeshift
    sudo apt install timeshift

    # Instalar grub-btrfs desde las fuentes
    sudo nala install build-essential git -y
    sudo git clone https://github.com/Antynea/grub-btrfs.git /git/
    cd /git/grub-btrfs
    sudo make install

    # Configurar grub-btrfs para monitorear instantáneas de Timeshift
    sudo update-grub
    sudo apt install inotify-tools
    sudo systemctl edit --full grub-btrfsd
    # Cambiar ExecStart=/usr/bin/grub-btrfsd --syslog /.snapshots a ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto

    # Iniciar grub-btrfsd y habilitar en el arranque
    sudo systemctl start grub-btrfsd
    sudo systemctl enable grub-btrfsd

    echo "Configuración realizada con éxito."
else
    echo "La partición root no está montada en un volumen BTRFS."
fi
