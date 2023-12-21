#!/bin/bash

get_root_uuid() {
    # Obtener el UUID de la partición donde está montado "/"
    root_partition=$(grep " / " /etc/fstab | awk '{print $1}')
    uuid=$(blkid -s UUID -o value "$root_partition")
    echo "$uuid"
}

# Llamar a la función y almacenar el resultado en una variable
UUID=$(get_root_uuid)

# Imprimir el UUID
echo "UUID de la partición root: $UUID"
