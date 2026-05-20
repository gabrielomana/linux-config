#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
trap 'echo -e "\n■ [ERROR] Ocurrió un fallo en la línea $LINENO del script. Abortando."; exit 1' ERR

# ──────────────────────────────────────────────────────────────────────────────
# SCRIPT 1: FEDORA 42+ CLI SYSTEM CORE, HARDENING & HARDWARE OPTIMIZATION
# ──────────────────────────────────────────────────────────────────────────────
# Autor: Gabriel Omaña – Initium | https://initiumsoft.com
# Descripción: Prepara un búnker CLI optimizado desde la ISO Everything.
#              Aplica seguridad de red, hotswap Btrfs y microcódigo de CPU.
# Compatible con: Fedora Workstation / Server 42+ (Btrfs Obligatorio)
# ──────────────────────────────────────────────────────────────────────────────

# === [1. VARIABLES GLOBALES Y CONFIGURACIÓN DE RUTAS] ===
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$REAL_USER")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$USER_HOME/fedora_logs"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="$LOG_DIR/system_core_$TIMESTAMP.log"
ERR_FILE="$LOG_DIR/system_core_error_$TIMESTAMP.log"
ERROR_COUNT=0

# Lista híbrida consolidada (Contingencia CLI de alto rendimiento)
declare -a FALLBACK_PACKAGES=(
  vim nano git curl wget htop fastfetch unzip p7zip p7zip-plugins tar gzip bzip2 zsh bash-completion
  firewalld policycoreutils policycoreutils-python-utils openssh-clients fail2ban rclone
  bat jq ripgrep fd-find eza cpuid cpu-x npm python3-pip pipx
)

# === [2. CONFIGURACIÓN DE COLORES CON DETECCIÓN DE TTY] ===
setup_colors() {
  if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
    RED=$(tput setaf 1)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 3)
    BLUE=$(tput setaf 4)
    CYAN=$(tput setaf 6)
    BOLD=$(tput bold)
    NC=$(tput sgr0)
  else
    RED=""; GREEN=""; YELLOW=""; BLUE=""; CYAN=""; BOLD=""; NC=""
  fi
}
setup_colors

# === [3. UTILIDADES DE LOGGING Y UX VISUAL] ===
log_info() {
  local msg="$1"
  printf "${BLUE}%-65s %s${NC}\n" "[INFO] $msg" "[OK]"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $msg" >> "$LOG_FILE"
}

log_success() {
  local msg="$1"
  printf "${GREEN}%-65s %s${NC}\n" "[✔ SUCCESS] $msg" "[OK]"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $msg" >> "$LOG_FILE"
}

log_warn() {
  local msg="$1"
  printf "${YELLOW}%-65s %s${NC}\n" "[⚠ WARNING] $msg" "[WARN]"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [WARNING] $msg" | tee -a "$LOG_FILE" >> "$ERR_FILE"
  ERROR_COUNT=$((ERROR_COUNT + 1))
}

log_error() {
  local msg="$1"
  printf "${RED}%-65s %s${NC}\n" "[❌ ERROR] $msg" "[FAIL]"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $msg" | tee -a "$LOG_FILE" >> "$ERR_FILE"
  ERROR_COUNT=$((ERROR_COUNT + 1))
}

log_section() {
  local title="$1"
  local clean_title="${title//[$'\t\r\n']}"
  local border=$(printf '─%.0s' $(seq 1 $(( ${#clean_title} + 4 ))))

  echo -e "\n${BLUE}┌$border┐${NC}"
  echo -e "${BLUE}│  ${BOLD}${clean_title}${NC}${BLUE}  │${NC}"
  echo -e "${BLUE}└$border┘${NC}\n"

  if [[ -n "${LOG_FILE:-}" && -f "$LOG_FILE" ]]; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] $title" >> "$LOG_FILE"
  fi
}

draw_progress_bar() {
  local current=$1 total=$2 width=40
  local percent=$(( current * 100 / total ))
  local filled=$(( current * width / total ))
  local empty=$(( width - filled ))
  local progress_bar

  progress_bar=$(printf "%-${filled}s" "#" | tr ' ' '#')
  progress_bar+=$(printf "%-${empty}s" "-" | tr ' ' '-')
  
  printf "\r[%s] %3d%% (%d/%d)" "$progress_bar" "$percent" "$current" "$total"
  [[ "$current" -eq "$total" ]] && echo ""
}

check_error() {
  local msg="${1:-Ocurrió un error}" code="${2:-$?}"
  if [[ "$code" -ne 0 ]]; then log_error "$msg"; return "$code"; fi
}

# === [4. COMPROBACIONES TÉCNICAS Y PRIVILEGIOS] ===
run_sudo() {
  if ! sudo -n true 2>/dev/null; then
    log_info "Elevando temporalmente privilegios a sudo..."
    sudo -v || { log_error "No se pudieron obtener credenciales de administrador"; exit 1; }
  fi
  if [[ -z "${DISABLE_SUDO_KEEPALIVE:-}" ]]; then
    ( while sudo -n true 2>/dev/null; do sleep 50; done ) &
    SUDO_PID=$!
    trap "kill -9 $SUDO_PID 2>/dev/null || true" EXIT
  fi
}

init_environment() {
  if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}❌ Error crítico: Este script debe lanzarse bajo sudo.${NC}" >&2
    exit 1
  fi

  mkdir -p "$LOG_DIR"
  touch "$LOG_FILE" "$ERR_FILE"
  chmod 664 "$LOG_FILE" "$ERR_FILE"
  chown "$REAL_USER:$REAL_USER" "$LOG_FILE" "$ERR_FILE" 2>/dev/null || true

  exec > >(tee >(grep --line-buffered -E "^\[|^\s*\[.*\]" >> "$LOG_FILE") > /dev/tty) \
       2> >(tee >(grep --line-buffered -E "^\[⚠|\[❌" >> "$ERR_FILE") > /dev/tty)

  log_info "👤 Operando en la cuenta de: $REAL_USER"
  log_info "📁 Bitácora de instalación asignada en: $LOG_DIR"

  local required_mb=5000
  local available_kb=$(df --output=avail "$LOG_DIR" | tail -n1 | tr -d ' ')
  local required_kb=$((required_mb * 1024))
  if [[ "$available_kb" -lt "$required_kb" ]]; then
    log_error "Almacenamiento insuficiente en disco. Requeridos al menos ${required_mb}MB."
    exit 1
  fi
}

# === [5. INTERFACES DE USUARIO Y MEJORAS DE UX] ===
show_welcome_banner() {
  clear
  local kernel_rel=$(uname -r)
  local fedora_ver=$(rpm -E %fedora)

  echo -e ""
  echo -e "${BLUE}${BOLD}    __         _                 ${NC}    ${BOLD}${BLUE}${REAL_USER}${NC}@${BOLD}${BLUE}${HOSTNAME}${NC}"
  echo -e "${BLUE}${BOLD}   / _|       | |                ${NC}    ${YELLOW}-------------------${NC}"
  echo -e "${BLUE}${BOLD}  | |_ ___  __| | ___  _ __ __ _ ${NC}    ${BOLD}${CYAN}OS:${NC} Fedora Linux ${fedora_ver} Minimal"
  echo -e "${BLUE}${BOLD}  |  _/ _ \\/ _\` |/ _ \\| '__/ _\` |${NC}    ${BOLD}${CYAN}KERNEL:${NC} ${kernel_rel}"
  echo -e "${BLUE}${BOLD}  | ||  __/ (_| | (_) | | | (_| |${NC}    ${BOLD}${CYAN}SUITE:${NC} HARDENING & CLI CORE"
  echo -e "${BLUE}${BOLD}  |_| \\___|\\__,_|\\___/|_|  \\__,_|${NC}    ${BOLD}${CYAN}AUTHOR:${NC} gabrielomana"
  echo -e ""
  echo -e "${YELLOW}===================================================================${NC}"
  echo -e "   ${BOLD}${BLUE}SUITE DE RECONFIGURACIÓN DE NÚCLEO - INICIO DEL PROCESO${NC}"
  echo -e "${YELLOW}===================================================================${NC}"
  echo -e " El asistente automatizará las tareas iniciales en modo consola:"
  echo -e "  1. Tuning fino de DNF (Descargas Paralelas a 10 y espejos rápidos)."
  echo -e "  2. Inyección de Herramientas de Compilación, Motores Dev y Utilidades CLI."
  echo -e "  3. Despliegue de Seguridad Avanzada (Fail2ban, SSHD en 2222, DNS-over-TLS)."
  echo -e "  4. Inyección de parches de Microcódigo de CPU según fabricante (Intel/AMD)."
  echo -e "  5. Remodelación estructural de particiones Btrfs para soporte de Timeshift."
  echo -e "${YELLOW}-------------------------------------------------------------------${NC}"
  echo -ne "${BLUE}¿Deseas iniciar la automatización del Core del sistema ahora? (s/N): ${NC}" > /dev/tty
  read -r proceed < /dev/tty
  if [[ ! "$proceed" =~ ^[Ss]$ ]]; then
    echo -e "${RED}» Proceso cancelado. Saliendo sin alterar el sistema.${NC}"
    exit 0
  fi
}

change_hostname() {
  clear
  log_section "🖥️ Identidad del Sistema (Hostname Setup)"
  
  local default_hostname="hal9k"
  local hostname_var=""

  if [[ -t 0 ]]; then
    echo -e "${YELLOW}Asigna el identificador de red para este equipo.${NC}"
    echo -ne "${BLUE}Introduce el nuevo hostname [Por defecto: $default_hostname]: ${NC}" > /dev/tty
    read -r hostname_var < /dev/tty
  fi

  if [[ -z "$hostname_var" ]]; then
    hostname_var="$default_hostname"
    log_info "Campo vacío detectado. Aplicando sugerencia automática: $hostname_var"
  fi

  if [[ "$hostname_var" =~ ^[a-zA-Z0-9][-a-zA-Z0-9]{0,61}[a-zA-Z0-9]$ ]]; then
    sudo hostnamectl set-hostname --static "$hostname_var"
    log_success "Nombre de host estático cambiado correctamente a: $hostname_var"
  else
    log_error "El nombre '$hostname_var' no cumple con la norma RFC1123. Se salta el paso."
  fi
  sleep 1.5
}

explain_btrfs_and_cpu_phase() {
  clear
  log_section "🧬 Fase Core: Almacenamiento Btrfs y Estabilidad CPU"
  echo -e "${YELLOW}FASE CRÍTICA: Optimizaciones nucleares del sistema...${NC}"
  echo -e "A continuación, el script blindará las capas más profundas del sistema operativo:"
  echo -e ""
  echo -e " 1. ${BOLD}Microcódigo de la CPU:${NC} Detectará si tu procesador es Intel o AMD"
  echo -e "    e inyectará los parches de hardware directo en el initramfs."
  echo -e " 2. ${BOLD}Cirugía Btrfs:${NC} Moverá las entradas raíz a la nomenclatura '@' y '@home'"
  echo -e "    dejando la máquina lista para snapshots en el GRUB con Timeshift."
  echo -e ""
  echo -e "${GREEN}El procedimiento es 100% seguro. Se generará una pausa para Dracut.${NC}"
  echo -e "${YELLOW}-------------------------------------------------------------------${NC}"
  echo -e "Presiona cualquier tecla para iniciar el procesamiento físico..."
  read -n 1 -s -r < /dev/tty
}

# === [6. OPTIMIZACIÓN DEL GESTOR DE SOFTWARE] ===
configure_dnf() {
  log_section "⚙️ Sintonización Fina de Parámetros DNF"
  
  # INTEGRACIÓN QUIRÚRGICA: CONFIGURACIÓN RTC EN HORA LOCAL PARA COMPATIBILIDAD CON WINDOWS (DUAL-BOOT)
  sudo timedatectl set-local-rtc 1 --adjust-system-clock &>/dev/null || log_warn "Imposible setear RTC local"

  local dnf_conf="/etc/dnf/dnf.conf"
  sudo cp "$dnf_conf" "$dnf_conf.bak" 2>/dev/null || true
  
  sudo tee "$dnf_conf" > /dev/null <<EOF
[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
fastestmirror=True
max_parallel_downloads=10
defaultyes=True
keepcache=True
deltarpm=True
EOF
  log_success "DNF sintonizado correctamente: Descargas simultáneas elevadas a 10"
}

configure_dnf_automatic() {
  log_section "🛠️ Automatización de Parches de Seguridad"
  sudo dnf install -y dnf-automatic
  sudo cp /usr/lib/systemd/system/dnf-automatic.timer /etc/systemd/system/
  sudo systemctl enable --now dnf-automatic.timer
  log_success "Actualizaciones automáticas de seguridad habilitadas mediante Systemd Timers"
}

configure_repositories() {
  log_section "🌐 Suministro de Repositorios Esenciales"
  log_info "Instalando repositorios libres y no libres de RPM Fusion..."
  sudo dnf install -y \
    "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
  log_success "Repositorios RPM Fusion vinculados con éxito al árbol de paquetes"
}

install_essential_packages() {
  log_section "📦 Aprovisionamiento de Utilidades Base y Motores de Desarrollo"
  
  local list_file="${SCRIPT_DIR}/sources/lists/cli_tools.list"
  local -a packages_to_install=()

  if [[ -f "$list_file" ]]; then
    log_info "Leyendo archivo modular de paquetes: $(basename "$list_file")"
    mapfile -t raw_lines < "$list_file"
    for line in "${raw_lines[@]}"; do
      local clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
      [[ -z "$clean_line" ]] && continue
      packages_to_install+=("$clean_line")
    done
  else
    log_warn "Archivo modular 'cli_tools.list' no hallado. Cargando lista de contingencia integrada."
    packages_to_install=("${FALLBACK_PACKAGES[@]}")
  fi

  log_info "→ Incorporando grupos de desarrollo: development-tools y c-development"
  sudo dnf group install -y --allowerasing --skip-broken --setopt=skip_if_unavailable=true "development-tools" "c-development" &>> "$LOG_FILE"

  local total=${#packages_to_install[@]}
  for i in "${!packages_to_install[@]}"; do
    local pkg="${packages_to_install[$i]}"
    log_info "→ Aprovisionando paquete: $pkg"
    sudo dnf install -y --allowerasing --skip-broken --setopt=skip_if_unavailable=true "$pkg" &>> "$LOG_FILE"
    draw_progress_bar "$((i + 1))" "$total"
  done
  log_success "Herramientas CLI, compiladores y gestores dev (npm/pipx) integrados con éxito"
}

configure_flatpak_repositories() {
  log_section "📦 Activación del Sub-sistema de Paquetería Flatpak"
  sudo dnf install -y flatpak
  
  declare -A flatpak_remotes=(
    [flathub]="https://flathub.org/repo/flathub.flatpakrepo"
    [kde]="https://distribute.kde.org/kdeapps.flatpakrepo"
  )
  
  local i=0 total=${#flatpak_remotes[@]}
  for remote in flathub kde; do
    local url="${flatpak_remotes[$remote]}"
    sudo flatpak remote-add --if-not-exists --from "$remote" "$url" &>/dev/null
    sudo flatpak remote-modify --system --prio=$((++i)) "$remote" &>/dev/null
    draw_progress_bar "$i" "$total"
  done
  log_success "Motor Flatpak aprovisionado y ordenado por prioridades de búsqueda"
}

# === [7. DEFENSAS, SEGURIDAD Y PRIVACIDAD EN RED] ===
configure_security() {
  log_section "🔐 Blindaje Perimetral de Red y Privacidad DNS"
  
  sudo systemctl enable --now firewalld &>/dev/null
  sudo firewall-cmd --set-default-zone=FedoraWorkstation

  # INTEGRACIÓN QUIRÚRGICA: APERTURA DE PUERTOS DE SERVICIOS COMPARTIDOS HETEROGÉNEOS HEREDADOS
  log_info "Inyectando reglas corporativas de puertos en Firewalld..."
  sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=mdns &>> "$LOG_FILE" || true
  sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service=bluetooth &>> "$LOG_FILE" || true
  sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port=32400/tcp &>> "$LOG_FILE" || true  # Plex Media Server
  sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port=1714-1764/tcp &>> "$LOG_FILE" || true # KDE Connect TCP
  sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port=1714-1764/udp &>> "$LOG_FILE" || true # KDE Connect UDP
  sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port=3389/tcp &>> "$LOG_FILE" || true   # Remote Desktop Protocol (RDP)
  sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port=22000/tcp &>> "$LOG_FILE" || true  # Syncthing Transmisión

  log_info "Configurando mitigación de rastreo ISP mediante DNS-over-TLS (AdGuard + Cloudflare)..."
  sudo mkdir -p /etc/systemd/resolved.conf.d
  sudo tee /etc/systemd/resolved.conf.d/99-dns-over-tls.conf > /dev/null <<EOF
[Resolve]
DNS=94.140.14.14 94.140.15.15 1.1.1.1
DNSOverTLS=yes
EOF
  sudo systemctl restart systemd-resolved &>/dev/null

  sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
  log_success "Firewall establecido, mitigación de rastreo ISP (DoT) y SELinux forzado"
}

configure_network_security() {
  log_section "🌐 Endurecimiento y Ofuscación del Servicio SSHD"
  sudo systemctl enable --now fail2ban &>/dev/null

  log_info "Configurando jaula fail2ban personalizada para puerto 2222..."
  sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[sshd]
enabled = true
port    = 2222
logpath = /var/log/secure
maxretry = 3
bantime = 1h
EOF
  sudo systemctl restart fail2ban

  local ssh_config="/etc/ssh/sshd_config"
  sudo cp "$ssh_config" "$ssh_config.bak" 2>/dev/null || true
  sudo sed -i -E 's/^#?\s*Port\s+.*/Port 2222/' "$ssh_config"
  sudo sed -i -E 's/^#?\s*PermitRootLogin\s+.*/PermitRootLogin no/' "$ssh_config"
  sudo sed -i -E 's/^#?\s*PasswordAuthentication\s+.*/PasswordAuthentication no/' "$ssh_config"

  if sudo sshd -t; then
    sudo semanage port -a -t ssh_port_t -p tcp 2222 2>/dev/null || sudo semanage port -m -t ssh_port_t -p tcp 2222 2>/dev/null || true
    sudo systemctl restart sshd
    log_success "SSH reconfigurado de forma segura en puerto 2222 (Acceso root bloqueado)"
  else
    sudo cp "$ssh_config.bak" "$ssh_config"
    sudo systemctl restart sshd
    log_warn "Sintaxis errónea en SSH. Se restauró el respaldo preventivo."
  fi

  # RESTRICCIÓN PERIMETRAL: REGLA RICA EN FIREWALL PARA ADMITIR ACCESO SSH EXCLUSIVO EN LAN LOCAL
  log_info "Asegurando Rich Rule perimetral para restringir SSH al segmento local..."
  sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="2222" protocol="tcp" accept' &>> "$LOG_FILE" || true
  sudo firewall-cmd --permanent --zone=FedoraWorkstation --remove-service=ssh &>> "$LOG_FILE" || true
  sudo firewall-cmd --reload &>> "$LOG_FILE" || true
}

# === [8. SUBSISTEMA DE HARDWARE: MICROCODIGO DE CPU] ===
configure_cpu_hardware() {
  log_section "🧠 Mitigación de Errores de CPU: Inyección de Microcódigo"

  local hypervisor=$(systemd-detect-virt)
  if [[ "$hypervisor" != "none" ]]; then
    log_info "Máquina Virtual detectada ($hypervisor). Se omite la inyección de microcódigo físico."
    return 0
  fi

  local cpu_name=$(lscpu | grep -Ei 'Model name|Nombre del modelo' | head -n 1)
  log_info "Procesador físico detectado: ${cpu_name:-Desconocido}"

  if echo "$cpu_name" | grep -qi "intel"; then
    log_info "🧬 Procesador Intel identificado. Applying patches via 'microcode_ctl'..."
    sudo dnf install -y --enablerepo=rpmfusion-nonfree microcode_ctl &>> "$LOG_FILE"
    log_success "Microcódigo de Intel inyectado correctamente."
  elif echo "$cpu_name" | grep -qi "amd"; then
    log_info "🧬 Procesador AMD identificado. Applying patches via 'amd-ucode'..."
    sudo dnf install -y --enablerepo=rpmfusion-nonfree amd-ucode &>> "$LOG_FILE"
    log_info "Regenerando initramfs para forzar la carga temprana de parches AMD (Pausa corta)..."
    sudo dracut -f &>> "$LOG_FILE"
    log_success "Microcódigo de AMD inyectado e initramfs actualizado."
  else
    log_warn "Fabricante de CPU no homologado. Se omite la inyección automatizada."
  fi
}

# === [9. CIRUGÍA FÍSICA DE PARTICIONES BTRFS] ===
configure_btrfs_volumes() {
  local fs_type=$(findmnt -n -o FSTYPE /)
  if [[ "$fs_type" != "btrfs" ]]; then
    log_warn "El sistema de archivos actual no es BTRFS. Omitiendo cirugía de disco."
    return 0
  fi

  sudo dnf install -y btrfs-progs inotify-tools &>> "$LOG_FILE"
  local root_device=$(findmnt -n -o SOURCE /)
  local uuid=$(findmnt -n -o UUID /)
  local tmp_mnt="/tmp/btrfs_toplevel_surgery"

  sudo mkdir -p "$tmp_mnt"
  sudo mount -o subvolid=5 "$root_device" "$tmp_mnt"
  check_error "Imposible acceder a la raíz del volumen Btrfs (ID 5)"

  if [[ -d "$tmp_mnt/root" && ! -d "$tmp_mnt/@" ]]; then
    log_warn "Estructura estándar detectada (root). Clonando de forma transparente a (@)..."
    sudo btrfs subvolume snapshot "$tmp_mnt/root" "$tmp_mnt/@"
    check_error "Fallo de clonación en subvolumen raíz"
  fi

  if [[ -d "$tmp_mnt/home" && ! -d "$tmp_mnt/@home" ]]; then
    log_info "Clonando subvolumen de datos de usuario a (@home)..."
    sudo btrfs subvolume snapshot "$tmp_mnt/home" "$tmp_mnt/@home"
    check_error "Fallo de clonación en subvolumen home"
  fi

  declare -A subvolumes=(
    ["/"]="@"
    ["/var/log"]="@log"
    ["/var/tmp"]="@var_tmp"
    ["/.snapshots"]="@timeshift"
  )

  for mount_point in "${!subvolumes[@]}"; do
    local subvol_name="${subvolumes[$mount_point]}"
    if [[ ! -d "$tmp_mnt/$subvol_name" ]]; then
      log_info "➕ Creando subvolumen ausente en la tabla: $subvol_name"
      sudo btrfs subvolume create "$tmp_mnt/$subvol_name" &>> "$LOG_FILE"
    fi
  done

  sudo umount "$tmp_mnt"
  sudo rm -rf "$tmp_mnt"

  log_info "🔐 Reconfigurando fstab bajo directivas óptimas de almacenamiento de estado sólido"
  sudo cp /etc/fstab /etc/fstab.bak
  sudo sed -i -E '/\s+(\/|\/var\/log|\/var\/tmp|\/\.snapshots)\s+btrfs/d' /etc/fstab

  for mount_point in "${!subvolumes[@]}"; do
    echo "UUID=$uuid $mount_point btrfs rw,noatime,compress=zstd:3,space_cache=v2,subvol=${subvolumes[$mount_point]} 0 0" | sudo tee -a /etc/fstab > /dev/null
  done

  log_info "⚙️ Forzando remapeo de subvolúmenes en los argumentos de booteo (BLS & GRUB)..."
  if [[ -f "/etc/kernel/cmdline" ]]; then
    sudo sed -i 's/rootflags=subvol=root/rootflags=subvol=@/g' /etc/kernel/cmdline
  fi
  if [[ -d "/boot/loader/entries" ]]; then
    sudo sed -i 's/rootflags=subvol=root/rootflags=subvol=@/g' /boot/loader/entries/*.conf
  fi
  sudo sed -i 's/rootflags=subvol=root/rootflags=subvol=@/g' /etc/default/grub 2>/dev/null || true

  log_success "Topología Btrfs actualizada y configurada hacia la nomenclatura (@)"
}

# === [ 10. CONTROL DE EJECUCIÓN PRINCIPAL ] ===
main() {
  init_environment
  run_sudo
  
  show_welcome_banner
  
  configure_dnf
  configure_dnf_automatic
  change_hostname
  configure_repositories
  install_essential_packages
  configure_flatpak_repositories
  configure_security
  configure_network_security
  
  explain_btrfs_and_cpu_phase
  configure_cpu_hardware
  configure_btrfs_volumes

  clear
  log_section "🧼 Saneamiento y Depuración de Residuos"
  log_info "Eliminando dependencias huérfanas y liberando cachés..."
  sudo dnf autoremove -y &>> "$LOG_FILE"
  sudo dnf clean all &>> "$LOG_FILE"

  log_success "🎉 SCRIPT 1 COMPLETADO: El núcleo CLI de tu Fedora está blindado y optimizado."
  log_warn "🚨 NOTA: Se requiere reiniciar para que el Kernel monte el nuevo microcódigo y volumen (@)."
  
  echo -ne "${YELLOW}¿Deseas reiniciar el sistema operativo en este instante? (s/n): ${NC}" > /dev/tty
  read -r choice < /dev/tty
  if [[ "$choice" =~ ^[Ss]$ ]]; then
    sudo reboot
  fi
}

main "$@"
exit 0