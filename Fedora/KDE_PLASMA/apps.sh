#!/bin/bash
dir=$(pwd)

codecs="${dir}/sources/lists/codecs.list"
exta_apps="${dir}/sources/lists/exta_apps.list"
kde_plasma="${dir}/sources/lists/kde_plasma.list"
kde_plasma_apps="${dir}/sources/lists/kde_plasma_apps.list"
multimedia="${dir}/sources/lists/multimedia.list"
tools="${dir}/sources/lists/tools.list"
utilities="${dir}/sources/lists/utilities.list"
xfce="${dir}/sources/lists/xfce.list"
kde_bloatware="${dir}/sources/lists/kde_bloatware.list"

. "${dir}/sources/functions/functions"

# Obtener la lista de paquetes desde el archivo kde_plasma.list
packages=($(<"${kde_plasma}"))

# Crear una nueva lista para los paquetes que necesitan instalación o actualización
to_install_or_update=()

# Verificar disponibilidad, instalación y actualización de cada paquete
for package in "${packages[@]}"; do
    if sudo dnf list available "$package" &> /dev/null; then
        echo "El paquete $package está disponible en los repositorios."

        if ! sudo dnf list installed "$package" &> /dev/null || sudo dnf list updates "$package" &> /dev/null; then
            #echo "El paquete $package no está instalado o puede ser actualizado."
            to_install_or_update+=("$package")
        else
            #echo "El paquete $package ya está instalado y actualizado."
        fi
    else
        #echo "El paquete $package no está disponible en los repositorios."
    fi
done

# Instalar o actualizar paquetes
if [ ${#to_install_or_update[@]} -gt 0 ]; then
    echo "Instalando o actualizando paquetes:"
    sudo dnf install -y "${to_install_or_update[@]}"
else
    echo "Todos los paquetes disponibles ya están instalados y actualizados."
fi