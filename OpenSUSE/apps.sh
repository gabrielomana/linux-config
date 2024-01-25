#!/bin/bash
explorar_lista() {
    local lista=$1
    local paquetes_a_instalar=()

    # Iterar sobre la lista
    while IFS= read -r paquete; do
        # Verificar si el paquete está disponible en los repositorios
        if zypper search -s "$paquete" | grep -q "i | $paquete"; then
            # Verificar si el paquete está instalado
            if ! zypper search -i "$paquete" | grep -q "i | $paquete"; then
                paquetes_a_instalar+=("$paquete")
            fi
        else
            echo "El paquete \"$paquete\" no está disponible en los repositorios."
        fi
    done < "$lista"

    # Instalar los paquetes pendientes
    if [ ${#paquetes_a_instalar[@]} -gt 0 ]; then
        echo "Instalando paquetes: ${paquetes_a_instalar[*]}"
        sudo zypper install "${paquetes_a_instalar[@]}"
    else
        echo "No hay paquetes para instalar."
    fi
}

# Ejemplo de uso
lista=("\"KDE Plasma Workspaces\""
"\"Hardware Support\""
"\"Wayland\""
"\"X11\""
"\"Wifi\""
"plasma-desktop-minimal"
"plasma-workspace-wayland"
"plasma-wayland-session")

explorar_lista "${lista[@]}"