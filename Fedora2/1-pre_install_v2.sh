#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ╭──────────────────────────────────────────────────────────╮
# │   Fedora 42 Post-Install Script - Refactor Profesional   │
# ╰──────────────────────────────────────────────────────────╯

# === [🧱 Pilar 1] Seguridad: Variables Globales y Configuración Básica ===
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo ~"$REAL_USER")
LOGDIR="$USER_HOME/fedora_logs"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="$LOGDIR/install_$TIMESTAMP.log"
ERR_FILE="$LOGDIR/error_$TIMESTAMP.log"
ERROR_COUNT=0

declare -a PACKAGES_ESSENTIALS=(
  vim nano git curl wget htop
  neofetch unzip p7zip p7zip-plugins
  tar gzip bzip2
  zsh bash-completion
)

# === [🧱 Pilar 3] Colores y Logging Empresarial ===
if [[ -t 1 ]]; then
  RED="\033[0;31m"
  GREEN="\033[0;32m"
  YELLOW="\033[1;33m"
  BLUE="\033[1;34m"
  NC="\033[0m"
else
  RED=""; GREEN=""; YELLOW=""; BLUE=""; NC=""
fi

log_info() {
  local msg="$1"
  local ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf "${BLUE}%-65s %s${NC}\n" "[INFO] $msg" "[OK]"
  echo "[$ts] [INFO] $msg" >> "$LOG_FILE"
}

log_success() {
  local msg="$1"
  local ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf "${GREEN}%-65s %s${NC}\n" "[✔ SUCCESS] $msg" "[OK]"
  echo "[$ts] [SUCCESS] $msg" >> "$LOG_FILE"
}

log_warn() {
  local msg="$1"
  local ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf "${YELLOW}%-65s %s${NC}\n" "[⚠ WARNING] $msg" "[WARN]"
  echo "[$ts] [WARNING] $msg" | tee -a "$LOG_FILE" >> "$ERR_FILE"
  ERROR_COUNT=$((ERROR_COUNT + 1))
}

log_error() {
  local msg="$1"
  local ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf "${RED}%-65s %s${NC}\n" "[❌ ERROR] $msg" "[FAIL]"
  echo "[$ts] [ERROR] $msg" | tee -a "$LOG_FILE" >> "$ERR_FILE"
  ERROR_COUNT=$((ERROR_COUNT + 1))
}

log_section() {
  local title="$1"
  local border=$(printf '─%.0s' $(seq 1 $(( ${#title} + 4 ))))
  echo -e "\n${BLUE}┌$border┐${NC}"
  echo -e "${BLUE}│  $title  │${NC}"
  echo -e "${BLUE}└$border┘${NC}\n"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] $title" >> "$LOG_FILE"
}

# === [🧠 Pilar 4] UX - Barra de Progreso ===
progress_bar() {
  local progress=$1
  local total=$2
  local width=40
  local percent=$((progress * 100 / total))
  local done=$((width * progress / total))
  local left=$((width - done))

  {
    printf "\r[" > /dev/tty
    printf "%0.s#" $(seq 1 $done) > /dev/tty
    printf "%0.s-" $(seq 1 $left) > /dev/tty
    printf "] %3d%% (%d/%d)" "$percent" "$progress" "$total" > /dev/tty
    if (( progress == total )); then echo "" > /dev/tty; fi
  } 2>/dev/null
}

# === [🧱 Pilar 1] Verificación de Sudo ===
run_sudo() {
  if ! sudo -n true 2>/dev/null; then
    log_info "Solicitando privilegios sudo..."
    sudo -v || { log_error "No se pudieron obtener privilegios sudo"; exit 1; }
  fi
  if [[ -z "${DISABLE_SUDO_KEEPALIVE:-}" ]]; then
    ( while sudo -n true 2>/dev/null; do sleep 50; done ) &
    SUDO_PID=$!
    trap "kill -9 $SUDO_PID 2>/dev/null || true" EXIT
  fi
}

# === [🧱 Pilar 6] Preparación del Entorno (Logging y Espacio) ===
init_environment() {
  # Seguridad mínima: evitar fallos de log anticipados
  LOGDIR_FALLBACK="/tmp/fedora_logs_debug"
  TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"

  # Determinar usuario real
  REAL_USER="${SUDO_USER:-$USER}"

  # Validar existencia de usuario
  if id "$REAL_USER" &>/dev/null; then
    USER_HOME=$(eval echo "~$REAL_USER")
  else
    USER_HOME="/root"
    echo "[WARN] REAL_USER '$REAL_USER' no tiene home válido. Usando $USER_HOME"
  fi

  # Validar que el directorio home sea accesible
  if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
    echo "[ERROR] No se pudo determinar directorio HOME para $REAL_USER"
    USER_HOME="/root"
  fi

  # Preparar carpeta de logs
  LOGDIR="$USER_HOME/fedora_logs"
  LOG_FILE="$LOGDIR/install_$TIMESTAMP.log"
  ERR_FILE="$LOGDIR/error_$TIMESTAMP.log"

  if ! mkdir -p "$LOGDIR" 2>/dev/null; then
    echo "[ERROR] No se pudo crear $LOGDIR. Usando fallback $LOGDIR_FALLBACK"
    LOGDIR="$LOGDIR_FALLBACK"
    LOG_FILE="$LOGDIR/install_$TIMESTAMP.log"
    ERR_FILE="$LOGDIR/error_$TIMESTAMP.log"
    mkdir -p "$LOGDIR"
  fi

  # Crear archivos de log antes de log_section o log_info
  touch "$LOG_FILE" "$ERR_FILE"
  chmod 664 "$LOG_FILE" "$ERR_FILE"
  chown "$REAL_USER:$REAL_USER" "$LOG_FILE" "$ERR_FILE" 2>/dev/null || true

  # Iniciar redirección
  exec > >(tee >(grep --line-buffered -E "^\[|^\s*\[.*\]" >> "$LOG_FILE") > /dev/tty) \
       2> >(tee >(grep --line-buffered -E "^\[⚠|\[❌" >> "$ERR_FILE") > /dev/tty)

  log_section "🚀 Inicializando entorno de instalación"

  log_info "🧭 Usuario real: $REAL_USER"
  log_info "🏠 Carpeta HOME: $USER_HOME"
  log_info "📁 Carpeta de logs: $LOGDIR"
  log_info "📄 Log de instalación: $(basename "$LOG_FILE")"
  log_info "📄 Log de errores: $(basename "$ERR_FILE")"

  # Validar espacio libre
  REQUIRED_SPACE_MB=5000
  AVAILABLE_KB=$(df --output=avail "$LOGDIR" | tail -n1 | tr -d ' ')
  REQUIRED_KB=$((REQUIRED_SPACE_MB * 1024))

  if [[ -z "$AVAILABLE_KB" || "$AVAILABLE_KB" -lt "$REQUIRED_KB" ]]; then
    log_error "Espacio insuficiente. Requiere ${REQUIRED_SPACE_MB}MB en $LOGDIR (disponible: $((AVAILABLE_KB / 1024))MB)"
    exit 1
  else
    log_success "💽 Espacio libre verificado: $((AVAILABLE_KB / 1024))MB"
  fi
}

configure_dnf() {
  log_section "⚙️ Configuración de DNF (optimizaciones básicas)"

  log_info "📅 Desactivando reloj local (UTC por defecto)"
  sudo timedatectl set-local-rtc '0' &>/dev/null || \
    log_warn "No se pudo configurar timedatectl para usar UTC"

  log_info "🧾 Aplicando parámetros recomendados en /etc/dnf/dnf.conf"
  local dnf_conf="/etc/dnf/dnf.conf"

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

  check_error "No se pudo escribir la configuración en $dnf_conf"
  log_success "✅ DNF optimizado correctamente"
}

configure_dnf_automatic() {
  log_section "🛠️ Configurando DNF Automatic (actualizaciones automáticas)"

  log_info "📦 Instalando dnf-automatic si es necesario"
  sudo dnf install -y --allowerasing --skip-broken --skip-unavailable dnf-automatic
  check_error "No se pudo instalar dnf-automatic"

  log_info "⏱️ Copiando timer al sistema (systemd)"
  sudo cp /usr/lib/systemd/system/dnf-automatic.timer /etc/systemd/system/
  check_error "No se pudo copiar el timer de dnf-automatic"

  log_info "🔁 Habilitando y arrancando dnf-automatic.timer"
  sudo systemctl enable --now dnf-automatic.timer
  check_error "No se pudo habilitar dnf-automatic.timer"

  log_success "✅ dnf-automatic activado correctamente"
}

check_error() {
  local msg="${1:-Ha ocurrido un error}"
  local code="${2:-$?}"

  if [[ "$code" -ne 0 ]]; then
    log_error "$msg"
    return "$code"
  fi
}

update_system() {
  log_section "📦 Actualización del sistema base"

  log_info "🔁 Ejecutando: dnf upgrade --refresh"
  sudo dnf upgrade --refresh -y
  check_error "❌ No se pudo actualizar el sistema"

  log_success "✅ Sistema actualizado correctamente"
}

install_essential_packages() {
  log_section "📦 Instalación de paquetes esenciales del sistema"

  # Verificación de variable
  if [[ -z "${PACKAGES_ESSENTIALS[*]:-}" ]]; then
    log_error "Variable PACKAGES_ESSENTIALS no definida o vacía"
    return 1
  fi

  local total=${#PACKAGES_ESSENTIALS[@]}
  for i in "${!PACKAGES_ESSENTIALS[@]}"; do
    local pkg="${PACKAGES_ESSENTIALS[$i]}"
    log_info "→ Instalando: $pkg"
    sudo dnf install -y --allowerasing --skip-broken --skip-unavailable "$pkg"
    check_error "❌ Fallo al instalar $pkg"
    progress_bar "$((i + 1))" "$total"
  done

  log_success "✅ Todos los paquetes esenciales fueron instalados correctamente"
}

clean_system() {
  log_section "🧼 Limpieza del sistema"

  log_info "🧹 Ejecutando autoremove de paquetes obsoletos"
  sudo dnf autoremove -y
  check_error "❌ No se pudo ejecutar dnf autoremove"

  log_info "🧼 Limpiando caché de DNF"
  sudo dnf clean all
  check_error "❌ No se pudo limpiar la caché de DNF"

  log_success "✅ Sistema limpiado correctamente"
}


# === [📦 Pilar 2] Procesamiento de Argumentos CLI ===
show_help() {
  echo "Uso: $0 [opciones]"
  echo "  -h, --help     Mostrar ayuda"
  echo "  -u, --update   Actualizar el sistema antes de instalar"
  echo "  -c, --clean    Limpiar el sistema después de instalar"
}

UPDATE_SYSTEM=0
CLEAN_SYSTEM=0

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    -h|--help) show_help; exit 0 ;;
    -u|--update) UPDATE_SYSTEM=1; shift ;;
    -c|--clean) CLEAN_SYSTEM=1; shift ;;
    *) log_warn "Opción desconocida: $key"; show_help; exit 1 ;;
  esac
done

change_hostname() {
  log_section "🖥️ Configuración del hostname"
  local hostname_var="${NEW_HOSTNAME:-}"

  # 🧩 Si no se definió por variable, pedirlo por terminal real
  if [[ -z "$hostname_var" ]]; then
    if [[ -t 0 ]]; then
      echo -ne "${BLUE}Introduce el nuevo hostname para este sistema: ${NC}" > /dev/tty
      read -r hostname_var < /dev/tty
    else
      log_warn "No se puede solicitar hostname: no hay terminal interactiva (TTY)"
      return 0
    fi
  fi

  if [[ -z "$hostname_var" ]]; then
    log_warn "Hostname no especificado. Se omite cambio."
    return 0
  fi

  # 📜 Validación básica RFC1123
  if [[ ! "$hostname_var" =~ ^[a-zA-Z0-9][-a-zA-Z0-9]{0,61}[a-zA-Z0-9]$ ]]; then
    log_error "Hostname inválido según RFC1123: $hostname_var"
    return 1
  fi

  log_info "Estableciendo hostname a: $hostname_var"
  if sudo hostnamectl set-hostname --static "$hostname_var"; then
    log_success "Hostname establecido correctamente: $hostname_var"
  else
    log_error "No se pudo establecer el hostname"
  fi
}

# === [🧰 Pilar 5] Configuración de Flatpak ===
configure_flatpak_repositories() {
  log_section "📦 Configuración de Repositorios Flatpak"

  if ! command -v flatpak &>/dev/null; then
    log_info "Instalando Flatpak..."
    sudo dnf install -y flatpak
    [[ $? -eq 0 ]] && log_success "Flatpak instalado correctamente" || log_error "Fallo al instalar Flatpak"
  else
    log_info "Flatpak ya está presente en el sistema"
  fi

  declare -A flatpak_remotes=(
    [flathub]="https://flathub.org/repo/flathub.flatpakrepo"
    [elementary]="https://flatpak.elementary.io/repo.flatpakrepo"
    [kde]="https://distribute.kde.org/kdeapps.flatpakrepo"
    [fedora]="oci+https://registry.fedoraproject.org"
  )

  local i=0
  local total=${#flatpak_remotes[@]}
  for remote in kde flathub elementary fedora; do
    local url="${flatpak_remotes[$remote]}"
    log_info "→ Añadiendo remoto Flatpak: $remote"
    if [[ "$url" == *.flatpakrepo ]]; then
      sudo flatpak remote-add --if-not-exists --from "$remote" "$url" &>/dev/null || log_warn "No se pudo agregar $remote"
    else
      sudo flatpak remote-add --if-not-exists "$remote" "$url" &>/dev/null || log_warn "No se pudo agregar $remote"
    fi
    sudo flatpak remote-modify --system --prio=$((++i)) "$remote" &>/dev/null || log_warn "No se pudo asignar prioridad a $remote"
    progress_bar "$i" "$total"
  done

  log_success "Repositorios Flatpak configurados correctamente"
}

# === [🔐 Pilar 7] Seguridad Básica del Sistema ===
configure_security() {
  log_section "🔐 Configuración de Seguridad y Servicios Base"

  # 1. Instalación de herramientas base
  log_info "📦 Instalando paquetes de seguridad y red..."
  sudo dnf install -y --allowerasing --skip-broken --skip-unavailable \
    firewalld firewall-config \
    selinux-policy selinux-policy-targeted \
    policycoreutils policycoreutils-python-utils \
    samba samba-client avahi nss-mdns \
    ftp lftp openssh-clients bluez-obexd \
    kde-connect qt6-qml kde-connectd \
    rclone fuse

  # 2. Activación de firewalld y zona FedoraWorkstation
  log_info "🔥 Activando firewalld"
sudo systemctl enable --now firewalld &>/dev/null || log_warn "No se pudo activar firewalld"

# Establecer zona por defecto (solo en runtime)
sudo firewall-cmd --set-default-zone=FedoraWorkstation
sudo firewall-cmd --get-default-zone

  # 3. Servicios comunes
  log_info "📡 Habilitando servicios estándar en firewalld"
  local services=(
    ssh http https
    samba samba-client
    mdns ipp
    dns dhcpv6-client
    plex jellyfin
    ftp sftp
    bluetooth obex
  )
  local idx=0
  local total_services=${#services[@]}

  for service in "${services[@]}"; do
    if [[ -n "$service" ]] && sudo firewall-cmd --get-services | grep -qw "$service"; then
      sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service="$service"
      check_error "❌ Error al agregar servicio: $service"
      log_info "✔ Servicio agregado correctamente: $service"
    else
      log_warn "⚠ Servicio no reconocido o vacío: $service"
    fi
    progress_bar "$((++idx))" "$total_services"
  done

  # 4. Puertos manuales adicionales
  log_info "🔌 Apertura de puertos manuales"
  declare -A ports_tcp=(
    [22]="SSH"
    [631]="Impresoras IPP"
    [32400]="Plex"
    [8096]="Jellyfin"
    [21]="FTP"
    [60000-61000]="FTP pasivo"
    [650]="OBEX Bluetooth"
    [1714-1764]="KDE Connect TCP/UDP"
    [8080]="rclone serve http"
  )

  idx=0
  local total_ports=${#ports_tcp[@]}

  for port in "${!ports_tcp[@]}"; do
    if [[ "$port" =~ ^[0-9]+(-[0-9]+)?$ ]]; then
      sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port="${port}/tcp"
      check_error "❌ Error al agregar puerto TCP: $port (${ports_tcp[$port]})"
      log_info "✔ Puerto TCP agregado: ${port} (${ports_tcp[$port]})"

      if [[ "$port" == "1714-1764" ]]; then
        sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port="${port}/udp"
        check_error "❌ Error al agregar puerto UDP: $port"
        log_info "✔ Puerto UDP agregado: ${port}"
      fi
    else
      log_warn "⚠ Puerto no válido: $port"
    fi
    progress_bar "$((++idx))" "$total_ports"
  done

  log_info "🔁 Recargando configuración de firewalld..."
  sudo firewall-cmd --reload
  check_error "❌ Error al recargar firewalld"
  log_success "✅ firewalld recargado correctamente"


  # 5. Servicios de red local
  log_info "⚙️ Activando servicios locales (Avahi, Bluetooth)"
  sudo systemctl enable --now avahi-daemon &>/dev/null
  sudo systemctl enable --now bluetooth &>/dev/null

  # 6. SELinux
  log_info "🔒 Estableciendo SELinux en modo enforcing"
  sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
  sudo semanage permissive -a firewalld_t &>/dev/null || true
  log_success "SELinux configurado con excepción para firewalld"

  # 7. DNS-over-TLS con comentarios
  log_info "🌐 Configurando DNS seguros (DNS-over-TLS)"
  sudo mkdir -p /etc/systemd/resolved.conf.d
  sudo tee /etc/systemd/resolved.conf.d/99-dns-over-tls.conf > /dev/null <<EOF
[Resolve]
DNS=94.140.14.14        # AdGuard primario
DNS=94.140.15.15        # AdGuard secundario
DNS=1.1.1.1             # Cloudflare primario
DNS=1.0.0.1             # Cloudflare secundario
DNSOverTLS=yes
EOF
  sudo systemctl restart systemd-resolved &>/dev/null
  log_success "DNS over TLS configurado (AdGuard + Cloudflare)"

  # 8. hblock
  log_info "🚫 Instalando hblock (bloqueador DNS desde COPR)"
  sudo dnf -y copr enable pesader/hblock &>/dev/null
  sudo dnf install -y hblock &>/dev/null

  if command -v hblock &>/dev/null; then
    sudo hblock &>/dev/null
    log_success "✅ hblock instalado y ejecutado correctamente"
  else
    log_warn "⚠️ hblock no se instaló correctamente"
  fi

  log_success "🎉 Configuración general de seguridad finalizada"
}

configure_network_security() {
  log_section "🌐 Seguridad de Red: Fail2ban + SSH + Firewall"

  # 1. Desactivar chronyd si no se requiere
  log_info "🕒 Desactivando servicio de sincronización NTP (chronyd)"
  sudo systemctl disable --now chronyd.service &>/dev/null || \
    log_warn "chronyd ya estaba desactivado o no instalado"

  # 2. Instalar y activar fail2ban
  log_info "🔐 Instalando y activando fail2ban"
  sudo dnf install -y fail2ban &>/dev/null
  sudo systemctl enable --now fail2ban &>/dev/null
  check_error "No se pudo activar fail2ban"

  log_info "🛠️ Configurando fail2ban para proteger SSH"
  sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[sshd]
enabled = true
port    = 2222
logpath = /var/log/secure
maxretry = 3
bantime = 1h
EOF
  sudo systemctl restart fail2ban

  # 3. Endurecer configuración SSH
  log_info "🔐 Ajustando configuración de SSH"
  sudo sed -i 's/^#\?Port .*/Port 2222/' /etc/ssh/sshd_config
  sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
  sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
  sudo systemctl restart sshd
  check_error "No se pudo reiniciar SSH con nuevos ajustes"

  # 4. Limitar acceso SSH a red local
  log_info "🌐 Restringiendo acceso SSH al segmento local 192.168.1.0/24"
  sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="2222" protocol="tcp" accept' --zone=FedoraWorkstation --permanent
  sudo firewall-cmd --remove-service=ssh --zone=FedoraWorkstation --permanent
  sudo firewall-cmd --reload &>/dev/null

  # 5. Registrar nuevo puerto SSH en SELinux (si aplica)
  sudo semanage port -a -t ssh_port_t -p tcp 2222 2>/dev/null || true

  log_success "✅ Seguridad de red configurada correctamente (fail2ban + SSH endurecido)"
}

# === [🧰 Pilar 5] Configuración de subvolúmenes BTRFS ===
configure_btrfs_volumes() {
  log_section "🧩 Configurando BTRFS y subvolúmenes"

  local fs_type
  fs_type=$(findmnt -n -o FSTYPE /)
  if [[ "$fs_type" != "btrfs" ]]; then
    log_warn "Sistema no está en BTRFS. Saltando configuración."
    return 0
  fi

  sudo dnf install -y btrfs-progs inotify-tools

  log_info "Respaldando fstab actual..."
  sudo cp /etc/fstab /etc/fstab.old
  local output_file="/etc/fstab.new"
  sudo cp /etc/fstab "$output_file"

  declare -A subvolumes=(
    ["/"]="@"
    ["/var/log"]="@log"
    ["/var/tmp"]="@var_tmp"
    ["/tmp"]="@tmp"
    ["/timeshift"]="@timeshift"
  )

  for mount_point in "${!subvolumes[@]}"; do
    uuid=$(findmnt -no UUID "$mount_point" 2>/dev/null)
    if [[ -n "$uuid" ]]; then
      sudo sed -i -E \
        "s|UUID=.*[[:space:]]+$mount_point[[:space:]]+btrfs.*|UUID=$uuid $mount_point btrfs rw,noatime,compress=zstd:3,space_cache=v2,subvol=${subvolumes[$mount_point]} 0 0|" \
        "$output_file"
    fi
  done

  sudo cp "$output_file" /etc/fstab

  log_info "Aplicando compresión y balanceo inicial..."
  sudo btrfs filesystem defragment -r -czstd:3 / &>/dev/null || true
  sudo btrfs balance start -m / &>/dev/null || true

  log_success "Subvolúmenes BTRFS configurados correctamente"
}

# === Snapshot inicial con Timeshift ===
initialize_timeshift_config() {
  log_info "📸 Configurando Timeshift y creando snapshot inicial"

  sudo mkdir -p /timeshift

  if ! sudo timeshift --btrfs --snapshot-device "$(findmnt -no SOURCE /)"; then
    log_error "Fallo al configurar Timeshift para /timeshift"
    return 1
  fi

  if ! sudo timeshift --create --comments "Snapshot inicial" --tags D; then
    log_error "Fallo al crear snapshot inicial con Timeshift"
    return 1
  fi

  sudo tee /etc/timeshift/timeshift.json > /dev/null <<EOF
{
  "backup_device_uuid" : "$(findmnt -no UUID /)",
  "snapshot_dir" : "/timeshift",
  "snapshot_name" : "timeshift-btrfs",
  "mode" : "btrfs",
  "schedule_daily" : true,
  "count_daily" : 5,
  "schedule_weekly" : true,
  "count_weekly" : 3,
  "schedule_monthly" : true,
  "count_monthly" : 2
}
EOF

  log_success "✅ Timeshift configurado correctamente con snapshot inicial"
}

# === Configuración de GRUB-BTRFS + Timeshift ===
configure_grub_btrfs_timeshift() {
  log_info "🔧 Configurando integración grub-btrfs con Timeshift"

  sudo mkdir -p /etc/default/grub-btrfs
  sudo tee /etc/default/grub-btrfs/config > /dev/null <<EOF
GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"
GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig
GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check
GRUB_BTRFS_SUBMENUNAME="Snapshots BTRFS"
GRUB_BTRFS_SNAPSHOT_FORMAT="%Y-%m-%d %H:%M | %c"
GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="rootflags=subvol=@ quiet"
EOF

  log_info "🌀 Regenerando configuración de GRUB"
  sudo grub2-mkconfig -o /boot/grub2/grub.cfg

  if systemctl list-unit-files | grep -q '^grub-btrfs.path'; then
    log_info "🟢 Habilitando grub-btrfs.path"
    sudo systemctl enable --now grub-btrfs.path || log_warn "No se pudo habilitar grub-btrfs.path"
  else
    log_warn "Servicio grub-btrfs.path no disponible. Se omite."
  fi

  initialize_timeshift_config || log_warn "Problemas al inicializar Timeshift"

  log_success "GRUB-BTRFS y Timeshift configurados correctamente"
}

# === Instalación desde COPR ===
install_grub_btrfs_timeshift() {
  log_section "📥 Instalando grub-btrfs y Timeshift desde COPR"

  if ! dnf copr list | grep -q "kylegospo/grub-btrfs"; then
    log_info "🔗 Habilitando COPR: grub-btrfs"
    sudo dnf copr enable -y kylegospo/grub-btrfs || log_warn "No se pudo habilitar COPR grub-btrfs"
  fi

  sudo dnf -y update
  sudo dnf install -y timeshift grub-btrfs-timeshift || log_warn "Error parcial en instalación de paquetes grub-btrfs"

  configure_btrfs_volumes
  configure_grub_btrfs_timeshift
}

final_cleanup_and_reboot() {
  log_section "🧹 Limpieza Final y Preparación para Reinicio"

  log_info "🗑️ Eliminando archivos temporales (con precaución)"
  sudo rm -rf /tmp/* /var/tmp/* &>/dev/null || log_warn "No se pudieron limpiar todos los temporales"

  log_info "🧼 Limpiando caché de DNF"
  sudo dnf clean all &>/dev/null || log_warn "Fallo al limpiar caché DNF"

  log_info "🔁 Refrescando caché de DNS"
  sudo systemd-resolve --flush-caches &>/dev/null || log_warn "No se pudo limpiar la caché DNS (systemd-resolved)"

  log_info "📦 Aplicando update y upgrade final"
  sudo dnf update -y --refresh && sudo dnf upgrade -y

  log_success "✅ Sistema actualizado y limpiado correctamente"

  # Confirmación de reinicio
  echo -ne "${BLUE}¿Deseas reiniciar el sistema ahora? (s/n): ${NC}" > /dev/tty
  read -r confirm < /dev/tty
  if [[ "$confirm" =~ ^[sS]$ ]]; then
    log_info "🔄 Reiniciando el sistema..."
    sudo reboot
  else
    log_info "⏹️ Reinicio cancelado por el usuario. Puedes hacerlo manualmente más tarde."
  fi
}


main() {
  
  init_environment

  run_sudo

  [[ "$UPDATE_SYSTEM" -eq 1 ]] && update_system

  configure_dnf
  configure_dnf_automatic
  change_hostname

  install_essential_packages
  configure_flatpak_repositories

  configure_security
  configure_network_security

  install_grub_btrfs_timeshift

  [[ "$CLEAN_SYSTEM" -eq 1 ]] && clean_system

  log_info "ℹ️ Todas las configuraciones básicas han sido aplicadas."

  if [[ $ERROR_COUNT -eq 0 ]]; then
    log_success "🎉 Script finalizado sin errores."
  else
    log_warn "⚠️ Script finalizado con $ERROR_COUNT error(es)/advertencia(s). Revisa el archivo: $ERR_FILE"
  fi

  final_cleanup_and_reboot
}



main "$@"

exit 0
