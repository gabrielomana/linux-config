#!/bin/bash

# ───────────────────────────────────────────────────────────────
# Script de instalación del tema Windows11-Endless para Plasma 6
# Compatible con Wayland / KDE Plasma moderno
# Requiere ejecución como root
# Autor: Gabriel Omaña / Initium
# ───────────────────────────────────────────────────────────────

# 🛡️ Autoelevación si es necesario
if [[ "$(id -u)" -ne 0 ]]; then
  echo "[INFO] Elevando permisos para ejecutar como root..."
  exec sudo bash "$0" "$@"
fi

[[ "$(id -u)" -ne 0 ]] && { echo "[FATAL] No se pudo elevar permisos. Abortando."; exit 1; }

echo "[INFO] Instalando tema Windows11-Endless para KDE Plasma 6..."

TMP_DIR="/tmp/win11_endless"
REPO_URL="https://github.com/yeyushengfan258/Windows11-Endless"
ARCHIVE_URL="https://github.com/yeyushengfan258/Windows11-Endless/archive/refs/heads/master.zip"
INSTALL_DIR="/usr/share/plasma/look-and-feel"

# Descarga del repositorio
rm -rf "$TMP_DIR"
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "[INFO] Descargando tema desde GitHub..."
curl -L -o endless_theme.zip "$ARCHIVE_URL" &>/dev/null || {
  echo "[ERROR] No se pudo descargar el tema Windows11-Endless."
  exit 1
}

unzip -q endless_theme.zip || {
  echo "[ERROR] Fallo al descomprimir el paquete del tema."
  exit 1
}

# Instalar en el sistema
THEME_SRC=$(find . -type d -name "Windows11-Endless*" | head -n1)

if [[ -z "$THEME_SRC" ]]; then
  echo "[ERROR] No se encontró la carpeta del tema tras descompresión."
  exit 1
fi

echo "[INFO] Copiando tema a $INSTALL_DIR..."
cp -r "$THEME_SRC/GlobalTheme/Windows11-Endless" "$INSTALL_DIR/" || {
  echo "[ERROR] Fallo al copiar el tema global."
  exit 1
}

echo "[INFO] Tema instalado. Puedes activarlo con:"
echo "lookandfeeltool -a Windows11-Endless"

rm -rf "$TMP_DIR"
echo "[OK] Tema Windows11-Endless instalado correctamente."
