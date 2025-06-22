#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
trap 'echo "■ Error en la línea $LINENO"; exit 1' ERR

# ───────────────────────────────────────────────────────────────
# Fedora 42 Post-install Script - Initium (v3)
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
    source "$SCRIPT_DIR/sources/functions/functions3"
    log_info "Funciones3 cargadas correctamente"
else
    echo "[ERROR] No se encontró el archivo functions3 en sources/functions/"
    exit 1
fi

if [[ -f "$SCRIPT_DIR/sources/functions/functions_zsh_v2" ]]; then
    source "$SCRIPT_DIR/sources/functions/functions_zsh_v2"
    log_info "Funciones ZSH cargadas correctamente"
else
    echo "[ERROR] No se encontró el archivo functions_zsh_v2 en sources/functions/"
    exit 1
fi

# ========== EJECUCIÓN PRINCIPAL ==========
main() {
    log_section "🛠️ INICIO DE POST-INSTALACIÓN EN FEDORA"
    
    check_dependencies
    add_repositories
    configure_hardware
    install_multimedia
    configure_konsole
    install_zsh_main       # ZSH completo: usuario + root
    install_extra_apps     # CLI, utilidades adicionales
    system_cleanup

    log_success "✅ Instalación finalizada correctamente"

    echo -e "\n🌀 ¿Deseas reiniciar ahora? (s/n)"
    read -r answer
    if [[ "$answer" =~ ^[sS]$ ]]; then
        log_info "Reiniciando el sistema..."
        reboot
    else
        log_info "Reinicio omitido por el usuario."
    fi
}

main
