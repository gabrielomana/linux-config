#!/bin/bash

# ───────────────────────────────────────────────────────────────
# Fedora KDE Plasma: Instalación automatizada
# Autor: Gabriel Omaña / Initium
# Última revisión: 2025-06-15
# Descripción: Script para instalación base y preparación del entorno KDE Plasma.
# ───────────────────────────────────────────────────────────────

set -euo pipefail
IFS=$'\n\t'

# ───── Variables globales ─────
SCRIPT_NAME="$(basename "$0")"
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(eval echo "~$REAL_USER")

LOG_DIR="$REAL_HOME/fedora_logs"
DATESTAMP=$(date '+%Y%m%d-%H%M')
LOG_FILE="$LOG_DIR/install_full_${DATESTAMP}.log"
ERR_FILE="$LOG_DIR/install_error_${DATESTAMP}.log"

# Preguntar si se desea eliminar logs anteriores
if [[ -d "$LOG_DIR" ]]; then
  read -rp $'\e[1;34m¿Deseas eliminar logs anteriores en "$LOG_DIR"? [s/N]: \e[0m' clear_logs
  if [[ "$clear_logs" =~ ^[sS]$ ]]; then
    find "$LOG_DIR" -type f -name 'install_*.log' -delete
    echo "[INFO]  $(date '+%F %T')  Logs anteriores eliminados en $LOG_DIR"
  fi
fi

mkdir -p "$LOG_DIR"
touch "$LOG_FILE" "$ERR_FILE"

# ───── Redirección global: consola + logs con filtrado inteligente ─────
exec > >(tee >(grep --line-buffered -E "^\[|^\s*\[.*\]" >> "$LOG_FILE") > /dev/tty) \
     2> >(tee >(grep --line-buffered -E "^\[WARN|^\[ERROR|^\[❗" >> "$ERR_FILE") > /dev/tty)

# ───── Logging estándar ─────
log_info() {
  local msg="[INFO]  $(date '+%F %T')  $*"
  echo -e "$msg" | tee -a "$LOG_FILE"
}

log_warn() {
  local msg="[WARN]  $(date '+%F %T')  $*"
  echo -e "$msg" | tee -a "$LOG_FILE" >&2
  echo -e "$msg" >> "$ERR_FILE"
}

log_error() {
  local msg="[ERROR] $(date '+%F %T')  $*"
  echo -e "$msg" | tee -a "$LOG_FILE" >&2
  echo -e "$msg" >> "$ERR_FILE"
  exit 1
}

log_success() {
  local msg="[ OK ]  $(date '+%F %T')  $*"
  echo -e "$msg" | tee -a "$LOG_FILE"
}

# ───── Manejador de errores ─────
error_handler() {
  local exit_code=$?
  local line_no=$1
  log_error "❗ Error en la línea $line_no. Código de salida: $exit_code. Abortando $SCRIPT_NAME"
  exit "$exit_code"
}

trap 'error_handler $LINENO' ERR



# ───── Validación de comandos base ─────
check_dependency() {
  command -v "$1" &>/dev/null || log_error "Dependencia faltante: $1"
}

for bin in dnf sudo tee; do
  check_dependency "$bin"
done

# ───── Carga de funciones compartidas ─────
FUNCTIONS_FILE="${BASE_DIR}/sources/functions/functions2"

if [[ -f "$FUNCTIONS_FILE" ]]; then
  source "$FUNCTIONS_FILE"
  log_info "Funciones cargadas desde $FUNCTIONS_FILE"

  if ! declare -f install_kde &>/dev/null; then
    log_error "La función 'install_kde' no está definida tras cargar el archivo de funciones"
  fi
else
  log_error "Archivo de funciones no encontrado: $FUNCTIONS_FILE"
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
#   log_section "🚀 Iniciando instalación automatizada de Fedora KDE"

#   log_info "🔹 Instalando KDE Plasma..."
#   install_kde || check_error $? "❌ Falló la instalación de KDE Plasma"
#   log_success "✅ KDE Plasma instalado correctamente"

  log_info "🔹 Instalando aplicaciones base del sistema..."
  install_core_apps || check_error $? "❌ Falló la instalación de aplicaciones base"
  log_success "✅ Aplicaciones base instaladas correctamente"

  log_info "🔹 Instalando aplicaciones multimedia..."
  install_multimedia || check_error $? "❌ Falló la instalación de multimedia"
  log_success "✅ Aplicaciones multimedia instaladas correctamente"

  log_info "🔄 Ejecutando actualización completa del sistema..."
  run_sudo
  sudo dnf clean all &>> "$LOG_FILE"
  sudo dnf update -y &>> "$LOG_FILE"
  sudo dnf upgrade -y &>> "$LOG_FILE"
  log_success "✅ Sistema actualizado correctamente"

  log_info "🔁 Reiniciando sistema para aplicar cambios..."
  sudo reboot
}
main

add_repositories() {
  log_section "🔗 Adding External Repositories"

  try_cmd "Installing dnf-plugins-core" sudo dnf install -y dnf-plugins-core

  # Brave Browser
  local brave_repo="/etc/yum.repos.d/brave-browser.repo"
  if [[ ! -f "$brave_repo" ]]; then
    try_cmd "Adding Brave repo" sudo dnf config-manager --add-repo=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
    try_cmd "Importing Brave GPG key" sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
    log_success "✓ Brave repo configured"
  else
    log_info "Brave repo already present. Skipping."
  fi

  # VSCode
  local vscode_repo="/etc/yum.repos.d/vscode.repo"
  if [[ ! -f "$vscode_repo" ]]; then
    log_info "Adding Microsoft VSCode repo..."
    cat <<EOF | sudo tee "$vscode_repo" &>/dev/null
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    try_cmd "Importing Microsoft GPG key" sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    log_success "✓ VSCode repo configured"
  else
    log_info "VSCode repo already present. Skipping."
  fi
}

run_sudo() {
  while true; do
    sleep 60
    sudo -n true || break
  done & disown
}

check_dependencies() {
  log_section "🔍 Checking Minimum Dependencies"
  local dependencies=(git wget unzip cmake dnf)
  local missing=()

  for dep in "${dependencies[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      missing+=("$dep")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    log_warn "Installing missing dependencies: ${missing[*]}"
    try_cmd "Installing dependencies" sudo dnf install -y "${missing[@]}"
  else
    log_success "All required dependencies are present"
  fi
}

install_extra_apps_with_progress() {
  local extra_list="$BASE_DIR/sources/lists/extra_apps.list"
  if [[ ! -f "$extra_list" ]]; then
    log_warn "extra_apps.list not found. Skipping extra packages."
    return
  fi

  log_section "📦 Installing Extra Applications"
  local total
  total=$(grep -cve '^\s*$' "$extra_list" || echo 0)
  local i=0

  while read -r pkg; do
    [[ -z "$pkg" ]] && continue
    ((i++))
    show_progress "$i" "$total"
    try_cmd "Installing $pkg" sudo dnf install -y "$pkg"
  done < "$extra_list"
  echo ""
  log_success "✓ Extra applications installation completed"
}

show_progress() {
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

# ───── Post-Installation Extension ─────
run_sudo
check_dependencies
add_repositories
install_extra_apps_with_progress

install_kde_with_xorg() {
  log_section "🖥️ Installing KDE Plasma with Xorg"

  # Instalar grupo KDE Plasma
  try_cmd "Installing KDE Plasma Workspaces group" sudo dnf groupinstall -y "KDE Plasma Workspaces"

  # Instalar servidor Xorg explícitamente
  try_cmd "Installing Xorg server" sudo dnf install -y xorg-x11-server-Xorg

  # Instalar y habilitar SDDM
  try_cmd "Installing SDDM display manager" sudo dnf install -y sddm
  try_cmd "Enabling SDDM" sudo systemctl enable sddm

  # Configurar arranque gráfico por defecto
  try_cmd "Setting graphical target as default" sudo systemctl set-default graphical.target

  log_success "✓ KDE Plasma with Xorg installed and configured"
}

install_kde_with_xorg

install_from_list() {
  local list_file="$1"
  local enable_wildcards="\${2:-false}"

  if [[ ! -f "$list_file" ]]; then
    log_error "❌ Package list not found: $list_file"
    return 1
  fi

  log_section "📦 Installing packages from list: $list_file"

  local groups=()
  local packages=()
  local wildcards=()

  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"                      # Strip comments
    line="${line//[$'\t\r\n ']}"         # Trim whitespace

    [[ -z "$line" ]] && continue            # Skip empty lines

    if [[ "$line" =~ ^@ ]]; then
      groups+=("${line:1}")
    elif [[ "$line" == *"*"* ]]; then
      wildcards+=("$line")
    else
      packages+=("$line")
    fi
  done < "$list_file"

  if [[ ${#groups[@]} -gt 0 ]]; then
    log_info "➡ Installing DNF groups: ${groups[*]}"
    try_cmd "Installing groups" sudo dnf groupinstall -y "${groups[@]}"
  fi

  if [[ ${#packages[@]} -gt 0 ]]; then
    log_info "➡ Installing packages: ${packages[*]}"
    try_cmd "Installing packages" sudo dnf install -y "${packages[@]}"
  fi

  if [[ "$enable_wildcards" == "true" && ${#wildcards[@]} -gt 0 ]]; then
    log_info "🔍 Expanding wildcards: ${wildcards[*]}"
    local matches=()
    for pattern in "${wildcards[@]}"; do
      mapfile -t result < <(dnf list --available "$pattern" 2>/dev/null | awk '/^\S/ {print $1}' | cut -d. -f1)
      matches+=("${result[@]}")
    done

    if [[ ${#matches[@]} -gt 0 ]]; then
      log_info "➡ Installing expanded wildcard matches: ${matches[*]}"
      try_cmd "Installing wildcard matches" sudo dnf install -y "${matches[@]}"
    else
      log_warn "⚠️ No matches found for wildcards."
    fi
  else
    log_info "ℹ️ Wildcard expansion disabled or no wildcards present."
  fi

  log_success "✓ Completed list installation: $list_file"
}
