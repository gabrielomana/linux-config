#!/bin/bash

# Instalación del tema Layan KDE (Kvantum + Plasma)
# Autor: Gabriel Omaña / Initium
# Ejecutar como root

if [[ "$(id -u)" -ne 0 ]]; then
  echo "[INFO] Elevando a root..."
  exec sudo bash "$0" "$@"
fi

echo "[INFO] Agregando COPR para Layan..."
dnf copr enable -y dirkdavidis/layan-kde &>/dev/null

echo "[INFO] Instalando paquete layan-kde..."
dnf install -y layan-kde &>/dev/null || {
  echo "[ERROR] No se pudo instalar layan-kde desde COPR."
  exit 1
}

echo "[OK] Tema Layan KDE instalado. Aplica desde Preferencias del Sistema o con kvantummanager."
