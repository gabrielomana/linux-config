#!/bin/bash

function check_installed {
  local package
  local to_install=()
  list=""
  list2=""
  
  while IFS= read -r package; do
    [ -z "${package}" ] && continue

    STR="${package}"

    if dpkg -s "${STR}" >/dev/null 2>&1; then
      echo "El paquete ${STR} ya está instalado."
    else
      if nala show "${STR}" 2>&1 | grep -q "Error: "; then
        echo "El paquete ${STR} no está instalado y no se puede instalar."
      else
        list="${list} \"${STR}\""
        list2="${list2} \"${STR}\""
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

check_installed "${package}"
