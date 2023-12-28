#!/bin/bash
dir="$(pwd)"
kde_plasma="${dir}/sources/lists/kde_plasma.list"
kde_plasma_apps="${dir}/sources/lists/kde_plasma_apps.list"

function check_installed {
  local package_list="$1"
  local list=""
  local list2=""

  while IFS= read -r package; do
    [ -z "${package}" ] && continue

    # Verificar si el paquete es un patrón y obtener la lista de paquetes que coinciden
    if [[ "${package}" == *'*'* ]]; then
      matching_packages=($(apt search "${package}" | grep -oP "^[\S]+"))
      if [ ${#matching_packages[@]} -eq 0 ]; then
        echo "No hay paquetes que coincidan con el patrón ${package} en los repositorios."
      else
        list2="${list2} ${matching_packages[@]}"
      fi
    else
      # Verificar si el paquete existe en los repositorios
      if apt show "${package}" &>/dev/null; then
        list="${list} \"${package}\""
      else
        echo "El paquete ${package} no existe en los repositorios."
      fi
    fi
  done <<< "${package_list}"

  # Imprime los paquetes a instalar con nala
  if [ -n "${list}" ]; then
    echo "Paquetes a instalar con nala:"
    echo "sudo nala install ${list} -y"
  else
    echo "No hay paquetes para instalar con nala."
  fi

  # Imprime los paquetes a instalar con apt
  if [ -n "${list2}" ]; then
    echo "Paquetes a instalar con apt:"
    echo "sudo apt install ${list2} -y"
  else
    echo "No hay paquetes para instalar con apt."
  fi
}

check_installed "${kde_plasma_apps}"






# package=(
#   "kcalc"
#   "kate"
#   "kmix"
#   "knotes"
#   "\"kde-config-cron*\""
#   "krename"
#   "kamoso"
#   "kolourpaint"
#   "kid3"
#   "kcolorchooser"
#   "kcharselect"
#   "kdenetwork-filesharing"
#   "kfind"
#   "kget"
#   "kinfocenter"
#   "\"kio*\""
#   "\"kio*\""
#   "kio-admin"
#   "kleopatra"
#   "krdc"
#   "kaccounts-providers"
#   "kio-gdrive"
#   "kbackup"
#   "plasma-nm"
#   "plasma-pa"
#   "\"plasma-widget*\""
#   "\"plasma-widget*\""
#   "plasma-widgets-addons"
#   "ffmpegthumbs"
#   "ark"
#   "okular"
#   "ksystemlog"
#   "kde-config-cron"
#   "kdeplasma-addons"
#   "\"kdeplasma-addon*\""
# )
