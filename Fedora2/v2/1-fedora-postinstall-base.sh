#!/bin/bash
# Fedora 42 Post-Install Script – Optimized with try_cmd for error-tolerant execution

set -euo pipefail
IFS=$'\n\t'

trap 'cleanup_on_exit' EXIT
trap 'cleanup_on_error ${LINENO} "$BASH_COMMAND"' ERR

readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_VERSION="2.1"
readonly MIN_DISK_SPACE_MB=5000
readonly SUPPORTED_FEDORA_VERSIONS=(42 43 44)

declare -g REAL_USER="${SUDO_USER:-$USER}"
declare -g USER_HOME
declare -g TIMESTAMP
declare -g LOG_DIR
declare -g LOG_FILE
declare -g ERR_FILE
declare -g ERROR_COUNT=0
declare -g VERBOSE=0
declare -g UPDATE_SYSTEM=0
declare -g CLEAN_SYSTEM=0

readonly ESSENTIAL_PACKAGES=(vim nano git curl wget htop neofetch unzip p7zip p7zip-plugins tar gzip bzip2 zsh bash-completion tree fd-find ripgrep bat)
readonly SECURITY_PACKAGES=(firewalld firewall-config selinux-policy selinux-policy-targeted policycoreutils policycoreutils-python-utils fail2ban aide rkhunter clamav clamav-update)
readonly NETWORK_PACKAGES=(samba samba-client avahi nss-mdns ftp lftp openssh-clients bluez-obexd kde-connect qt6-qml kde-connectd rclone fuse NetworkManager-tui)

setup_colors() {
    if [[ -t 1 ]] && command -v tput >/dev/null 2>&1; then
        readonly RED="$(tput setaf 1)"
        readonly GREEN="$(tput setaf 2)"
        readonly YELLOW="$(tput setaf 3)"
        readonly BLUE="$(tput setaf 4)"
        readonly CYAN="$(tput setaf 6)"
        readonly BOLD="$(tput bold)"
        readonly NC="$(tput sgr0)"
    else
        readonly RED="" GREEN="" YELLOW="" BLUE="" CYAN="" BOLD="" NC=""
    fi
}

log_message() {
    local level="$1"
    local msg="$2"
    local color="${3:-$NC}"
    local icon="${4:-ℹ️}"
    local status="${5:-INFO}"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    printf "${color}[%s] %-8s %s${NC}
" "$icon" "$level" "$msg"
    [[ -f "$LOG_FILE" ]] && printf "[%s] [%-8s] %s
" "$timestamp" "$level" "$msg" >> "$LOG_FILE"
    [[ $VERBOSE -eq 1 && "$level" == "DEBUG" ]] && printf "${CYAN}[DEBUG] %s${NC}
" "$msg" >&2
}

log_info() { log_message "INFO" "$1" "$BLUE" "ℹ️"; }
log_success() { log_message "SUCCESS" "$1" "$GREEN" "✅"; }
log_warn() { log_message "WARNING" "$1" "$YELLOW" "⚠️" "WARN"; echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "$ERR_FILE" 2>/dev/null || true; ((ERROR_COUNT++)); }
log_error() { log_message "ERROR" "$1" "$RED" "❌" "FAIL"; echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$ERR_FILE" 2>/dev/null || true; ((ERROR_COUNT++)); }
log_debug() { [[ $VERBOSE -eq 1 ]] && log_message "DEBUG" "$1" "$CYAN" "🔍"; }

log_section() {
    local title="$1"
    local width=80
    local padding=$(( (width - ${#title} - 4) / 2 ))
    local border=$(printf '═%.0s' $(seq 1 $width))
    echo -e "\n${CYAN}┌${border}┐${NC}"
    printf "${CYAN}│%*s  ${BOLD}%s${NC}${CYAN}  %*s│${NC}\n" $padding "" "$title" $padding ""
    echo -e "${CYAN}└${border}┘${NC}\n"
    [[ -f "$LOG_FILE" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] $title" >> "$LOG_FILE"
}

try_cmd() {
    local description="$1"; shift; local cmd=("$@")
    log_info "[TRY] 🔄 $description"
    if "${cmd[@]}" >/dev/null 2>&1; then
        log_success "[TRY] ✅ $description"
    else
        log_warn "[TRY] ⚠️ Falló: $description"
    fi
}


# ========== FUNCIONES DE SISTEMA CON try_cmd APLICADO ==========

cleanup_on_exit() {
    local exit_code=$?
    if [[ -n "${SUDO_PID:-}" ]]; then
        try_cmd "Detener proceso sudo keepalive" kill "$SUDO_PID"
    fi

    if [[ $ERROR_COUNT -gt 0 ]]; then
        log_warn "Script completed with $ERROR_COUNT errors. Check $ERR_FILE for details."
    else
        log_success "Script completed successfully!"
    fi

    if [[ "$REAL_USER" != "root" && -f "$LOG_FILE" ]]; then
        try_cmd "Cambiar ownership de logs" chown "$REAL_USER:$REAL_USER" "$LOG_FILE" "$ERR_FILE"
    fi

    exit $exit_code
}

cleanup_on_error() {
    local line_no=$1
    local failed_command=$2
    log_error "Script failed at line $line_no: $failed_command"
}

init_environment() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        REAL_USER="$SUDO_USER"
        USER_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
    elif [[ "$USER" != "root" ]]; then
        REAL_USER="$USER"
        USER_HOME="$HOME"
    else
        REAL_USER="root"
        USER_HOME="/root"
    fi

    [[ ! -d "$USER_HOME" ]] && USER_HOME="/tmp"
    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
    LOG_DIR="$USER_HOME/fedora_logs"
    mkdir -p "$LOG_DIR" 2>/dev/null || LOG_DIR="/tmp/fedora_logs_$TIMESTAMP" && mkdir -p "$LOG_DIR"

    LOG_FILE="$LOG_DIR/install_$TIMESTAMP.log"
    ERR_FILE="$LOG_DIR/error_$TIMESTAMP.log"

    touch "$LOG_FILE" "$ERR_FILE"
    chmod 644 "$LOG_FILE" "$ERR_FILE" 2>/dev/null || true
    [[ "$REAL_USER" != "root" ]] && chown "$REAL_USER:$REAL_USER" "$LOG_FILE" "$ERR_FILE" 2>/dev/null || true

    log_section "🚀 Environment Initialization"
    log_info "Script version: $SCRIPT_VERSION"
    log_info "Real user: $REAL_USER"
    log_info "Home directory: $USER_HOME"
    log_info "Log directory: $LOG_DIR"
    log_info "Verbose mode: $([[ $VERBOSE -eq 1 ]] && echo enabled || echo disabled)"
    log_success "Environment initialized successfully"
}

ensure_sudo() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root. Use 'sudo' or switch to root user."
        exit 1
    fi
    log_info "Running as root — OK"
}

check_prerequisites() {
    log_section "🔍 System Prerequisites Check"

    if [[ -f /etc/fedora-release ]]; then
        local fedora_version
        fedora_version=$(grep -oP 'Fedora.*?release \K\d+' /etc/fedora-release)
        log_info "Detected Fedora version: $fedora_version"
        if [[ " ${SUPPORTED_FEDORA_VERSIONS[@]} " =~ (^|[[:space:]])"$fedora_version"($|[[:space:]]) ]]; then
            log_success "Fedora $fedora_version detected (supported)"
        else
            log_warn "Fedora $fedora_version may not be fully supported"
        fi
    else
        log_error "This script is designed for Fedora Linux"
        return 1
    fi

    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_success "Internet connection verified"
    else
        log_error "No internet connection available"
        return 1
    fi

    if findmnt -n -o FSTYPE / | grep -q btrfs; then
        log_success "BTRFS root filesystem detected"
    else
        log_warn "BTRFS not detected. Some features may not work properly."
    fi

    local available_mb
    available_mb=$(df --output=avail / | tail -n1 | awk '{print int($1/1024)}')
    if [[ $available_mb -gt $MIN_DISK_SPACE_MB ]]; then
        log_success "Sufficient disk space: ${available_mb}MB available"
    else
        log_error "Insufficient disk space. Required: ${MIN_DISK_SPACE_MB}MB, Available: ${available_mb}MB"
        return 1
    fi

    log_success "All prerequisites satisfied"
}


configure_dnf() {
    log_section "⚙️ DNF Optimization"

    try_cmd "Configurar RTC en modo UTC" sudo timedatectl set-local-rtc 0
    try_cmd "Habilitar NTP" sudo timedatectl set-ntp true

    log_info "[DNF] 💾 Respaldando configuración actual de DNF"
    local dnf_conf="/etc/dnf/dnf.conf"
    local backup_conf="${dnf_conf}.backup.$(date +%Y%m%d)"

    if [[ -f "$dnf_conf" ]]; then
        if [[ ! -f "$backup_conf" ]]; then
            try_cmd "Crear backup de dnf.conf" sudo cp "$dnf_conf" "$backup_conf"
        else
            log_info "[DNF] Ya existía backup previo: $backup_conf"
        fi
    else
        log_warn "[DNF] Archivo no encontrado: $dnf_conf"
    fi

    log_info "[DNF] 🛠️ Aplicando parámetros optimizados"
    sudo tee "$dnf_conf" > /dev/null << 'EOF'
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
timeout=30
retries=3
throttle=0
minrate=1000
metadata_expire=3600
countme=False
EOF

    log_success "[DNF] ✅ Configuración optimizada aplicada con éxito"
}

configure_automatic_updates() {
    log_section "🔄 Automatic Updates Setup"

    run_cmd sudo dnf install -y dnf-automatic
    local auto_conf="/etc/dnf/automatic.conf"

    if [[ -f "$auto_conf" ]]; then
        try_cmd "Activar apply_updates" sudo sed -i 's/^apply_updates =.*/apply_updates = yes/' "$auto_conf"
        try_cmd "Configurar emisión por email" sudo sed -i 's/^emit_via =.*/emit_via = email/' "$auto_conf"
    else
        log_warn "[AUTO] Archivo de configuración no encontrado: $auto_conf"
    fi

    try_cmd "Habilitar y activar dnf-automatic.timer" sudo systemctl enable --now dnf-automatic.timer

    if systemctl is-active --quiet dnf-automatic.timer; then
        log_success "[AUTO] ✅ Actualizaciones automáticas activadas"
    else
        log_warn "[AUTO] ⚠️ El timer de dnf-automatic no está activo"
    fi
}

configure_hostname() {
    log_section "🖥️ Hostname Configuration"

    local current_hostname
    current_hostname=$(hostnamectl --static 2>/dev/null || echo "unknown")
    local new_hostname="${NEW_HOSTNAME:-}"

    log_info "Current hostname: $current_hostname"

    if [[ -z "$new_hostname" && -t 0 ]]; then
        echo -ne "${BLUE}Enter new hostname (current: $current_hostname, or press Enter to skip): ${NC}"
        read -r new_hostname
    fi

    if [[ -z "$new_hostname" ]]; then
        log_info "Hostname configuration skipped"
        return 0
    fi

    if [[ ! "$new_hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
        log_warn "Invalid hostname format: $new_hostname"
        return 0
    fi

    if [[ "$current_hostname" == "$new_hostname" ]]; then
        log_info "Hostname already set to: $new_hostname"
        return 0
    fi

    try_cmd "Aplicar nuevo hostname" sudo hostnamectl set-hostname --static "$new_hostname"

    if grep -q "127.0.1.1" /etc/hosts; then
        try_cmd "Actualizar /etc/hosts" sudo sed -i "s/127.0.1.1.*/127.0.1.1 $new_hostname.localdomain $new_hostname/" /etc/hosts
    else
        echo "127.0.1.1 $new_hostname.localdomain $new_hostname" | sudo tee -a /etc/hosts >/dev/null ||             log_warn "No se pudo agregar el hostname a /etc/hosts"
    fi

    log_success "Hostname set to: $new_hostname"
}


install_packages() {
    local package_group="$1"
    local -n packages_ref

    case "$package_group" in
        "essential") packages_ref=ESSENTIAL_PACKAGES ;;
        "security") packages_ref=SECURITY_PACKAGES ;;
        "network") packages_ref=NETWORK_PACKAGES ;;
        *) log_error "Unknown package group: $package_group"; return 1 ;;
    esac

    log_section "📦 Installing ${package_group^} Packages"

    local total=${#packages_ref[@]}
    local installed=0
    local failed=0

    for i in "${!packages_ref[@]}"; do
        local pkg="${packages_ref[$i]}"

        if rpm -q "$pkg" >/dev/null 2>&1; then
            log_debug "Package already installed: $pkg"
            ((installed++))
        else
            log_info "Installing: $pkg"
            if sudo dnf install -y --allowerasing --skip-broken --skip-unavailable "$pkg" >/dev/null 2>&1; then
                log_success "Installed: $pkg"
                ((installed++))
            else
                log_warn "Failed to install: $pkg"
                ((failed++))
            fi
        fi

        show_progress "$((i + 1))" "$total"
    done

    log_info "Package installation summary: $installed installed, $failed failed"
    log_success "Package group '$package_group' installation completed"
}

clean_system() {
    log_section "🧹 System Cleanup"

    local space_before
    space_before=$(df --output=used / | tail -n1)

    run_cmd sudo dnf autoremove -y
    run_cmd sudo dnf clean all
    try_cmd "Vaciar journal logs antiguos" sudo journalctl --vacuum-time=7d

    if [[ -d "$USER_HOME/.cache" ]]; then
        try_cmd "Eliminar caché del usuario" find "$USER_HOME/.cache" -type f -atime +7 -delete
    fi

    local space_after
    space_after=$(df --output=used / | tail -n1)
    local space_freed=$(( (space_before - space_after) / 1024 ))

    log_success "System cleanup completed. Space freed: ${space_freed}MB"
}

main() {
    local start_time
    start_time=$(date +%s)

    setup_colors
    init_environment

    cat << EOF

${CYAN}╔════════════════════════════════════════════════════════════════════════════════╗
║                      ${BOLD}Fedora $SCRIPT_VERSION Post-Install Script${NC}${CYAN}                      ║
║                           ${YELLOW}Professional Configuration Suite${NC}${CYAN}                          ║
╚════════════════════════════════════════════════════════════════════════════════╝${NC}

EOF

    parse_arguments "$@"
    check_prerequisites
    ensure_sudo

    [[ $UPDATE_SYSTEM -eq 1 ]] && update_system

    configure_dnf
    configure_automatic_updates

    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "    9. Instalar paquetes esenciales"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    install_packages "essential"
    install_packages "security"
    install_packages "network"

    configure_hostname

    [[ $CLEAN_SYSTEM -eq 1 ]] && clean_system

    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_section "📊 Installation Summary"
    log_info "Script version: $SCRIPT_VERSION"
    log_info "Execution time: ${duration} seconds"
    log_info "Total errors: $ERROR_COUNT"
    log_info "Log file: $LOG_FILE"

    if [[ $ERROR_COUNT -eq 0 ]]; then
        log_success "All configurations completed successfully!"
    else
        log_warn "Completed with $ERROR_COUNT errors. Check logs for details."
    fi

    echo -e "\n${GREEN}${BOLD}🎉 Fedora post-installation configuration completed!${NC}"
    echo -e "${CYAN}Please reboot your system to ensure all changes take effect.${NC}\n"
}

main "$@"


# ══════════════════════════════════════════════════════════════════════════════
# MAIN FUNCTION
# ══════════════════════════════════════════════════════════════════════════════

main() {
    local start_time=$(date +%s)

    setup_colors
    parse_arguments "$@"
    init_environment
    ensure_sudo

    log_section "✨ Fedora $SCRIPT_VERSION Post-Install Script"

    [[ $UPDATE_SYSTEM -eq 1 ]] && update_system

    configure_dnf
    configure_automatic_updates

    install_packages "essential"
    install_packages "security"
    install_packages "network"

    configure_hostname
    configure_flatpak
    configure_firewall
    configure_selinux
    configure_dns
    configure_ssh_security
    enable_system_services

    install_grub_btrfs
    configure_grub_btrfs
    setup_timeshift
    create_initial_snapshot
    finalize_grub_btrfs
    verify_snapshot_setup

    [[ $CLEAN_SYSTEM -eq 1 ]] && clean_system

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    log_section "📊 Installation Summary"
    log_info "Script version: $SCRIPT_VERSION"
    log_info "Execution time: ${duration} seconds"
    log_info "Total errors: $ERROR_COUNT"
    log_info "Log file: $LOG_FILE"

    if [[ $ERROR_COUNT -eq 0 ]]; then
        log_success "All configurations completed successfully!"
    else
        log_warn "Completed with $ERROR_COUNT errors. Check logs for details."
    fi

    echo -e "\n${GREEN}${BOLD}🎉 Fedora post-installation configuration completed!${NC}"
    echo -e "${CYAN}Please reboot your system to ensure all changes take effect.${NC}\n"
}

main "$@"
