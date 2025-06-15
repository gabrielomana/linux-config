#!/bin/bash

# ───────────────────────────────────────────────────────────────
# Fedora KDE Plasma: Instalación automatizada
# Autor: Gabriel Omaña / Initium
# Última revisión: 2025-06-14
# Descripción: Script para instalación base y preparación del entorno KDE Plasma.
# ───────────────────────────────────────────────────────────────

# Seguridad y entorno estricto
set -euo pipefail
IFS=$'\n\t'

# ───── Variables globales ─────
SCRIPT_NAME="$(basename "$0")"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Directorio de logs
LOG_DIR="$HOME/fedora_logs"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME%.sh}.log"
ERR_FILE="$LOG_DIR/${SCRIPT_NAME%.sh}.err"
mkdir -p "$LOG_DIR"

# ───── Logging estándar ─────
log_info()   { echo -e "[INFO]  $(date '+%F %T')  $*" | tee -a "$LOG_FILE"; }
log_warn()   { echo -e "[WARN]  $(date '+%F %T')  $*" | tee -a "$LOG_FILE" >&2; }
log_error()  { echo -e "[ERROR] $(date '+%F %T')  $*" | tee -a "$LOG_FILE" "$ERR_FILE" >&2; exit 1; }
log_success(){ echo -e "[ OK ]  $(date '+%F %T')  $*" | tee -a "$LOG_FILE"; }

# ───── Manejador de errores ─────
trap 'log_error "Error en la línea $LINENO. Abortando $SCRIPT_NAME."' ERR

# ───── Validación de comandos base ─────
check_dependency() {
  command -v "$1" &>/dev/null || log_error "Dependencia faltante: $1"
}

for bin in dnf sudo tee; do
  check_dependency "$bin"
done

# ───── Carga de funciones compartidas ─────
FUNCTIONS_DIR="${BASE_DIR}/sources/functions/functions"
if [[ -f "$FUNCTIONS_DIR" ]]; then
  source "$FUNCTIONS_DIR"
  log_info "Funciones cargadas desde $FUNCTIONS_DIR"
else
  log_error "Archivo de funciones no encontrado: $FUNCTIONS_DIR"
fi

# ───── Comprobación de permisos sudo ─────
if ! sudo -n true 2>/dev/null; then
  log_warn "Se requieren permisos sudo para continuar."
  sudo -v || log_error "No se pudo obtener permisos sudo. Abortando."
fi

# ───── Mantenimiento de sesión sudo ─────
run_sudo() {
  while true; do
    sleep 60
    sudo -n true || break
  done & disown
}

# ───── Barra de progreso ─────
progress_bar() {
  local current=$1
  local total=$2
  local width=40
  local progress=$(( current * width / total ))
  local percent=$(( current * 100 / total ))
  local filled=$(printf "%${progress}s" | tr ' ' '#')
  local empty=$(printf "%$((width - progress))s" | tr ' ' '-')
  printf "\r[%s%s] %3d%% (%d/%d)" "$filled" "$empty" "$percent" "$current" "$total"
  [[ "$current" -eq "$total" ]] && echo ""
}

# ───── Backup de entorno del usuario ─────
BASHRC_BACKUP="$HOME/.bashrc_original"
if [[ -f "$HOME/.bashrc" && ! -f "$BASHRC_BACKUP" ]]; then
  cp "$HOME/.bashrc" "$BASHRC_BACKUP"
  log_info "Se realizó respaldo de .bashrc en $BASHRC_BACKUP"
fi

# ───── Carga de listas de paquetes ─────
LISTS_DIR="${BASE_DIR}/sources/lists"

declare -A PACKAGE_LISTS=(
  [codecs]="$LISTS_DIR/codecs.list"
  [extra_apps]="$LISTS_DIR/extra_apps.list"
  [kde_plasma]="$LISTS_DIR/kde_plasma.list"
  [kde_plasma_apps]="$LISTS_DIR/kde_plasma_apps.list"
  [multimedia]="$LISTS_DIR/multimedia.list"
  [tools]="$LISTS_DIR/tools.list"
  [utilities]="$LISTS_DIR/utilities.list"
  [xfce]="$LISTS_DIR/xfce.list"
  [kde_bloatware]="$LISTS_DIR/kde_bloatware.list"
)

validate_package_lists() {
  for key in "${!PACKAGE_LISTS[@]}"; do
    local list_path="${PACKAGE_LISTS[$key]}"
    if [[ ! -f "$list_path" ]]; then
      log_error "Archivo obligatorio no encontrado: $list_path"
    else
      log_info "✓ Lista validada: $key"
    fi
  done
}

check_error() {
  local exit_code=$1
  local msg=$2
  if [[ "$exit_code" -ne 0 ]]; then
    log_error "$msg"
  fi
}

# ───── Ejecución principal ─────

log_info "Validando listas de paquetes requeridas..."
validate_package_lists
log_success "Todas las listas han sido validadas correctamente."

main() {
  log_info "▶ Instalando KDE Plasma..."
  install_kde || check_error $? "Falló la instalación de KDE Plasma"
  log_success "✔ KDE Plasma instalado correctamente."

  # log_info "▶ Instalando aplicaciones base del sistema..."
  # install_core_apps || check_error $? "Falló la instalación de aplicaciones base"
  # log_success "✔ Aplicaciones base instaladas correctamente."

  # log_info "▶ Instalando aplicaciones multimedia..."
  # install_multimedia || check_error $? "Falló la instalación de multimedia"
  # log_success "✔ Aplicaciones multimedia instaladas correctamente."

  # log_info "▶ Ejecutando actualización completa del sistema..."
  # run_sudo
  # sudo dnf clean all &>> "$LOG_FILE"
  # sudo dnf update -y &>> "$LOG_FILE"
  # sudo dnf upgrade -y &>> "$LOG_FILE"
  # log_success "✔ Sistema actualizado correctamente."

  # log_info "🌀 Reiniciando sistema para aplicar cambios..."
  # sudo reboot
}

main