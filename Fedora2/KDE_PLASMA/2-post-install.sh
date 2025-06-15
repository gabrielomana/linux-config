#!/bin/bash

# ───────────────────────────────────────────────────────────────
# Fedora Post-Install: Configuración y repositorios
# Autor: Gabriel Omaña / Initium
# Última revisión: 2025-06-14
# Descripción: Script para configurar Fedora tras instalación base.
# ───────────────────────────────────────────────────────────────

# Seguridad estricta
set -euo pipefail
IFS=$'\n\t'

# Variables globales
SCRIPT_NAME="$(basename "$0")"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$HOME/fedora_logs"
LOG_FILE="$LOG_DIR/${SCRIPT_NAME%.sh}.log"
ERR_FILE="$LOG_DIR/${SCRIPT_NAME%.sh}.err"

mkdir -p "$LOG_DIR"

# Logging estándar
log_info()    { echo -e "[INFO]  $(date '+%F %T')  $*" | tee -a "$LOG_FILE"; }
log_warn()    { echo -e "[WARN]  $(date '+%F %T')  $*" | tee -a "$LOG_FILE" >&2; }
log_error()   { echo -e "[ERROR] $(date '+%F %T')  $*" | tee -a "$LOG_FILE" "$ERR_FILE" >&2; exit 1; }
log_success() { echo -e "[ OK ]  $(date '+%F %T')  $*" | tee -a "$LOG_FILE"; }

# Manejo de errores
trap 'log_error "Error en la línea $LINENO. Abortando $SCRIPT_NAME."' ERR

# Validación de binarios esenciales
check_dependency() {
  command -v "$1" &>/dev/null || log_error "Dependencia faltante: $1"
}

for bin in dnf sudo tee; do
  check_dependency "$bin"
done

# Mantener sesión sudo activa en background
run_sudo() {
  while true; do
    sleep 60
    sudo -n true || break
  done & disown
}

# Barra de progreso visual
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

# ───── Variables de control ─────
ERROR_COUNT=0
EXTRA_APPS_LIST="$BASE_DIR/sources/lists/extra_apps.list"

# Validación de archivo requerido
if [[ ! -f "$EXTRA_APPS_LIST" ]]; then
  log_error "Archivo de lista de aplicaciones extra no encontrado: $EXTRA_APPS_LIST"
else
  log_info "✓ Lista de aplicaciones extra detectada: $EXTRA_APPS_LIST"
fi

# ───── Función de ejecución segura ─────
safe_run() {
  local cmd=("$@")
  log_info "Ejecutando: ${cmd[*]}"
  if "${cmd[@]}" &>> "$LOG_FILE"; then
    log_success "✔ ${cmd[*]} ejecutado correctamente"
  else
    log_error "❌ Fallo al ejecutar: ${cmd[*]}"
    ((ERROR_COUNT++))
    return 1
  fi
}

# ───── Verificación de dependencias mínimas ─────
check_dependencies() {
  log_info "🔍 Verificando dependencias..."
  local dependencies=(git wget unzip cmake dnf)
  local missing=()

  for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      missing+=("$dep")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_warn "Se instalarán las siguientes dependencias: ${missing[*]}"
    safe_run sudo dnf install -y "${missing[@]}" || log_error "Error al instalar dependencias"
  else
    log_success "Todas las dependencias requeridas están presentes"
  fi
}

# ───── Agregado de repositorios externos ─────
add_repositories() {
  log_info "🌐 Agregando repositorios externos (Brave, VSCode)..."

  safe_run sudo dnf install -y dnf-plugins-core
  safe_run sudo dnf config-manager --add-repo=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
  safe_run sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc

  local vscode_repo='/etc/yum.repos.d/vscode.repo'
  cat <<EOF | sudo tee "$vscode_repo" &> /dev/null
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

  log_success "Repositorios Brave y VSCode añadidos correctamente"
}

# ───── Ejecución principal ─────
main() {
  run_sudo

  log_info "🚀 Iniciando configuración post-instalación..."

  check_dependencies
  add_repositories

  if [[ -s "$EXTRA_APPS_LIST" ]]; then
    log_info "📦 Instalando paquetes definidos en extra_apps.list..."
    total=$(grep -cve '^\s*$' "$EXTRA_APPS_LIST")
    i=0
    while read -r pkg; do
      [[ -z "$pkg" ]] && continue
      ((i++))
      progress_bar "$i" "$total"
      safe_run sudo dnf install -y "$pkg"
    done < "$EXTRA_APPS_LIST"
    echo ""
  else
    log_warn "extra_apps.list está vacío. No se instalarán paquetes adicionales."
  fi

  log_info "✅ Configuración post-instalación finalizada"
  if [[ "$ERROR_COUNT" -gt 0 ]]; then
    log_warn "Finalizado con $ERROR_COUNT errores. Revisa $ERR_FILE para más detalles."
  else
    log_success "Todo se ejecutó correctamente sin errores."
  fi
}

main
