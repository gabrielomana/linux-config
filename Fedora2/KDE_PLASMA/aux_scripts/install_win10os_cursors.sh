#!/bin/bash

# ───────────────────────────────────────────────────────────────
# Script de instalación de cursores estilo Windows 10 para KDE (root)
# Autor: Gabriel Omaña / Initium
# Requiere ejecución como root
# ───────────────────────────────────────────────────────────────

# 🛡️ Autoelevación si es necesario
if [[ "$(id -u)" -ne 0 ]]; then
  echo "[INFO] Elevando permisos para ejecutar como root..."
  exec sudo bash "$0" "$@"
fi

[[ "$(id -u)" -ne 0 ]] && { echo "[FATAL] No se pudo elevar permisos. Abortando."; exit 1; }

echo "[INFO] Instalando cursores estilo Windows 10..."

# Directorio de instalación
DEST_DIR="/usr/share/icons/Windows-10"
TMP_DIR="/tmp/win10os_cursors"
CURSOR_URL="https://github.com/ful1e5/Windows-10-Cursors/archive/refs/heads/master.zip"

# Verificación previa
if [[ -d "$DEST_DIR" ]]; then
  echo "[INFO] Los cursores Windows 10 ya están instalados. Se omite."
  exit 0
fi

# Descarga e instalación
mkdir -p "$TMP_DIR"
cd "$TMP_DIR"

echo "[INFO] Descargando paquete de cursores..."
curl -sL "$CURSOR_URL" -o cursors.zip || {
  echo "[ERROR] No se pudo descargar el archivo ZIP de cursores."
  exit 1
}

unzip -q cursors.zip || {
  echo "[ERROR] Fallo al descomprimir el paquete ZIP."
  exit 1
}

INSTALL_FOLDER=$(find . -type d -name "Windows-10-*" | head -n1)
if [[ -z "$INSTALL_FOLDER" ]]; then
  echo "[ERROR] No se encontró carpeta válida tras descompresión."
  exit 1
fi

cp -r "$INSTALL_FOLDER" "$DEST_DIR" || {
  echo "[ERROR] No se pudo copiar los cursores a $DEST_DIR"
  exit 1
}

rm -rf "$TMP_DIR"
echo "[OK] Cursores estilo Windows 10 instalados correctamente en $DEST_DIR"
