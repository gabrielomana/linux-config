#!/bin/bash

# ───────────────────────────────────────────────────────────────
# Script de instalación del tema Layan GTK para Plasma 6 + Wayland
# Compatible con apps GTK3, GTK4 y Electron
# Requiere ejecución como root
# Autor: Gabriel Omaña / Initium
# ───────────────────────────────────────────────────────────────

# 🛡️ Autoelevación si es necesario
if [[ "$(id -u)" -ne 0 ]]; then
  echo "[INFO] Elevando permisos para ejecutar como root..."
  exec sudo bash "$0" "$@"
fi

[[ "$(id -u)" -ne 0 ]] && { echo "[FATAL] No se pudo elevar permisos. Abortando."; exit 1; }

echo "[INFO] Instalando tema GTK Layan..."

TMP_DIR="/tmp/layan_gtk"
REPO_URL="https://github.com/vinceliuice/Layan-gtk-theme.git"
INSTALL_SCRIPT="./install.sh"
INSTALL_ARGS="-c dark --tweaks normal -l"

rm -rf "$TMP_DIR"
git clone --depth=1 "$REPO_URL" "$TMP_DIR" &>/dev/null || {
  echo "[ERROR] No se pudo clonar el repositorio del tema Layan."
  exit 1
}

cd "$TMP_DIR" || {
  echo "[ERROR] No se pudo acceder al directorio $TMP_DIR"
  exit 1
}

echo "[INFO] Ejecutando script de instalación..."
$INSTALL_SCRIPT $INSTALL_ARGS &>/dev/null || {
  echo "[ERROR] Fallo durante la instalación del tema Layan."
  exit 1
}

echo "[OK] Tema GTK Layan instalado correctamente."

rm -rf "$TMP_DIR"
