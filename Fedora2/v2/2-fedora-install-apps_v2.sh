#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ───────────────────────────────────────────────────────────────
# Fedora 42 Post-install Script - Initium
# Seguridad, modularidad, logging y CI/CD-friendly
# ───────────────────────────────────────────────────────────────

# ========== VARIABLES GLOBALES ==========
SCRIPT_NAME="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")" && pwd)"
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME="$(eval echo "~$REAL_USER")"

LOG_DIR="$REAL_HOME/fedora_logs"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"
LOG_FILE="$LOG_DIR/install_full_${TIMESTAMP}.log"
ERR_FILE="$LOG_DIR/install_error_${TIMESTAMP}.log"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE" "$ERR_FILE"

# ========== REDIRECCIÓN GLOBAL ==========
exec > >(tee >(grep --line-buffered -E "^\[|^\s*\[.*\]" >> "$LOG_FILE") > /dev/tty) \
     2> >(tee >(grep --line-buffered -E "^\[WARN|^\[ERROR|^\[❌" >> "$ERR_FILE") > /dev/tty)

# ========== LOGGING ==========
log_info()    { echo -e "[INFO]  $(date '+%F %T')  $*" | tee -a "$LOG_FILE"; }
log_warn()    { echo -e "[WARN]  $(date '+%F %T')  $*" | tee -a "$LOG_FILE" >&2; echo -e "[WARN]  $(date '+%F %T')  $*" >> "$ERR_FILE"; }
log_error()   { echo -e "[ERROR] $(date '+%F %T')  $*" | tee -a "$LOG_FILE" >&2; echo -e "[ERROR] $(date '+%F %T')  $*" >> "$ERR_FILE"; exit 1; }
log_success() { echo -e "[ OK ]  $(date '+%F %T')  $*" | tee -a "$LOG_FILE"; }

# ========== MANEJO DE ERRORES ==========
error_handler() {
  local exit_code=$?
  local line_no=$1
  log_error "❌ Error en la línea $line_no. Código de salida: $exit_code. Abortando $SCRIPT_NAME"
  exit "$exit_code"
}
trap 'error_handler $LINENO' ERR

# ========== VALIDACIÓN DEPENDENCIAS ==========
check_dependency() {
  command -v "$1" &>/dev/null || log_error "Dependencia faltante: $1"
}
for bin in dnf sudo tee grep; do
  check_dependency "$bin"
done

# ========== CARGA DE FUNCIONES ==========
if [[ -f "$SCRIPT_DIR/sources/functions/functions2" ]]; then
  source "$SCRIPT_DIR/sources/functions/functions2"
  log_info "Funciones cargadas desde functions2"
else
  log_error "Archivo de funciones no encontrado: sources/functions/functions2"
fi

if [[ -f "$SCRIPT_DIR/sources/functions/functions_zsh" ]]; then
  source "$SCRIPT_DIR/sources/functions/functions_zsh"
  log_info "Funciones cargadas desde functions_zsh"
else
  log_error "Archivo de funciones no encontrado: sources/functions/functions_zsh"
fi

# ========== DEFINICIÓN DE RUTAS DE LISTAS ==========
LISTS_DIR="${SCRIPT_DIR}/sources/lists"

LIST_KDE_PLASMA="${LISTS_DIR}/kde_plasma.list"
LIST_KDE_APPS="${LISTS_DIR}/kde_plasma_apps.list"
LIST_KDE_BLOATWARE="${LISTS_DIR}/kde_bloatware.list"
LIST_MULTIMEDIA="${LISTS_DIR}/multimedia.list"
LIST_CODECS="${LISTS_DIR}/codecs.list"
LIST_UTILITIES="${LISTS_DIR}/utilities.list"
LIST_EXTRA_APPS="${LISTS_DIR}/extra_apps.list"
LIST_XORG_WORKSPACE="${LISTS_DIR}/plasma_xorg_full.list"

REQUIRED_LISTS=(
  "$LIST_KDE_PLASMA"
  "$LIST_KDE_APPS"
  "$LIST_KDE_BLOATWARE"
  "$LIST_MULTIMEDIA"
  "$LIST_CODECS"
  "$LIST_UTILITIES"
  "$LIST_EXTRA_APPS"
  "$LIST_XORG_WORKSPACE"
)

# ========== VALIDACIÓN DE LISTAS ==========
for list_file in "${REQUIRED_LISTS[@]}"; do
  [[ -f "$list_file" ]] || log_error "Lista no encontrada: $list_file"
done

# ========== EJECUCIÓN ==========
main() {
  check_dependencies
  add_repositories
  configure_hardware
  install_multimedia
  configure_konsole
  install_zsh_main
  verify_zsh_setup
  install_extra_apps
  system_cleanup

  log_info "🌀 Instalación finalizada. ¿Deseas reiniciar ahora? (s/n)"
  read -r answer
  if [[ "$answer" =~ ^[sS]$ ]]; then
    log_info "Reiniciando el sistema..."
    reboot
  else
    log_info "Reinicio omitido por el usuario."
  fi
}
main
