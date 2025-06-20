#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

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

# ========== LOGGING ==========
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date +'%Y-%m-%d %H:%M:%S')"
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

print_message() {
    local level="$1"
    local message="$2"
    local color=""
    case "$level" in
        INFO) color="\033[0;34m" ;;
        ERROR) color="\033[0;31m" ;;
        SUCCESS) color="\033[0;32m" ;;
        *) color="\033[0m" ;;
    esac
    echo -e "${color}[$level] $message\033[0m"
    log "$level" "$message"
}

execute_command() {
    local cmd="$1"
    local description="$2"
    print_message "INFO" "Ejecutando: $description"
    output=$(eval "$cmd" 2>&1) || {
        print_message "ERROR" "Error al ejecutar: $description"
        log "ERROR_DETAIL" "$output"
        ((ERROR_COUNT++))
        return 1
    }
    print_message "SUCCESS" "$description completado correctamente"
    log "OUTPUT" "$output"
}

# ========== CARGA DE FUNCIONES EXTERNAS ==========
if [[ -f "$SCRIPT_DIR/sources/functions/functions" ]]; then
    source "$SCRIPT_DIR/sources/functions/functions"
    print_message "INFO" "Funciones externas cargadas correctamente"
else
    print_message "ERROR" "Archivo de funciones no encontrado en sources/functions/"
    exit 1
fi

# ========== INICIALIZACIÓN LOG ==========
setup_log_file() {
    {
        echo "==============================================================="
        echo "    LOG DE POST-INSTALACIÓN FEDORA 42 - $TIMESTAMP"
        echo "==============================================================="
        echo ""
    } > "$LOG_FILE"
    print_message "INFO" "Archivo de log creado en $LOG_FILE"
}

# ========== FLUJO PRINCIPAL ==========
main() {
    setup_log_file

    check_dependencies
    add_repositories
    configure_hardware
    install_multimedia
    install_konsole_and_dotfiles
    install_extra_apps
    system_cleanup
    #install_zsh

    echo ""
    echo "==============================================================="
    if [[ $ERROR_COUNT -eq 0 ]]; then
        print_message "SUCCESS" "INSTALACIÓN COMPLETADA SIN ERRORES"
    else
        print_message "ERROR" "INSTALACIÓN COMPLETADA CON $ERROR_COUNT ERRORES"
        print_message "INFO" "Revise el archivo de log en $LOG_FILE"
    fi
    echo "==============================================================="

    echo ""
    read -p "¿Desea reiniciar el sistema ahora? (s/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Ss]$ ]]; then
        print_message "INFO" "Reiniciando el sistema..."
        execute_command "sudo reboot" "Reinicio del sistema"
    else
        print_message "INFO" "Reinicio cancelado. Reinicie manualmente para aplicar los cambios."
    fi
}

main
