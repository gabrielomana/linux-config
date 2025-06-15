#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ===============================================
# Post-Instalación Fedora 42 - Script Principal
# ===============================================

# === VARIABLES GLOBALES ===
USER_HOME=$(eval echo ~$(logname))
LOG_DIR="$USER_HOME/fedora_logs"
LOG_FILE="$LOG_DIR/post_install_full.log"
ERR_FILE="$LOG_DIR/post_install_errors.log"
ERROR_COUNT=0

# ====== LISTAS DE PAQUETES GLOBALES ======
PACKAGES_ESSENTIALS=(
    vim nano git curl wget htop
    neofetch unzip p7zip p7zip-plugins
    tar gzip bzip2
    zsh bash-completion
)

# === PREPARACIÓN DE LOGS ===
mkdir -p "$LOG_DIR"
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
    sudo -n true 2>/dev/null || {
        log_info "Se necesitan privilegios de administrador para continuar"
        sudo -v || {
            log_error "No se pudieron obtener privilegios de administrador" "true"
            exit 1
        }
    }
    (
        while true; do
            sudo -n true
            sleep 50
        done
    ) &
    SUDO_PID=$!
    trap "kill -9 $SUDO_PID" EXIT
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
    sudo dnf install -y dnf-automatic
    check_error "No se pudo instalar dnf-automatic"
    sudo cp /usr/lib/systemd/system/dnf-automatic.timer /etc/systemd/system/
    check_error "No se pudo copiar el timer de dnf-automatic"
    sudo systemctl enable --now dnf-automatic.timer
    check_error "No se pudo habilitar dnf-automatic.timer"
    log_info "DNF Automatic configurado correctamente"
}

change_hostname() {
    log_info "Cambiando el hostname del sistema"
    local hostname_var="${NEW_HOSTNAME:-}"
    if [[ -z "$hostname_var" ]]; then
        read -rp "Introduce el nuevo hostname para este sistema: " hostname_var
    fi
    if [[ -z "$hostname_var" ]]; then
        log_warn "No se especificó un hostname. Se omite el cambio de hostname."
        return 0
    fi
    sudo hostnamectl set-hostname "$hostname_var"
    check_error "No se pudo cambiar el hostname"
    log_info "Hostname cambiado a $hostname_var"
}

configure_repositories() {
    log_info "Configurando repositorios adicionales"
    log_info "Instalando repositorios de Fedora Workstation..."
    sudo dnf -y --quiet install fedora-workstation-repositories
    if ! check_error "No se pudieron instalar los repositorios de Fedora Workstation"; then
        log_warn "Continuando sin los repositorios Workstation"
    fi
    log_info "Instalando repositorios RPM Fusion (Free y NonFree)..."
    sudo dnf -y --quiet install \
        https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    if check_error "No se pudieron instalar los repositorios RPM Fusion"; then
        log_info "Repositorios RPM Fusion instalados correctamente"
    else
        log_warn "Continuando sin los repositorios RPM Fusion"
    fi
    log_info "Actualizando caché de repositorios..."
    sudo dnf clean all -q
    sudo dnf makecache --refresh -q
    sudo dnf update -y -q
    sudo dnf upgrade -y -q
    sudo dnf -y -q group upgrade core
    log_info "Repositorios configurados y actualizados"
}

install_essential_packages() {
    log_info "Instalando paquetes esenciales del sistema"
    local total=${#PACKAGES_ESSENTIALS[@]}
    for i in "${!PACKAGES_ESSENTIALS[@]}"; do
        sudo dnf install -y "${PACKAGES_ESSENTIALS[$i]}"
        check_error "No se pudo instalar ${PACKAGES_ESSENTIALS[$i]}"
        progress_bar "$((i + 1))" "$total"
    done
    log_info "Paquetes esenciales instalados correctamente"
}

configure_flatpak_repositories() {
    log_info "Configurando repositorios Flatpak"

    log_info "Instalando Flatpak..."
    sudo dnf -y --quiet install flatpak
    if ! check_error "No se pudo instalar Flatpak"; then
        log_warn "Error al instalar Flatpak. Saliendo de esta fase."
        return 1
    fi

    log_info "Agregando repositorios Flatpak..."
    sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo &>/dev/null
    sudo flatpak remote-add --if-not-exists elementary https://flatpak.elementary.io/repo.flatpakrepo &>/dev/null
    sudo flatpak remote-add --if-not-exists kde https://distribute.kde.org/kdeapps.flatpakrepo &>/dev/null
    sudo flatpak remote-add --if-not-exists fedora oci+https://registry.fedoraproject.org &>/dev/null

    sudo flatpak remote-modify --system --prio=1 kde &>/dev/null || log_warn "No se pudo configurar prioridad de KDE"
    sudo flatpak remote-modify --system --prio=2 flathub &>/dev/null || log_warn "No se pudo configurar prioridad de Flathub"
    sudo flatpak remote-modify --system --prio=3 elementary &>/dev/null || log_warn "No se pudo configurar prioridad de Elementary"
    sudo flatpak remote-modify --system --prio=4 fedora &>/dev/null || log_warn "No se pudo configurar prioridad de Fedora"

    log_info "Repositorios Flatpak configurados correctamente"
}

configure_zswap() {
    log_info "Configurando ZSWAP para mejor rendimiento del sistema"

    log_info "Eliminando zram-generator si existe..."
    sudo dnf remove -y zram-generator &>/dev/null

    log_info "Actualizando sistema antes de configurar ZSWAP..."
    sudo dnf update -y -q

    log_info "Habilitando algoritmo de compresión lz4hc..."
    sudo modprobe lz4hc &>/dev/null
    if ! check_error "No se pudo cargar el módulo lz4hc"; then
        log_warn "Continuando sin optimización de ZSWAP"
        return 1
    fi

    log_info "Configurando dracut para ZSWAP..."
    sudo mkdir -p /etc/dracut.conf.d
    echo 'add_drivers+="lz4hc"' | sudo tee /etc/dracut.conf.d/lz4hc.conf > /dev/null

    log_info "Regenerando initramfs (esto puede tardar unos minutos)..."
    sudo dracut --regenerate-all --force &>/dev/null
    if ! check_error "No se pudo regenerar initramfs"; then
        log_warn "Error al regenerar initramfs, pero continuando"
    fi

    echo "lz4hc" | sudo tee /sys/module/zswap/parameters/compressor &>/dev/null

    log_info "Optimizando ZSWAP según memoria del sistema..."
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
    echo "vm.swappiness=$swappiness" | sudo tee "$sysctl_conf" > /dev/null
    echo "vm.vfs_cache_pressure=$vfs_cache_pressure" | sudo tee -a "$sysctl_conf" > /dev/null
    sudo sysctl -p "$sysctl_conf" &>/dev/null

    log_info "Configurando GRUB para ZSWAP..."
    grub_file="/etc/default/grub"
    sudo cp "$grub_file" "$grub_file.bak"
    sudo sed -i '/^GRUB_CMDLINE_LINUX_DEFAULT=/ s/"$/ zswap.enabled=1 zswap.max_pool_percent='"$zswap_max_pool"' zswap.zpool=z3fold zswap.compressor=lz4hc"/' "$grub_file"
    sudo grub2-mkconfig -o /boot/grub2/grub.cfg &>/dev/null
    if ! check_error "No se pudo actualizar GRUB"; then
        log_warn "Error al actualizar GRUB, pero continuando"
    fi

    script_file="/usr/local/bin/zswap-monitor"
    script_content='#!/bin/bash
MDL=/sys/module/zswap
DBG=/sys/kernel/debug/zswap
PAGE=$(( $(cat $DBG/stored_pages 2>/dev/null || echo 0) * 4096 ))
POOL=$(( $(cat $DBG/pool_total_size 2>/dev/null || echo 0) ))
Show(){
    printf "========\n$1\n========\n"
    grep -R . $2 2>&1 | sed "s|.*/||"
}
Show "ZSWAP Settings" $MDL
Show "ZSWAP Statistics" $DBG
printf "\nCompression ratio: "
[ $POOL -gt 0 ] && {
    echo "scale=3; $PAGE / $POOL" | bc
} || echo "ZSWAP disabled"'

    echo "$script_content" | sudo tee "$script_file" > /dev/null
    sudo chmod +x "$script_file"

    log_info "ZSWAP configurado correctamente"
    log_info "Puedes ver estadísticas de ZSWAP con: sudo zswap-monitor"
}

configure_security() {
    log_info "Configurando seguridad del sistema"

    log_info "Creando snapshot de seguridad con Timeshift..."
    sudo timeshift --create --comments "pre-security-update" --tags D &>/dev/null || log_warn "No se pudo crear snapshot con Timeshift"

    log_info "Instalando paquetes de seguridad..."
    sudo dnf install -y --skip-unavailable --skip-broken \
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

    log_info "Configurando bloqueador de anuncios y trackers..."
    sudo npm install -g hblock &>/dev/null
    hblock &>/dev/null

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

  run_cmd dnf install -y --skip-broken btrfs-progs inotify-tools

  log_info "Respaldando fstab..."
  run_cmd cp /etc/fstab /etc/fstab.old
  local output_file="/etc/fstab.new"
  cp /etc/fstab "$output_file"

  get_uuid() {
    grep -E "$1\s+btrfs\s+" /etc/fstab | awk '{print $1}' | sed -n 's/UUID=\(.*\)/\1/p'
  }

  declare -A subvolumes=(
    ["/"]="@"
    ["/var/log"]="@log"
    ["/var/tmp"]="@var_tmp"
    ["/tmp"]="@tmp"
    ["/timeshift"]="@timeshift"
  )

  for mount_point in "${!subvolumes[@]}"; do
    local uuid
    uuid=$(get_uuid "$mount_point")
    if [[ -n "$uuid" ]]; then
      sed -i -E \
        "s|UUID=.*\s+$mount_point\s+btrfs.*|UUID=$uuid $mount_point btrfs rw,noatime,compress=zstd:3,space_cache=v2,subvol=${subvolumes[$mount_point]} 0 0|" \
        "$output_file"
    fi
  done

  run_cmd cp "$output_file" /etc/fstab

  log_info "Aplicando compresión y balanceo inicial..."
  btrfs filesystem defragment -r -czstd:3 / &>/dev/null || true
  btrfs balance start -m / &>/dev/null || true

  log_success "Subvolúmenes BTRFS configurados correctamente."
}

install_grub_btrfs() {
  log_section "🔄 Instalación y configuración de grub-btrfs + Timeshift"

  run_cmd dnf copr enable -y kylegospo/grub-btrfs
  run_cmd dnf update -y
  run_cmd dnf install -y grub-btrfs grub-btrfs-timeshift

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

  run_cmd grub2-mkconfig -o /boot/grub2/grub.cfg

  log_info "Habilitando grub-btrfs.path..."
  run_cmd systemctl enable --now grub-btrfs.path

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

    configure_dnf
    configure_dnf_automatic
    change_hostname
    configure_repositories
    install_essential_packages
    configure_flatpak_repositories
    configure_security
    configure_zswap
    configure_btrfs_volumes
    instalar_grub_btrfs

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

