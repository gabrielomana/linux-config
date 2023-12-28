#!/bin/bash

function check_installed {
  local package
  local list=""
  local list2=""

  while IFS= read -r package; do
    [ -z "${package}" ] && continue

    if dpkg -l "${package}" 2>/dev/null | grep -q "ii"; then
      echo "El paquete ${package} ya está instalado."
    else
      # Verificar si el paquete es un patrón y obtener la lista de paquetes que coinciden
      if [[ "${package}" == *'*'* ]]; then
        matching_packages=($(apt list "${package}" 2>/dev/null | grep -oP "^\S+"))
        if [ ${#matching_packages[@]} -eq 0 ]; then
          echo "No hay paquetes que coincidan con el patrón ${package} en los repositorios."
        else
          list2="${list2} ${matching_packages[@]}"
        fi
      else
        # Verificar si el paquete existe en los repositorios
        if apt show "${package}" &>/dev/null; then
          list="${list} ${package}"
        else
          echo "El paquete ${package} no está instalado y no existe en los repositorios."
        fi
      fi
    fi
  done < "${1}"

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

# Ejemplo de lista de paquetes
package=("kcalc" "kate" "kmix" "knotes" "kde-config-cron*" "krename" "kamoso" "kolourpaint" "kid3" "kcolorchooser"
  "kcharselect" "kdenetwork-filesharing" "kfind" "kget" "kinfocenter" "kio*" "kio-admin" "kleopatra"
  "krdc" "kaccounts-providers" "kio-gdrive" "kbackup" "plasma-nm" "plasma-pa" "plasma-widget*" "plasma-widgets-addons"
  "ffmpegthumbs" "ark" "okular" "ksystemlog" "kde-config-cron" "kdeplasma-addons" "kdeplasma-addon*")

check_installed "${package}"



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
