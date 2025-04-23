#!/bin/bash

# Función para obtener la UUID de una partición dada por el punto de montaje
get_uuid() {
    local mount_point=$1
    grep -E "${mount_point}\s+btrfs\s+" "/etc/fstab" | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p'
}

# Inicializamos un archivo de salida nuevo
output_file="/etc/fstab.new"

# Copiar el contenido original de /etc/fstab al nuevo archivo
cp /etc/fstab $output_file

# Obtener las UUIDs de las particiones
ROOT_UUID=$(get_uuid "/")
HOME_UUID=$(get_uuid "/home")
VAR_UUID=$(get_uuid "/var")
VAR_LOG_UUID=$(get_uuid "/var/log")
SNAPSHOT_UUID=$(get_uuid "/.snapshots")

# Modificar las entradas correspondientes si las UUIDs fueron encontradas

if [ -n "$ROOT_UUID" ]; then
    sudo sed -i -E "s|UUID=.*\s+/\s+btrfs.*|UUID=${ROOT_UUID} / btrfs rw,noatime,compress=lzo,space_cache=v2,subvol=@ 0 0|" $output_file
fi

if [ -n "$HOME_UUID" ]; then
    sudo sed -i -E "s|UUID=.*\s+/home\s+btrfs.*|UUID=${HOME_UUID} /home btrfs rw,noatime,compress=lzo,space_cache=v2,subvol=@home 0 0|" $output_file
fi

if [ -n "$VAR_UUID" ]; then
    sudo sed -i -E "s|UUID=.*\s+/var\s+btrfs.*|UUID=${VAR_UUID} /var btrfs rw,noatime,compress=lzo,space_cache=v2,subvol=@var 0 0|" $output_file
fi

if [ -n "$VAR_LOG_UUID" ]; then
    sudo sed -i -E "s|UUID=.*\s+/var/log\s+btrfs.*|UUID=${VAR_LOG_UUID} /var/log btrfs rw,noatime,compress=lzo,space_cache=v2,subvol=@varlog 0 0|" $output_file
fi

if [ -n "$SNAPSHOT_UUID" ]; then
    sudo sed -i -E "s|UUID=.*\s+/.snapshots\s+btrfs.*|UUID=${SNAPSHOT_UUID} /.snapshots btrfs rw,noatime,compress=lzo,space_cache=v2,subvol=@snapshots 0 0|" $output_file
fi

# Informar que el archivo ha sido generado
echo "El archivo /etc/fstab.new ha sido creado con las nuevas configuraciones."

# Mostrar el contenido del nuevo archivo /etc/fstab.new
echo "Contenido de /etc/fstab.new:"
cat $output_file
