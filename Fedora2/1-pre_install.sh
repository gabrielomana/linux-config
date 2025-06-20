#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ===============================================
# Post-Instalación Fedora 42 - Script Principal
# ===============================================

# === VARIABLES GLOBALES ===
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo ~"$REAL_USER")
LOGDIR="$USER_HOME/fedora_logs"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="$LOGDIR/pre_install_full_${TIMESTAMP}.log"
ERR_FILE="$LOGDIR/pre_install_error_${TIMESTAMP}.log"
ERROR_COUNT=0

declare -a PACKAGES_ESSENTIALS=(
  vim nano git curl wget htop
  neofetch unzip p7zip p7zip-plugins
  tar gzip bzip2
  zsh bash-completion
)




# === COLORES ANSI CON DETECCIÓN DE TTY ===
if [[ -t 1 ]]; then
  RED="\033[0;31m"
  GREEN="\033[0;32m"
  YELLOW="\033[1;33m"
  BLUE="\033[1;34m"
  NC="\033[0m"
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  NC=""
fi

# === PREPARACIÓN DE LOGS ===
mkdir -p "$LOGDIR"
: > "$LOG_FILE"
: > "$ERR_FILE"

# === CHEQUEO DE DEPENDENCIAS ===
for bin in logger awk grep tee; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        echo "[ERROR] Falta dependencia: $bin" | tee -a "$ERR_FILE"
        exit 2
    fi
done

# === FUNCIONES DE LOG Y FEEDBACK ===

log_info() {
    local msg="$1"
    local date_time; date_time=$(date '+%Y-%m-%d %H:%M:%S')
    printf "${BLUE}%-65s %s${NC}\n" "[INFO] $msg" "[OK]"
    echo "[$date_time] [INFO] $msg" >> "$LOG_FILE"
}

log_success() {
    local msg="$1"
    local date_time; date_time=$(date '+%Y-%m-%d %H:%M:%S')
    printf "${GREEN}%-65s %s${NC}\n" "[✔ SUCCESS] $msg" "[OK]"
    echo "[$date_time] [SUCCESS] $msg" >> "$LOG_FILE"
}

log_warn() {
    local msg="$1"
    local date_time; date_time=$(date '+%Y-%m-%d %H:%M:%S')
    printf "${YELLOW}%-65s %s${NC}\n" "[⚠ WARNING] $msg" "[WARN]"
    echo "[$date_time] [WARNING] $msg" | tee -a "$LOG_FILE" >> "$ERR_FILE"
    ERROR_COUNT=$((ERROR_COUNT+1))
}

log_error() {
    local msg="$1"
    local date_time; date_time=$(date '+%Y-%m-%d %H:%M:%S')
    printf "${RED}%-65s %s${NC}\n" "[❌ ERROR] $msg" "[FAIL]"
    echo "[$date_time] [ERROR] $msg" | tee -a "$LOG_FILE" >> "$ERR_FILE"
    ERROR_COUNT=$((ERROR_COUNT+1))
}

log_section() {
    local title="$1"
    local len=${#title}
    local border
    border=$(printf '─%.0s' $(seq 1 $((len + 4))))
    echo -e "\n${BLUE}┌$border┐${NC}"
    echo -e "${BLUE}│  $title  │${NC}"
    echo -e "${BLUE}└$border┘${NC}\n"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] $title" >> "$LOG_FILE"
}

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


# === SUDO & PRIVILEGIOS ===
check_error() {
  local msg="$1"
  if [[ $? -ne 0 ]]; then
    log_error "$msg"
    return 1
  fi
  return 0
}

run_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_info "Solicitando privilegios sudo..."
        sudo -v || {
            log_error "No se pudieron obtener privilegios de administrador" "true"
            exit 1
        }
    fi

    if [[ -z "${DISABLE_SUDO_KEEPALIVE:-}" ]]; then
        (
            while sudo -n true 2>/dev/null; do
                sleep 50
            done
        ) &
        SUDO_PID=$!
        trap "kill -9 $SUDO_PID 2>/dev/null || true" EXIT
    fi
}

# === AYUDA CLI ===
show_help() {
    echo "Script de post-instalación para Fedora 42"
    echo
    echo "Opciones:"
    echo "  -h, --help      Mostrar esta ayuda"
    echo "  -u, --update    Actualizar el sistema antes de ejecutar el resto"
    echo "  -c, --clean     Limpiar el sistema tras la instalación"
    echo
}

init_environment() {
  log_section "🚀 Inicializando entorno de post-instalación"

  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  LOG_TAG="fedora_refactor"
  REQUIRED_CMDS=(tee dnf command mkdir logger)
  REQUIRED_SPACE_MB=5000
  REAL_USER="${SUDO_USER:-$USER}"
  REAL_HOME=$(eval echo "~$REAL_USER")

  # Pilar 1: Seguridad y permisos de ejecución
  if [[ $EUID -ne 0 ]]; then
    echo "❌ Este script debe ejecutarse con privilegios de root (sudo)" >&2
    exit 1
  fi

  # Pilar 3: Crear y configurar carpeta de logs
  mkdir -p "$LOGDIR"
  chmod 775 "$LOGDIR"

  # Pilar 4: Definir archivos de log con timestamp para trazabilidad
  timestamp="$(date +'%Y%m%d_%H%M%S')"
  export LOG_FILE="$LOGDIR/install_${timestamp}.log"
  export ERR_FILE="$LOGDIR/error_${timestamp}.log"

  touch "$LOG_FILE" "$ERR_FILE"
  chown "$REAL_USER":"$REAL_USER" "$LOG_FILE" "$ERR_FILE"
  chmod 664 "$LOG_FILE" "$ERR_FILE"

  # Pilar 3: Redirección avanzada de salida/logs (stdout → install, stderr → error)
  exec > >(tee >(grep --line-buffered -E "^\[|^\s*\[.*\]" >> "$LOG_FILE") > /dev/tty) \
       2> >(tee >(grep --line-buffered -E "^\[⚠|\[❌" >> "$ERR_FILE") > /dev/tty)

  log_info "🧭 Proyecto: $PROJECT_ROOT"
  log_info "👤 Usuario original: $REAL_USER (home: $REAL_HOME)"
  log_info "📁 Logs en: $LOGDIR"
  log_info "📄 Archivo de instalación: $(basename "$LOG_FILE")"
  log_info "📄 Archivo de errores: $(basename "$ERR_FILE")"

  # Pilar 7: Validación de comandos esenciales
  for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
      log_warn "El comando '$cmd' no está instalado. Intentando instalar..."
      if [[ "$cmd" == "logger" ]]; then
        dnf install -y --allowerasing --skip-broken --skip-unavailable util-linux &>/dev/null
      else
        dnf install -y --allowerasing --skip-broken --skip-unavailable "$cmd" &>/dev/null || {
          log_error "No se pudo instalar '$cmd'. Abortando." "true"
          exit 1
        }
      fi
    fi
  done

  # Pilar 5: Compatibilidad visual
  if [ -n "${DISPLAY:-}" ]; then
    log_info "🖥️ Entorno gráfico detectado: $DISPLAY"
  else
    log_info "📦 Modo consola / TTY"
  fi

  # Pilar 1 y 6: Validación de espacio
  log_info "Verificando espacio disponible en $PROJECT_ROOT..."
  AVAILABLE_KB=$(df --output=avail "$PROJECT_ROOT" 2>/dev/null | tail -n 1 | tr -d ' ')
  REQUIRED_KB=$((REQUIRED_SPACE_MB * 1024))

  if [[ -z "$AVAILABLE_KB" || "$AVAILABLE_KB" -lt "$REQUIRED_KB" ]]; then
    log_error "Espacio insuficiente: se requieren ${REQUIRED_SPACE_MB}MB libres en $PROJECT_ROOT (disponible: $((AVAILABLE_KB / 1024))MB)" "true"
    exit 1
  else
    log_success "Espacio libre verificado: $((AVAILABLE_KB / 1024))MB disponibles"
  fi

  log_success "✅ Entorno inicial preparado correctamente"
}




get_uuid() {
  local mount_point="$1"
  findmnt -no UUID "$mount_point" 2>/dev/null
}

configure_dnf() {
    log_info "Configurando DNF para optimizar rendimiento"
    sudo timedatectl set-local-rtc '0' &>/dev/null || log_warn "No se pudo configurar timedatectl"
    local DNF_CONF_CONTENT="[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
fastestmirror=True
max_parallel_downloads=10
defaultyes=True
keepcache=True
deltarpm=True"
    echo "$DNF_CONF_CONTENT" | sudo tee /etc/dnf/dnf.conf > /dev/null
    check_error "No se pudo escribir configuración de DNF"
    log_info "DNF configurado exitosamente"
}

configure_dnf_automatic() {
    log_info "Configurando DNF Automatic para actualizaciones automáticas"
    sudo dnf install -y --allowerasing --skip-broken --skip-unavailable dnf-automatic
    check_error "No se pudo instalar dnf-automatic"
    sudo cp /usr/lib/systemd/system/dnf-automatic.timer /etc/systemd/system/
    check_error "No se pudo copiar el timer de dnf-automatic"
    sudo systemctl enable --now dnf-automatic.timer
    check_error "No se pudo habilitar dnf-automatic.timer"
    log_info "DNF Automatic configurado correctamente"
}

change_hostname() {
    log_section "🖥️ Configuración del hostname"

    local hostname_var="${NEW_HOSTNAME:-}"

    # 🧩 Si no se pasó por variable, pedirlo interactivamente por TTY
    if [[ -z "$hostname_var" ]]; then
        echo -ne "${BLUE}Introduce el nuevo hostname para este sistema: ${NC}" > /dev/tty
        read -r hostname_var < /dev/tty
    fi

    if [[ -z "$hostname_var" ]]; then
        log_warn "No se especificó un hostname. Se omite el cambio."
        return 0
    fi

    # 📜 Validación RFC1123
    if [[ ! "$hostname_var" =~ ^[a-zA-Z0-9][-a-zA-Z0-9]{0,61}[a-zA-Z0-9]$ ]]; then
        log_error "El hostname '$hostname_var' no es válido (RFC1123). Ejemplo válido: fedora42-dev"
        return 1
    fi

    log_info "Estableciendo hostname a: $hostname_var"
    if sudo hostnamectl set-hostname --static "$hostname_var"; then
        log_success "Hostname establecido correctamente: $hostname_var"
    else
        log_error "No se pudo establecer el hostname a $hostname_var"
    fi
}



configure_repositories() {
    log_section "🌐 Configuración de Repositorios Fedora"

    log_info "Instalando repositorios de Fedora Workstation..."
    if sudo dnf -y --quiet install fedora-workstation-repositories; then
        log_info "Repositorios Workstation instalados correctamente"
    else
        check_error "No se pudieron instalar los repositorios de Fedora Workstation"
        log_warn "Continuando sin los repositorios Workstation"
    fi

    log_info "Instalando repositorios RPM Fusion (Free y NonFree)..."
    if sudo dnf -y --quiet install \
        "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"; then
        log_info "Repositorios RPM Fusion instalados correctamente"
    else
        check_error "No se pudieron instalar los repositorios RPM Fusion"
        log_warn "Continuando sin los repositorios RPM Fusion"
    fi

    log_info "Actualizando caché de repositorios..."
    sudo dnf clean all -q || log_warn "Fallo al limpiar caché DNF"
    sudo dnf makecache --refresh -q || log_warn "Fallo al refrescar caché DNF"
    sudo dnf update -y -q || log_warn "Fallo al aplicar 'dnf update'"
    sudo dnf upgrade -y -q || log_warn "Fallo al aplicar 'dnf upgrade'"
    sudo dnf -y -q group upgrade core || log_warn "Fallo al actualizar grupo 'core'"

    log_success "Repositorios configurados y actualizados correctamente"
}


install_essential_packages() {
    log_section "📦 Instalando paquetes esenciales del sistema"

    if [[ -z "${PACKAGES_ESSENTIALS[*]:-}" ]]; then
        log_error "La variable PACKAGES_ESSENTIALS está vacía o no definida"
        return 1
    fi

    local total=${#PACKAGES_ESSENTIALS[@]}
    for i in "${!PACKAGES_ESSENTIALS[@]}"; do
        local pkg="${PACKAGES_ESSENTIALS[$i]}"
        log_info "→ Instalando $pkg"
        sudo dnf install -y --allowerasing --skip-broken --skip-unavailable "$pkg"
        check_error "No se pudo instalar $pkg"
        progress_bar "$((i + 1))" "$total"
    done

    log_success "Todos los paquetes esenciales fueron instalados correctamente"
}


configure_flatpak_repositories() {
    log_section "📦 Configuración de Repositorios Flatpak"

    if ! command -v flatpak &>/dev/null; then
        log_info "Instalando Flatpak..."
        sudo dnf install -y --allowerasing --skip-broken --skip-unavailable flatpak
        check_error "No se pudo instalar Flatpak"
    else
        log_info "Flatpak ya está instalado"
    fi

    log_info "Agregando repositorios Flatpak si no existen..."

    declare -A flatpak_remotes=(
        [flathub]="https://flathub.org/repo/flathub.flatpakrepo"
        [elementary]="https://flatpak.elementary.io/repo.flatpakrepo"
        [kde]="https://distribute.kde.org/kdeapps.flatpakrepo"
        [fedora]="oci+https://registry.fedoraproject.org"
    )

    prio=1
    for remote in kde flathub elementary fedora; do
        url="${flatpak_remotes[$remote]}"
        log_info "→ Asegurando remoto: $remote ($url)"

        if [[ "$url" == *.flatpakrepo ]]; then
            sudo flatpak remote-add --if-not-exists --from "$remote" "$url" &>/dev/null || log_warn "No se pudo agregar el remoto $remote"
        else
            sudo flatpak remote-add --if-not-exists "$remote" "$url" &>/dev/null || log_warn "No se pudo agregar el remoto $remote"
        fi

        sudo flatpak remote-modify --system --prio=$prio "$remote" &>/dev/null || log_warn "No se pudo asignar prioridad al remoto $remote"
        prio=$((prio + 1))
    done

    log_success "Repositorios Flatpak configurados correctamente"
}



configure_zswap() {
  log_info "Configurando ZSWAP para mejor rendimiento del sistema"
  _zswap_prerequisitos
  _zswap_dinamico_por_memoria
  _zswap_grub_config
  _zswap_script_monitor
  log_info "ZSWAP configurado correctamente"
  log_info "Puedes ver estadísticas de ZSWAP con: sudo zswap-monitor"
}

_zswap_prerequisitos() {
  log_info "Eliminando zram-generator si existe..."
  dnf remove -y zram-generator &>/dev/null

  log_info "Actualizando sistema antes de configurar ZSWAP..."
  dnf update -y -q

  log_info "Habilitando módulo lz4hc..."
  modprobe lz4hc &>/dev/null
  check_error "No se pudo cargar el módulo lz4hc"

  log_info "Configurando dracut para ZSWAP..."
  mkdir -p /etc/dracut.conf.d
  echo 'add_drivers+="lz4hc"' | tee /etc/dracut.conf.d/lz4hc.conf > /dev/null

  log_info "Regenerando initramfs (esto puede tardar)..."
  dracut --regenerate-all --force &>/dev/null
  check_error "No se pudo regenerar initramfs"

  echo "lz4hc" | tee /sys/module/zswap/parameters/compressor &>/dev/null
}

_zswap_dinamico_por_memoria() {
  log_info "Ajustando configuración ZSWAP según cantidad de RAM"

  total_ram=$(free -g | awk '/^Mem:/{print $2}')
  if [ "$total_ram" -le 4 ]; then
    swappiness=60
    zswap_max_pool=40
    vfs_cache_pressure=50
  elif [ "$total_ram" -le 12 ]; then
    swappiness=40
    zswap_max_pool=33
    vfs_cache_pressure=50
  elif [ "$total_ram" -le 20 ]; then
    swappiness=30
    zswap_max_pool=25
    vfs_cache_pressure=50
  elif [ "$total_ram" -le 32 ]; then
    swappiness=20
    zswap_max_pool=20
    vfs_cache_pressure=75
  else
    swappiness=10
    zswap_max_pool=20
    vfs_cache_pressure=75
  fi

  sysctl_conf="/etc/sysctl.d/99-zswap.conf"
  echo "vm.swappiness=$swappiness" > "$sysctl_conf"
  echo "vm.vfs_cache_pressure=$vfs_cache_pressure" >> "$sysctl_conf"
  sysctl -p "$sysctl_conf" &>/dev/null
}

_zswap_grub_config() {
  log_info "Configurando GRUB para ZSWAP"
  grub_file="/etc/default/grub"
  cp "$grub_file" "$grub_file.bak"

  sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ zswap.enabled=1 zswap.max_pool_percent='"$zswap_max_pool"' zswap.zpool=z3fold zswap.compressor=lz4hc"/' "$grub_file"

  grub2-mkconfig -o /boot/grub2/grub.cfg &>/dev/null
  check_error "No se pudo actualizar GRUB"
}

_zswap_script_monitor() {
  log_info "Instalando script de monitoreo de ZSWAP"

  local script_file="/usr/local/bin/zswap-monitor"
  cat << 'EOF' > "$script_file"
#!/bin/bash
MDL=/sys/module/zswap
DBG=/sys/kernel/debug/zswap
PAGE=$(( $(cat $DBG/stored_pages 2>/dev/null || echo 0) * 4096 ))
POOL=$(( $(cat $DBG/pool_total_size 2>/dev/null || echo 0) ))
Show(){
    printf "========
$1
========
"
    grep -R . $2 2>&1 | sed "s|.*/||"
}
Show "ZSWAP Settings" $MDL
Show "ZSWAP Statistics" $DBG
printf "\nCompression ratio: "
[ $POOL -gt 0 ] && {
    echo "scale=3; $PAGE / $POOL" | bc
} || echo "ZSWAP disabled"
EOF

  chmod +x "$script_file"
}

configure_security() {
    log_info "🔐 Iniciando configuración de seguridad y servicios para entorno doméstico y multimedia"

    # 1. INSTALACIÓN DE PAQUETES NECESARIOS
    log_info "📦 Instalando herramientas base..."
    sudo dnf install -y --allowerasing --skip-broken --skip-unavailable \
        firewalld firewall-config \
        selinux-policy selinux-policy-targeted \
        policycoreutils policycoreutils-python-utils \
        samba samba-client avahi nss-mdns \
        ftp lftp openssh-clients bluez-obexd \
        kde-connect qt6-qml kde-connectd \
        rclone fuse

    # 2. FIREWALL – ZONA Y SERVICIOS
    log_info "🔥 Activando firewalld y configurando zona"
    sudo systemctl enable --now firewalld &>/dev/null
    check_error "❌ No se pudo activar firewalld"

    sudo firewall-cmd --set-default-zone=FedoraWorkstation --permanent
    sudo firewall-cmd --reload &>/dev/null

    log_info "📺 Habilitando servicios en FedoraWorkstation..."
    services=(
        ssh http https
        samba samba-client
        mdns ipp
        dns dhcpv6-client
        plex jellyfin
        ftp sftp
        bluetooth obex
    )
    for service in "${services[@]}"; do
        sudo firewall-cmd --add-service="$service" --zone=FedoraWorkstation --permanent &>/dev/null
    done

    # 3. PUERTOS MANUALES CON COMENTARIOS
    log_info "📡 Habilitando puertos individuales necesarios..."
    sudo firewall-cmd --add-port=22/tcp --zone=FedoraWorkstation --permanent      # SSH
    sudo firewall-cmd --add-port=631/tcp --zone=FedoraWorkstation --permanent     # Impresoras IPP
    sudo firewall-cmd --add-port=32400/tcp --zone=FedoraWorkstation --permanent   # Plex
    sudo firewall-cmd --add-port=8096/tcp --zone=FedoraWorkstation --permanent    # Jellyfin
    sudo firewall-cmd --add-port=21/tcp --zone=FedoraWorkstation --permanent      # FTP
    sudo firewall-cmd --add-port=60000-61000/tcp --zone=FedoraWorkstation --permanent # FTP pasivo
    sudo firewall-cmd --add-port=650/tcp --zone=FedoraWorkstation --permanent     # OBEX Bluetooth
    sudo firewall-cmd --add-port=1714-1764/tcp --zone=FedoraWorkstation --permanent # KDE Connect TCP
    sudo firewall-cmd --add-port=1714-1764/udp --zone=FedoraWorkstation --permanent # KDE Connect UDP
    sudo firewall-cmd --add-port=8080/tcp --zone=FedoraWorkstation --permanent     # rclone serve http/webdav
    sudo firewall-cmd --reload &>/dev/null

    # 4. RED LOCAL
    log_info "📡 Activando servicios de red local (Avahi, Bluetooth)"
    sudo systemctl enable --now avahi-daemon &>/dev/null
    sudo systemctl enable --now bluetooth &>/dev/null

    # 5. SELINUX
    log_info "🔒 Configurando SELinux en modo enforcing"
    sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
    log_info "⚙️ Aplicando excepción permisiva para firewalld"
    sudo semanage permissive -a firewalld_t &>/dev/null

    # 6. DNS OVER TLS – DOCUMENTADO
    log_info "🌐 Configurando DNS seguros con DNS-over-TLS"
    sudo mkdir -p /etc/systemd/resolved.conf.d
    {
        echo "[Resolve]"
        echo "DNS=94.140.14.14"       # AdGuard primario
        echo "DNS=94.140.15.15"       # AdGuard secundario
        echo "DNS=1.1.1.1"             # Cloudflare primario
        echo "DNS=1.0.0.1"             # Cloudflare secundario
        echo "DNSOverTLS=yes"
    } | sudo tee /etc/systemd/resolved.conf.d/99-dns-over-tls.conf > /dev/null
    sudo systemctl restart systemd-resolved &>/dev/null

    # 7. HBLOCK
    log_info "🚫 Instalando hblock desde COPR"
    sudo dnf -y copr enable pesader/hblock &>/dev/null
    sudo dnf install -y hblock &>/dev/null
    if command -v hblock &>/dev/null; then
        sudo hblock &>/dev/null
        log_success "✅ hblock instalado y ejecutado correctamente"
    else
        log_warn "⚠️ hblock no se instaló correctamente"
    fi

    log_success "🎉 Configuración general de seguridad finalizada"
    configure_network_security
}

configure_network_security() {
    log_info "🌐 Aplicando configuraciones de seguridad de red avanzada"

    # 1. Desactivar chronyd si no se requiere
    log_info "🕒 Desactivando servicio de sincronización NTP (chronyd)"
    sudo systemctl disable --now chronyd.service &>/dev/null || \
        log_warn "chronyd ya estaba desactivado o no instalado"

    # 2. Instalar y configurar fail2ban
    log_info "🔐 Instalando fail2ban"
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

    # 3. Configurar SSH endurecido en puerto alternativo
    log_info "🔐 Ajustando configuración de SSH"
    sudo sed -i 's/^#\?Port .*/Port 2222/' /etc/ssh/sshd_config
    sudo sed -i 's/^#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
    sudo sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
    sudo systemctl restart sshd
    check_error "No se pudo reiniciar SSH con nuevos ajustes"

    # 4. Limitar SSH a red local
    log_info "🌐 Restringiendo acceso SSH a red local"
    sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="2222" protocol="tcp" accept' --zone=FedoraWorkstation --permanent
    sudo firewall-cmd --remove-service=ssh --zone=FedoraWorkstation --permanent
    sudo firewall-cmd --reload &>/dev/null

    # Registrar nuevo puerto en SELinux si es necesario
    sudo semanage port -a -t ssh_port_t -p tcp 2222 2>/dev/null || true

    log_success "✅ Seguridad de red configurada correctamente"
}


configure_btrfs_volumes() {
  log_section "🧩 Configurando BTRFS y subvolúmenes"

  local fs_type
  fs_type=$(findmnt -n -o FSTYPE /)
  if [[ "$fs_type" != "btrfs" ]]; then
    log_warn "Sistema no está en BTRFS. Saltando configuración."
    return 0
  fi

  dnf install -y --allowerasing --skip-broken --skip-unavailable btrfs-progs inotify-tools

  log_info "Respaldando fstab..."
  cp /etc/fstab /etc/fstab.old
  local output_file="/etc/fstab.new"
  cp /etc/fstab "$output_file"


  declare -A subvolumes=(
    ["/"]="@"
    ["/var/log"]="@log"
    ["/var/tmp"]="@var_tmp"
    ["/tmp"]="@tmp"
    ["/timeshift"]="@timeshift"
  )

  for mount_point in "${!subvolumes[@]}"; do
    uuid=$(get_uuid "$mount_point")
    if [[ -n "$uuid" ]]; then
      sed -i -E \
        "s|UUID=.*\s+$mount_point\s+btrfs.*|UUID=$uuid $mount_point btrfs rw,noatime,compress=zstd:3,space_cache=v2,subvol=${subvolumes[$mount_point]} 0 0|" \
        "$output_file"
    fi
  done

  cp "$output_file" /etc/fstab

  log_info "Aplicando compresión y balanceo inicial..."
  btrfs filesystem defragment -r -czstd:3 / &>/dev/null || true
  btrfs balance start -m / &>/dev/null || true

  log_success "Subvolúmenes BTRFS configurados correctamente."
}

configure_grub_btrfs_timeshift() {
    log_section "📌 Configurando grub-btrfs con soporte para /timeshift"

    local CONFIG_FILE="/etc/default/grub-btrfs/config"

    if ! command -v grub-btrfs.path &>/dev/null; then
        log_warn "grub-btrfs no está instalado. Se omite configuración de grub-btrfs.path"
        return 0
    fi

    if [ ! -d "/timeshift" ]; then
        log_info "Directorio /timeshift no existe. Creándolo..."
        mkdir -p /timeshift
    fi

    mkdir -p "$(dirname "$CONFIG_FILE")"

    if grep -q 'GRUB_BTRFS_SNAPSHOT_DIR="/timeshift"' "$CONFIG_FILE" 2>/dev/null; then
        log_info "Ya existe configuración válida en $CONFIG_FILE. No se sobrescribe."
    else
        log_info "Aplicando configuración personalizada a $CONFIG_FILE"
        echo 'GRUB_BTRFS_SNAPSHOT_DIR="/timeshift"' >> "$CONFIG_FILE"
    fi

    systemctl daemon-reexec

    if systemctl restart grub-btrfs.path &>/dev/null; then
        log_success "Servicio grub-btrfs.path reiniciado correctamente"
    else
        log_warn "No se pudo reiniciar grub-btrfs.path (puede requerir revisión manual)"
    fi
}



install_grub_btrfs() {
    log_section "🔄 Instalación y configuración de grub-btrfs + Timeshift"

    log_info "Habilitando repositorio COPR para grub-btrfs..."
    dnf copr enable -y kylegospo/grub-btrfs

    log_info "Actualizando paquetes antes de instalar grub-btrfs..."
    dnf update -y

    log_info "Instalando grub-btrfs, integración con Timeshift y Timeshift..."
    dnf install -y --allowerasing --skip-broken --skip-unavailable grub-btrfs grub-btrfs-timeshift timeshift

    log_info "Configurando directorio y archivo de grub-btrfs..."
    mkdir -p /etc/default/grub-btrfs
    tee /etc/default/grub-btrfs/config > /dev/null <<EOF
GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"
GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig
GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check
GRUB_BTRFS_SUBMENUNAME="Snapshots BTRFS"
GRUB_BTRFS_SNAPSHOT_FORMAT="%Y-%m-%d %H:%M | %c"
GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="rootflags=subvol=@ quiet"
EOF

    log_info "Regenerando configuración de GRUB..."
    grub2-mkconfig -o /boot/grub2/grub.cfg

    configure_grub_btrfs_timeshift

    log_info "Habilitando servicio grub-btrfs.path..."
    systemctl enable --now grub-btrfs.path || log_warn "No se pudo habilitar grub-btrfs.path"

    log_info "Preparando Timeshift y snapshot inicial..."
    mkdir -p /timeshift

    timeshift --btrfs --snapshot-device "$(findmnt -no SOURCE /)" --snapshot-dir /timeshift \
        || log_error "Fallo configurando Timeshift para /timeshift"

    timeshift --create --comments "Snapshot inicial" --tags D \
        || log_error "Fallo al crear snapshot inicial con Timeshift"

    tee /etc/timeshift.json > /dev/null <<EOF
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

    log_success "✅ grub-btrfs y Timeshift configurados correctamente"
}



# === UTILITARIOS ADICIONALES ===

update_system() {
    log_info "Actualizando el sistema"
    sudo dnf upgrade --refresh -y
    check_error "No se pudo actualizar el sistema"
    log_info "Sistema actualizado correctamente"
}

clean_system() {
    log_info "Limpiando el sistema"
    sudo dnf autoremove -y
    check_error "No se pudo limpiar el sistema (autoremove)"
    sudo dnf clean all
    check_error "No se pudo limpiar la caché de DNF"
    log_info "Sistema limpiado correctamente"
}

# === PROCESAMIENTO DE ARGUMENTOS ===

UPDATE_SYSTEM=0
CLEAN_SYSTEM=0

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -h|--help)
            show_help
            exit 0
            ;;
        -u|--update)
            UPDATE_SYSTEM=1
            shift
            ;;
        -c|--clean)
            CLEAN_SYSTEM=1
            shift
            ;;
        *)
            log_warn "Opción desconocida: $key"
            show_help
            exit 1
            ;;
    esac
done

# === FUNCIÓN PRINCIPAL ===

main() {
    run_sudo

    [[ "$UPDATE_SYSTEM" -eq 1 ]] && update_system

    init_environment
    configure_dnf
    configure_dnf_automatic
    change_hostname
    configure_repositories
    install_essential_packages
    configure_flatpak_repositories
    configure_security
    configure_zswap
    configure_btrfs_volumes
    install_grub_btrfs

    [[ "$CLEAN_SYSTEM" -eq 1 ]] && clean_system

    log_info "Para más configuraciones, revisa los scripts adicionales o consulta la documentación."
    if [[ $ERROR_COUNT -eq 0 ]]; then
        log_info "Script finalizado exitosamente sin errores."
    else
        log_warn "Script finalizado con $ERROR_COUNT error(es)/advertencia(s). Revisa $ERR_FILE para detalles."
    fi
}

main "$@"

# Fin del script principal

exit 0

