#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
trap 'echo -e "\n■ [ERROR] Ocurrió un fallo en la línea $LINENO del script. Abortando."; exit 1' ERR

# ──────────────────────────────────────────────────────────────────────────────
# SCRIPT 2: FEDORA KDE PLASMA, DRIVERS, CODECS, FONTS & TIMESHIFT BTRFS
# ──────────────────────────────────────────────────────────────────────────────

# === [1. VARIABLES GLOBALES Y RUTAS] ===
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$REAL_USER")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$USER_HOME/fedora_logs"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="$LOG_DIR/kde_desktop_$TIMESTAMP.log"
ERR_FILE="$LOG_DIR/kde_desktop_error_$TIMESTAMP.log"

SRC_PERSIST_DIR="$USER_HOME/.local/src"

LIST_PLASMA="$SCRIPT_DIR/sources/lists/kde_plasma.list"
LIST_APPS="$SCRIPT_DIR/sources/lists/kde_plasma_apps.list"
LIST_CODECS="$SCRIPT_DIR/sources/lists/codecs.list"
LIST_FONTS="$SCRIPT_DIR/sources/lists/fonts.list"

setup_colors() {
  if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1) GREEN=$(tput setaf 2) YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4) CYAN=$(tput setaf 6) BOLD=$(tput bold) NC=$(tput sgr0)
  else
    RED="" GREEN="" YELLOW="" BLUE="" CYAN="" BOLD="" NC=""
  fi
}
setup_colors

log_info() { printf "${BLUE}%-65s %s${NC}\n" "[INFO] $1" "[OK]"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_FILE"; }
log_success() { printf "${GREEN}%-65s %s${NC}\n" "[✔ SUCCESS] $1" "[OK]"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> "$LOG_FILE"; }
log_warn() { printf "${YELLOW}%-65s %s${NC}\n" "[⚠ WARNING] $1" "[WARN]"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1" | tee -a "$LOG_FILE" >> "$ERR_FILE"; }
log_error() { printf "${RED}%-65s %s${NC}\n" "[❌ ERROR] $1" "[FAIL]"; echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" | tee -a "$LOG_FILE" >> "$ERR_FILE"; exit 1; }

log_section() {
  local clean_title="${1//[$'\t\r\n']}"
  local border=$(printf '─%.0s' $(seq 1 $(( ${#clean_title} + 4 ))))
  echo -e "\n${BLUE}┌$border┐\n│  ${BOLD}${clean_title}${NC}${BLUE}  │\n└$border┘${NC}\n"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] $1" >> "$LOG_FILE"
}

check_error() { [[ "$2" -ne 0 ]] && log_error "$1"; }

run_sudo() {
  if ! sudo -n true 2>/dev/null; then
    log_info "Elevando privilegios a sudo..."
    sudo -v || log_error "No se obtuvieron credenciales de administrador"
  fi
  if [[ -z "${DISABLE_SUDO_KEEPALIVE:-}" ]]; then
    ( while sudo -n true 2>/dev/null; do sleep 50; done ) &
    trap "kill -9 $! 2>/dev/null || true" EXIT
  fi
}

init_environment() {
  [[ $EUID -ne 0 ]] && { echo -e "${RED}❌ Error: Debe ejecutarse bajo sudo.${NC}"; exit 1; }
  mkdir -p "$LOG_DIR"
  touch "$LOG_FILE" "$ERR_FILE"
  chmod 664 "$LOG_FILE" "$ERR_FILE"
  chown "$REAL_USER:$REAL_USER" "$LOG_FILE" "$ERR_FILE" 2>/dev/null || true
  exec > >(tee >(grep --line-buffered -E "^\[|^\s*\[.*\]" >> "$LOG_FILE") > /dev/tty) \
       2> >(tee >(grep --line-buffered -E "^\[⚠|\[❌" >> "$ERR_FILE") > /dev/tty)
}

show_welcome_banner() {
  clear
  local kernel_rel=$(uname -r)
  local fedora_ver=$(rpm -E %fedora)
  echo -e "${BLUE}${BOLD}PHASE 2: GRÁFICOS & HARDWARE${NC}"
  echo -e "${YELLOW}===================================================================${NC}"
  echo -ne "${BLUE}¿Deseas iniciar la ejecución de la Fase 2 ahora? (s/N): ${NC}" > /dev/tty
  read -r proceed < /dev/tty
  [[ ! "$proceed" =~ ^[Ss]$ ]] && exit 0
}

setup_persistent_src_dir() {
  log_section "📁 Preparación de Almacenamiento Git Persistente"
  mkdir -p "$SRC_PERSIST_DIR"
  chown -R "$REAL_USER:$REAL_USER" "$SRC_PERSIST_DIR"
  log_success "Directorio de fuentes asegurado."
}

configure_extra_repos() {
  log_section "🌐 Activando Repositorios de Software de Terceros"
  
  sudo dnf install -y dnf-plugins-core &>> "$LOG_FILE"
  
  log_info "Añadiendo repositorio: Brave Browser..."
  sudo dnf config-manager --add-repo=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo &>> "$LOG_FILE" || true
  sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc &>> "$LOG_FILE" || true

  log_info "Añadiendo repositorio: Visual Studio Code..."
  sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc &>> "$LOG_FILE" || true
  cat <<EOF | sudo tee /etc/yum.repos.d/vscode.repo &> /dev/null
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

  log_info "Añadiendo repositorio oficial de ONLYOFFICE..."
  sudo tee /etc/yum.repos.d/onlyoffice.repo > /dev/null <<EOF
[onlyoffice]
name=onlyoffice repo
baseurl=http://download.onlyoffice.com/repo/centos/main/noarch/
gpgcheck=1
gpgkey=http://download.onlyoffice.com/GPG-KEY-ONLYOFFICE
enabled=1
EOF

  # INTEGRACIÓN QUIRÚRGICA: INYECCIÓN DE REPOSITORIOS COPR ADICIONALES DE VERSIONES ANTERIORES (APPIMAGELAUNCHER, PERSONAL, HBLOCK)
  log_info "Añadiendo repositorios COPR (WebApp Manager, Ubuntu Fonts, AppImageLauncher, Personal y hblock)..."
  sudo dnf copr enable -y refi64/webapp-manager &>> "$LOG_FILE" || true
  sudo dnf copr enable -y atim/ubuntu-fonts &>> "$LOG_FILE" || true
  sudo dnf copr enable -y pses/appimagelauncher &>> "$LOG_FILE" || true
  sudo dnf copr enable -y ayoungdukie/Personal_Repo &>> "$LOG_FILE" || true
  sudo dnf copr enable -y hectorm/hblock &>> "$LOG_FILE" || true
  
  # INTEGRACIÓN QUIRÚRGICA: AMPLIACIÓN COBERTA REGISTROS REMOTOS MOTOR FLATPAK (FEDORA OCI + ELEMENTARY APPCENTER)
  log_info "Inyectando orquestación avanzada de remotos del motor Flatpak..."
  sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo &>> "$LOG_FILE" || true
  sudo flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org &>> "$LOG_FILE" || true
  sudo flatpak remote-add --if-not-exists appcenter https://flatpak.elementary.io/repo.flatpakrepo &>> "$LOG_FILE" || true

  log_success "Repositorios de terceros configurados e importados de forma exhaustiva."
}

configure_gpu_hardware() {
  log_section "🛠️ Detección de Hardware Gráfico"
  local gpu_info=$(lspci | grep -iE "VGA|3D controller")
  if echo "$gpu_info" | grep -qi "Intel"; then
    sudo dnf install -y intel-media-driver vdpau-driver-all &>> "$LOG_FILE"
  elif echo "$gpu_info" | grep -qi "AMD"; then
    sudo dnf install -y akmod-amdgpu mesa-va-drivers-freeworld mesa-vdpau-drivers-freeworld vdpau-driver-all &>> "$LOG_FILE"
  elif echo "$gpu_info" | grep -qi "NVIDIA"; then
    sudo dnf install -y akmod-nvidia nvidia-driver nvidia-settings nvidia-vaapi-driver vdpau-driver-all &>> "$LOG_FILE"
    sudo grubby --update-kernel=ALL --args='nvidia-drm.modeset=1' &>> "$LOG_FILE"
  fi
  log_success "Controladores gráficos procesados."
}

install_packages_from_lists() {
  log_section "📦 Instalación Segura Tri-Fase: Lectura de Listas Modulares"
  local standard_pkgs=() wildcard_pkgs=() group_pkgs=()
  parse_list() {
    local file_path="$1"
    if [[ -f "$file_path" ]]; then
      while IFS= read -r line || [[ -n "$line" ]]; do
        local clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
        [[ -z "$clean_line" ]] && continue
        if [[ "$clean_line" == @* ]]; then group_pkgs+=("${clean_line#@}");
        elif [[ "$clean_line" == *'*'* ]]; then wildcard_pkgs+=("$clean_line");
        else standard_pkgs+=("$clean_line"); fi
      done < "$file_path"
    fi
  }

  local lists_to_process=("$LIST_PLASMA" "$LIST_APPS" "$LIST_CODECS" "$LIST_FONTS")
  for list_file in "${lists_to_process[@]}"; do parse_list "$list_file"; done

  if [ ${#standard_pkgs[@]} -gt 0 ]; then
    IFS=$'\n' sorted_standard=($(sort -u <<<"${standard_pkgs[*]}"))
    IFS=$'\n\t'
    sudo dnf install -y --allowerasing --skip-broken --setopt=skip_if_unavailable=true "${sorted_standard[@]}" &>> "$LOG_FILE"
  fi

  for w_pkg in "${wildcard_pkgs[@]:-}"; do
    sudo dnf install -y --skip-broken --setopt=skip_if_unavailable=true "$w_pkg" &>> "$LOG_FILE" || true
  done

  for g_pkg in "${group_pkgs[@]:-}"; do
    sudo dnf group install -y --skip-broken --setopt=skip_if_unavailable=true "$g_pkg" &>> "$LOG_FILE" || true
  done
  log_success "Software de las listas procesado."
}

install_external_fonts() {
  log_section "🔤 Despliegue de Tipografías Externas (NerdFonts)"
  local font_dir="$USER_HOME/.local/share/fonts"
  sudo -u "$REAL_USER" mkdir -p "$font_dir"
  curl -Ls -o /tmp/JetBrainsMono.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
  sudo -u "$REAL_USER" unzip -q -o /tmp/JetBrainsMono.zip -d "$font_dir" && rm -f /tmp/JetBrainsMono.zip
  curl -Ls -o /tmp/UbuntuNF.zip "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Ubuntu.zip"
  sudo -u "$REAL_USER" unzip -q -o /tmp/UbuntuNF.zip -d "$font_dir" && rm -f /tmp/UbuntuNF.zip
  sudo fc-cache -fv &>> "$LOG_FILE"
  log_success "Ecosistema tipográfico externo desplegado."
}

configure_timeshift_and_grub() {
  log_section "🔄 Infraestructura de Snapshots (Timeshift & Grub-Btrfs)"
  local uuid=$(findmnt -n -o UUID /)
  sudo mkdir -p /etc/timeshift /.snapshots
  sudo tee /etc/timeshift/timeshift.json > /dev/null <<EOF
{
  "backup_device_uuid" : "${uuid}",
  "btrfs_mode" : "true",
  "schedule_multiple" : "true",
  "schedule_d" : "true",
  "count_d" : "5"
}
EOF
  local target_dir="$SRC_PERSIST_DIR/grub-btrfs"
  sudo -u "$REAL_USER" rm -rf "$target_dir"
  sudo -u "$REAL_USER" git clone --depth=1 "https://github.com/Antynea/grub-btrfs.git" "$target_dir" &>> "$LOG_FILE"
  pushd "$target_dir" >/dev/null
  sed -i 's|/boot/grub/|/boot/grub2/|g' Makefile
  sed -i 's|/boot/grub|/boot/grub2|g' Makefile
  export GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"
  sudo make install &>> "$LOG_FILE"
  sudo systemctl enable --now grub-btrfsd.service &>> "$LOG_FILE"
  popd >/dev/null
  log_success "Infraestructura Grub-Btrfs acoplada perfectamente."
}

generate_initial_snapshot() {
  log_section "📸 Creación del Snapshot 0 (Clean Desktop Install)"
  sudo systemctl enable sddm &>> "$LOG_FILE"
  sudo systemctl set-default graphical.target &>> "$LOG_FILE"
  sudo timeshift --create --comments "Fedora KDE Clean Desktop (Snapshot 0)" --tags D &>> "$LOG_FILE"
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg &>> "$LOG_FILE"
  log_success "Snapshot Cero anclado con éxito."
}

main() {
  init_environment
  run_sudo
  show_welcome_banner
  setup_persistent_src_dir
  configure_extra_repos
  configure_gpu_hardware
  install_packages_from_lists
  install_external_fonts
  configure_timeshift_and_grub
  generate_initial_snapshot
  clear
  sudo dnf clean all &>> "$LOG_FILE"
  sync
  log_success "SCRIPT 2 FINALIZADO."
}
main "$@"
exit 0