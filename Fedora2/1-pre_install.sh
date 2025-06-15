#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ===============================================
# Post-Instalación Fedora 42 - Script Principal
# ===============================================

# === VARIABLES GLOBALES ===
USER_HOME=$(eval echo ~$(logname))
LOGDIR="$USER_HOME/fedora_logs"
LOG_FILE="$LOGDIR/post_install_full.log"
ERR_FILE="$LOGDIR/post_install_errors.log"
ERROR_COUNT=0

# ====== LISTAS DE PAQUETES GLOBALES ======
PACKAGES_ESSENTIALS=(
    vim nano git curl wget htop
    neofetch unzip p7zip p7zip-plugins
    tar gzip bzip2
    zsh bash-completion
)

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


# === FUNCIONES DE LOGGING Y FEEDBACK ===
log_section() {
    local section="$1"
    local date_time; date_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "\n\033[1;34m===== $section =====\033[0m"
    echo "[$date_time] [SECTION] $section" >> "$LOG_FILE"
}

log_info() {
    local msg="$1"
    local date_time; date_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[INFO] $msg"
    echo "[$date_time] [INFO] $msg" >> "$LOG_FILE"
}

log_warn() {
    local msg="$1"
    local date_time; date_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[⚠️ WARNING] $msg"
    echo "[$date_time] [WARNING] $msg" | tee -a "$LOG_FILE" >> "$ERR_FILE"
    ERROR_COUNT=$((ERROR_COUNT+1))
}

log_error() {
    local msg="$1"
    local date_time; date_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[❌ ERROR] $msg"
    echo "[$date_time] [ERROR] $msg" | tee -a "$LOG_FILE" >> "$ERR_FILE"
    ERROR_COUNT=$((ERROR_COUNT+1))
}

log_success() {
    local msg="$1"
    local date_time; date_time=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${GREEN}[✔ SUCCESS] $msg${NC}"
    echo "[$date_time] [SUCCESS] $msg" >> "$LOG_FILE"
}


progress_bar() {
    local progress=$1
    local total=$2
    local bar_size=30
    local filled=$((progress * bar_size / total))
    local empty=$((bar_size - filled))
    printf "\r["
    printf "%0.s#" $(seq 1 $filled)
    printf "%0.s-" $(seq 1 $empty)
    printf "] %d%%" $((progress * 100 / total))
    if [ "$progress" -eq "$total" ]; then
        echo ""
    fi
}

check_error() {
    local exit_code=$?
    local error_msg="$1"
    local fatal="${2:-false}"
    if [ $exit_code -ne 0 ]; then
        log_error "$error_msg (Código: $exit_code)"
        if [ "$fatal" = "true" ]; then
            log_error "Error fatal. Abortando script."
            exit 1
        fi
        return 1
    fi
    return 0
}

init_log() {
    echo "===================================================" > "$LOG_FILE"
    echo "Post-Instalación Fedora 42 - $(date)" >> "$LOG_FILE"
    echo "===================================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    log_info "Iniciando proceso de post-instalación para Fedora 42"
    log_info "Log completo: $LOG_FILE"
    log_info "Solo errores y advertencias: $ERR_FILE"
}

run_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_info "Solicitando privilegios sudo..."
        sudo -v || {
            log_error "No se pudieron obtener privilegios de administrador" "true"
            exit 1
        }
    fi

    # Keep-alive controlado por flag
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
  # 🧱 Pilar 1: Seguridad y robustez
  local PROJECT_ROOT
  PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  local REAL_USER="${SUDO_USER:-$USER}"
  local REAL_HOME
  REAL_HOME=$(eval echo "~$REAL_USER")

  local LOG_TAG="fedora_refactor"
  local REQUIRED_CMDS=(tee dnf command mkdir logger)
  local REQUIRED_SPACE_MB=5000

  if [[ $EUID -ne 0 ]]; then
    echo "❌ Este script debe ejecutarse con privilegios de root (sudo)" >&2
    exit 1
  fi

  # 🧱 Pilar 7: Compliance de comandos base
for cmd in "${REQUIRED_CMDS[@]}"; do
if ! command -v "$cmd" &>/dev/null; then
    echo -e "${YELLOW}⚠️ El comando '$cmd' no está instalado. Intentando instalar...${NC}"

    if [[ "$cmd" == "logger" ]]; then
    dnf install -y --allowerasing --skip-broken --skip-unavailable util-linux &>/dev/null
    else
    dnf install -y --allowerasing --skip-broken --skip-unavailable "$cmd" &>/dev/null || {
        echo -e "${RED}❌ No se pudo instalar '$cmd'. Abortando.${NC}" >&2
        exit 1
    }
    fi
fi
done


  # 🧱 Pilar 3: Logging empresarial
  # Crear carpeta de logs con permisos consistentes
mkdir -p "$LOGDIR"
chmod 775 "$LOGDIR"

# Validar usuario real (fallback a $USER si no hay SUDO_USER)
REAL_USER="${SUDO_USER:-$USER}"

# Validar existencia de logs antes de cambiar permisos
for log_file in install.log error.log; do
    full_path="$LOGDIR/$log_file"
    touch "$full_path"

    # Aplicar permisos si el archivo existe
    if [[ -f "$full_path" ]]; then
        chown "$REAL_USER":"$REAL_USER" "$full_path"
        chmod 664 "$full_path"
    fi
done


  if command -v logger &>/dev/null; then
    exec > >(tee -a "$LOGDIR/install.log" | logger -t "$LOG_TAG" -s) \
         2> >(tee -a "$LOGDIR/error.log" | logger -t "$LOG_TAG" -s >&2)
  else
    exec > >(tee -a "$LOGDIR/install.log") \
         2> >(tee -a "$LOGDIR/error.log" >&2)
  fi

  echo "[INFO] Fedora Refactor – Init Environment"
  echo "[INFO] Proyecto: $PROJECT_ROOT"
  echo "[INFO] Usuario original: $REAL_USER (home: $REAL_HOME)"
  echo "[INFO] Logs en: $LOGDIR (propietario: $REAL_USER)"

  # 🧱 Pilar 5: Compatibilidad y entorno
  if [ -n "${DISPLAY:-}" ]; then
    echo "[INFO] Entorno gráfico detectado: $DISPLAY"
  else
    echo "[INFO] Modo consola / TTY"
  fi

  # 🧱 Pilar 1 y 6: Validación de espacio y CI/CD friendly
 # Validación de espacio en disco (requiere df y awk en modo seguro)
log_info "Verificando espacio disponible en $PROJECT_ROOT..."

AVAILABLE_KB=$(df --output=avail "$PROJECT_ROOT" 2>/dev/null | tail -n 1 | tr -d ' ')
REQUIRED_KB=$((REQUIRED_SPACE_MB * 1024))

if [[ -z "$AVAILABLE_KB" || "$AVAILABLE_KB" -lt "$REQUIRED_KB" ]]; then
    log_error "Espacio insuficiente: se requieren ${REQUIRED_SPACE_MB}MB libres en $PROJECT_ROOT (disponible: $((AVAILABLE_KB / 1024))MB)"
    exit 1
else
    log_info "Espacio libre verificado: $((AVAILABLE_KB / 1024))MB disponibles (requerido: ${REQUIRED_SPACE_MB}MB)"
fi


  echo "[INFO] Espacio libre verificado: OK"
  echo "[INFO] ✅ Entorno inicial preparado correctamente"
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

    if [[ -z "$hostname_var" ]]; then
        read -rp "Introduce el nuevo hostname para este sistema: " hostname_var
    fi

    if [[ -z "$hostname_var" ]]; then
        log_warn "No se especificó un hostname. Se omite el cambio."
        return 0
    fi

    # Validación RFC1123
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
    log_info "Instalando paquetes esenciales del sistema"
    local total=${#PACKAGES_ESSENTIALS[@]}
    for i in "${!PACKAGES_ESSENTIALS[@]}"; do
        sudo dnf install -y --allowerasing --skip-broken --skip-unavailable "${PACKAGES_ESSENTIALS[$i]}"
        check_error "No se pudo instalar ${PACKAGES_ESSENTIALS[$i]}"
        progress_bar "$((i + 1))" "$total"
    done
    log_info "Paquetes esenciales instalados correctamente"
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
        sudo flatpak remote-add --if-not-exists "$remote" "$url" &>/dev/null || log_warn "No se pudo agregar el remoto $remote"

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
    log_info "Configurando seguridad del sistema"

   # Validar si timeshift está disponible, e instalarlo si no lo está
if ! command -v timeshift &>/dev/null; then
    log_info "Timeshift no está instalado. Procediendo con la instalación..."
    sudo dnf install -y --allowerasing --skip-broken --skip-unavailable timeshift
    check_error "No se pudo instalar Timeshift"
fi

# Crear snapshot de seguridad
log_info "Creando snapshot de seguridad con Timeshift..."
if ! sudo timeshift --create --comments "pre-security-update" --tags D &>/dev/null; then
    log_warn "No se pudo crear snapshot de seguridad con Timeshift"
else
    log_success "Snapshot de seguridad creado correctamente"
fi


    log_info "Instalando paquetes de seguridad..."
    sudo dnf install -y --allowerasing --skip-broken --skip-unavailable  --skip-broken \
        resolvconf firewalld firewall-config selinux-policy selinux-policy-targeted \
        policycoreutils policycoreutils-python-utils setools npm

    log_info "Habilitando firewall..."
    sudo systemctl enable --now firewalld &>/dev/null
    if ! check_error "No se pudo habilitar firewalld"; then
        log_warn "Error al activar firewalld, pero continuando"
    fi

    log_info "Configurando SELinux en modo enforcing..."
    sudo sed -i 's/SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

    log_info "Configurando reglas de firewall..."
    sudo firewall-cmd --set-default-zone=FedoraWorkstation &>/dev/null
    sudo firewall-cmd --complete-reload &>/dev/null

    sudo firewall-cmd --zone=FedoraWorkstation --remove-port=1-65535/tcp --permanent &>/dev/null
    sudo firewall-cmd --zone=FedoraWorkstation --remove-port=1-65535/udp --permanent &>/dev/null

    enabled_ports=$(sudo firewall-cmd --zone=FedoraWorkstation --list-ports 2>/dev/null)
    if [ -n "$enabled_ports" ]; then
        read -r -a ports_array <<< "$enabled_ports"
        for port in "${ports_array[@]}"; do
            sudo firewall-cmd --zone=FedoraWorkstation --remove-port="$port" --permanent &>/dev/null
        done
    fi

    sudo firewall-cmd --reload &>/dev/null

    sudo firewall-cmd --add-interface=lo --zone=FedoraWorkstation --permanent &>/dev/null

    declare -a services=(http https ssh samba dns dhcpv6-client ping)
    declare -a ports=("22/tcp" "631/tcp" "1194/udp" "5353/udp" "33434-33523/udp")

    log_info "Habilitando servicios esenciales en firewall..."
    for service in "${services[@]}"; do
        sudo firewall-cmd --add-service="$service" --zone=FedoraWorkstation --permanent &>/dev/null
    done

    log_info "Habilitando puertos esenciales en firewall..."
    for port in "${ports[@]}"; do
        sudo firewall-cmd --add-port="$port" --zone=FedoraWorkstation --permanent &>/dev/null
    done

    sudo firewall-cmd --reload &>/dev/null

    log_info "Ajustando SELinux para firewalld..."
    sudo semanage permissive -a firewalld_t &>/dev/null

    log_info "Configurando servidores DNS seguros..."
    sudo mkdir -p '/etc/systemd/resolved.conf.d'
    echo -e "[Resolve]\nDNS=94.140.14.14 94.140.15.15 1.1.1.1 1.0.0.1 8.8.8.8 8.8.4.4\nDNSOverTLS=yes" \
        | sudo tee /etc/systemd/resolved.conf.d/99-dns-over-tls.conf > /dev/null
    sudo systemctl restart systemd-resolved &>/dev/null

    if ! command -v npm &>/dev/null; then
  log_info "Instalando npm..."
  dnf install -y --allowerasing --skip-broken --skip-unavailable npm
  check_error "No se pudo instalar npm"
fi

log_info "Instalando bloqueador de anuncios (hblock)..."
npm install -g hblock &>/dev/null
if ! command -v hblock &>/dev/null; then
  log_warn "hblock no se instaló correctamente con npm"
else
  hblock &>/dev/null
fi

    log_info "Configuración de seguridad completada"
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

install_grub_btrfs() {
  log_section "🔄 Instalación y configuración de grub-btrfs + Timeshift"

  dnf copr enable -y kylegospo/grub-btrfs
  dnf update -y
  dnf install -y --allowerasing --skip-broken --skip-unavailable grub-btrfs grub-btrfs-timeshift timeshift

  log_info "Configurando GRUB..."
  mkdir -p /etc/default/grub-btrfs
  tee /etc/default/grub-btrfs/config > /dev/null <<EOF
GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"
GRUB_BTRFS_MKCONFIG=/sbin/grub2-mkconfig
GRUB_BTRFS_SCRIPT_CHECK=grub2-script-check
GRUB_BTRFS_SUBMENUNAME="Snapshots BTRFS"
GRUB_BTRFS_SNAPSHOT_FORMAT="%Y-%m-%d %H:%M | %c"
GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="rootflags=subvol=@ quiet"
EOF

  grub2-mkconfig -o /boot/grub2/grub.cfg

  log_info "Habilitando grub-btrfs.path..."
  systemctl enable --now grub-btrfs.path

  log_info "Configurando Timeshift para snapshots automáticos..."
  mkdir -p /timeshift
  timeshift --btrfs --snapshot-device "$(findmnt -no SOURCE /)" --snapshot-dir /timeshift || log_error "Fallo configurando Timeshift."
  timeshift --create --comments "Snapshot inicial" || log_error "Fallo al crear snapshot inicial."

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

  log_success "✅ grub-btrfs y Timeshift configurados correctamente."
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
    init_log
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

