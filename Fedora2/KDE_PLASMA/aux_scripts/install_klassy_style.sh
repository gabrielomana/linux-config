#!/bin/bash

# ───────────────────────────────────────────────────────────────
# Script de instalación del estilo Klassy para KDE (root)
# Autor: Gabriel Omaña / Initium
# Requiere ejecución como root
# ───────────────────────────────────────────────────────────────

# 🛡️ Autoelevación si es necesario
if [[ "$(id -u)" -ne 0 ]]; then
  echo "[INFO] Elevando permisos para ejecutar como root..."
  exec sudo bash "$0" "$@"
fi

[[ "$(id -u)" -ne 0 ]] && { echo "[FATAL] No se pudo elevar permisos. Abortando."; exit 1; }

echo "[INFO] Instalando estilo Klassy para KDE..."

# Agregar repositorio COPR si no está
if ! dnf repolist | grep -q "copr:copr.fedorainfracloud.org/dirkdavidis/klassy"; then
  echo "[INFO] Habilitando repositorio COPR para Klassy..."
  dnf copr enable -y dirkdavidis/klassy &>/dev/null || {
    echo "[ERROR] No se pudo habilitar el repositorio COPR."
    exit 1
  }
else
  echo "[INFO] Repositorio COPR para Klassy ya está habilitado."
fi

# Instalar Klassy
echo "[INFO] Instalando paquete klasy-kde..."
dnf install -y klassy-kde &>/dev/null || {
  echo "[ERROR] Fallo en la instalación de klassy-kde."
  exit 1
}

echo "[OK] Estilo Klassy instalado correctamente."
