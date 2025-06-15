#!/usr/bin/env bash
# ==============================================================================
# Funciones reutilizables para scripts de instalación SparkyLinux
# Requiere: bash 4+, set -euo pipefail en script principal
# ==============================================================================

# Registro con timestamp
log_info()    { echo -e "[INFO]    $(date +'%F %T') ➜ $*"; }
log_warn()    { echo -e "[WARNING] $(date +'%F %T') ⚠ $*" >&2; }
log_error()   { echo -e "[ERROR]   $(date +'%F %T') ❌ $*" >&2; }
log_success() { echo -e "[OK]      $(date +'%F %T') ✅ $*"; }
log_section() { echo -e "\n\033[1;34m🔷 $*\033[0m"; }

# Comprueba si un comando está disponible
require_cmd() {
  if ! command -v "$1" &>/dev/null; then
    log_error "Requiere el comando '$1', pero no está instalado."
    exit 1
  fi
}

# Ejecuta un comando con logging y control de errores
run_cmd() {
  log_info "Ejecutando: $*"
  if ! "$@"; then
    log_error "Fallo ejecutando: $*"
    exit 1
  fi
}
