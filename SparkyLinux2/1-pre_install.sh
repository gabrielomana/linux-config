#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
trap 'echo "[ERROR] Fallo en $0, línea $LINENO" >&2; exit 1'

PROJECT_ROOT="$(dirname "$0")"
source "$PROJECT_ROOT/KDE_PLASMA/functions/init_env.sh"

LOGDIR="$HOME/sparky_logs"
mkdir -p "$LOGDIR"
exec > >(tee -a "$LOGDIR/pre_install.log") \
     2> >(tee -a "$LOGDIR/pre_install.err" >&2)

log_info "📍 Iniciando preinstalación en $(date)"

require_cmd sudo
require_cmd apt
require_cmd locale-gen
require_cmd dpkg

NEW_PATH="/usr/local/sbin:/usr/local/bin"
if ! grep -qxF "export PATH=\$PATH:${NEW_PATH}" ~/.profile; then
  echo "export PATH=\$PATH:${NEW_PATH}" >> ~/.profile
fi
if ! sudo grep -qxF "export PATH=\$PATH:${NEW_PATH}" /etc/profile; then
  echo "export PATH=\$PATH:${NEW_PATH}" | sudo tee -a /etc/profile > /dev/null
fi

log_info "🧭 PATH extendido con ${NEW_PATH}"

packages=(locales locales-all hunspell-es)
APT_FLAGS="-y --no-install-recommends"
run_cmd sudo apt-get update
run_cmd sudo apt-get install $APT_FLAGS "${packages[@]}"
log_success "📦 Paquetes de localización instalados"

run_cmd sudo locale-gen "es_ES.UTF-8"
run_cmd sudo update-locale LANG=es_ES.UTF-8
source /etc/default/locale
log_success "🌐 Locales configurados correctamente"

KBD_LAYOUT="${KBD_LAYOUT:-es}"
run_cmd sudo localectl set-x11-keymap "$KBD_LAYOUT"

run_cmd sudo dpkg-reconfigure keyboard-configuration
run_cmd sudo systemctl restart keyboard-setup.service
run_cmd sudo systemctl restart console-setup.service
run_cmd sudo systemctl enable console-setup.service
log_success "🎹 Configuración de teclado y consola finalizada"
log_success "✅ Preinstalación completada correctamente"
