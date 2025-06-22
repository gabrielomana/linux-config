#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
trap 'echo "■ Error en la línea $LINENO"; exit 1' ERR

# ───────────────────────────────────────────────────────────────
# Fedora 42 Post-install Script - Initium
# Seguridad, modularidad, logging y CI/CD-friendly
# ───────────────────────────────────────────────────────────────

# ========== VARIABLES GLOBALES ==========
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXTRA_APPS_LIST="$SCRIPT_DIR/sources/lists/extra_apps.list"
LOG_DIR="$HOME/fedora_logs"
LOG_FILE="$LOG_DIR/fedora_post_install.log"
ERROR_COUNT=0
TIMESTAMP="$(date +'%Y-%m-%d %H:%M:%S')"

mkdir -p "$LOG_DIR"

# ========== CARGA DE FUNCIONES EXTERNAS ==========
if [[ -f "$SCRIPT_DIR/sources/functions/functions3" ]]; then
    log_info "INFO" "Funciones externas cargadas correctamente"
else
    log_info "ERROR" "Archivo de funciones no encontrado en sources/functions2/"
    exit 1
fi

if [[ -f "$SCRIPT_DIR/sources/functions/functions_zsh_v2" ]]; then
    log_info "INFO" "Funciones externas cargadas correctamente"
else
    log_info "ERROR" "Archivo de funciones no encontrado en sources/functions/"
    exit 1
fi


main() {
    check_dependencies
    add_repositories
    configure_hardware
    install_multimedia
    configure_konsole
    install_zsh_main      # ← ahora todo ZSH
    install_extra_apps    # (incluye CLI tools)
    system_cleanup

  echo -e "
🌀 Instalación finalizada. ¿Deseas reiniciar ahora? (s/n)"
  read -r answer
  if [[ "$answer" =~ ^[sS]$ ]]; then
    log_info "Reiniciando el sistema..."
    reboot
  else
    log_info "Reinicio omitido por el usuario."
  fi
}

main
