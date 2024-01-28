#!/bin/bash
total_ram=$(free -g | awk '/^Mem:/{print $2}')

if [ $total_ram -le 4 ]; then
    swappiness=60
    zswap_max_pool=40
    vfs_cache_pressure=50
elif [ $total_ram -le 12 ]; then
    swappiness=40
    zswap_max_pool=33
    vfs_cache_pressure=50
elif [ $total_ram -le 20 ]; then
    swappiness=30
    zswap_max_pool=25
    vfs_cache_pressure=50
elif [ $total_ram -le 32 ]; then
    swappiness=20
    zswap_max_pool=20
    vfs_cache_pressure=75
else
    swappiness=10
    zswap_max_pool=20
    vfs_cache_pressure=75
fi

sysctl_conf="/etc/sysctl.d/99-sysctl.conf"
if [ -f "$sysctl_conf" ]; then
    # Borrar el contenido del archivo
    sudo echo -n > "$sysctl_conf"
else
    # Crear el archivo si no existe
    sudo touch "$sysctl_conf"
fi

echo "vm.swappiness=$swappiness" | sudo tee -a "$sysctl_conf"
echo "vm.vfs_cache_pressure=$vfs_cache_pressure" | sudo tee -a "$sysctl_conf"

