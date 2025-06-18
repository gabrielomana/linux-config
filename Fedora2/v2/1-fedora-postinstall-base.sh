#!/bin/bash
# ──────────────────────────────────────────────────────────────────────────────
# Fedora 42 Post-Install Script – Professional Hardening & Configuration Suite
# 
# Description:
#   Automated secure and optimal post-install configuration for Fedora 42
#   workstation/server environments with system hardening, network security,
#   BTRFS snapshots with grub-btrfs and Timeshift integration.
#
# Author: Gabriel Omaña – Initium | https://initiumsoft.com
# Version: 2.1 (Optimized)
# License: MIT
# Created: 2025-06-17
# Compatible with: Fedora 42+ (Bash 5.1+, systemd, BTRFS root)
# 
# Usage: sudo ./fedora_postinstall.sh [--update] [--clean] [--verbose]
# ──────────────────────────────────────────────────────────────────────────────

# Configuración estricta de Bash
set -euo pipefail
IFS=$'\n\t'

# Captura de señales para limpieza
trap 'cleanup_on_exit' EXIT
trap 'cleanup_on_error ${LINENO} "$BASH_COMMAND"' ERR

# ══════════════════════════════════════════════════════════════════════════════
# CONFIGURACIÓN GLOBAL Y CONSTANTES
# ══════════════════════════════════════════════════════════════════════════════

readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_VERSION="2.1"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly MIN_DISK_SPACE_MB=5000
readonly SUPPORTED_FEDORA_VERSIONS=(42 43 44)

# Variables de entorno
declare -g REAL_USER="${SUDO_USER:-$USER}"
declare -g USER_HOME
declare -g TIMESTAMP
declare -g LOG_DIR
declare -g LOG_FILE
declare -g ERR_FILE
declare -g ERROR_COUNT=0
declare -g VERBOSE=0
declare -g SUDO_PID=""

# Opciones de línea de comandos
declare -g UPDATE_SYSTEM=0
declare -g CLEAN_SYSTEM=0

# Colecciones de paquetes optimizadas
readonly ESSENTIAL_PACKAGES=(
    "vim"
    "nano" 
    "git"
    "curl"
    "wget"
    "htop"
    "neofetch"
    "unzip"
    "p7zip"
    "p7zip-plugins"
    "tar"
    "gzip"
    "bzip2"
    "zsh"
    "bash-completion"
    "tree"
    "fd-find"
    "ripgrep"
    "bat"
)

readonly SECURITY_PACKAGES=(
    "firewalld"
    "firewall-config"
    "selinux-policy"
    "selinux-policy-targeted"
    "policycoreutils"
    "policycoreutils-python-utils"
    "fail2ban"
    "aide"
    "rkhunter"
    "clamav"
    "clamav-update"
)

readonly NETWORK_PACKAGES=(
    "samba"
    "samba-client"
    "avahi"
    "nss-mdns"
    "ftp"
    "lftp"
    "openssh-clients"
    "bluez-obexd"
    "kde-connect"
    "qt6-qml"
    "kde-connectd"
    "rclone"
    "fuse"
    "NetworkManager-tui"
)

# ══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE UTILIDAD MEJORADAS
# ══════════════════════════════════════════════════════════════════════════════

# Configuración de colores optimizada
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

# Sistema de logging mejorado con niveles
log_message() {
    local level="$1"
    local msg="$2"
    local color="${3:-$NC}"
    local icon="${4:-ℹ️}"
    local status="${5:-INFO}"
    
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Output a stdout con formato
    printf "${color}[%s] %-8s %s${NC}\n" "$icon" "$level" "$msg"
    
    # Log a archivo si está disponible
    if [[ -f "$LOG_FILE" ]]; then
        printf "[%s] [%-8s] %s\n" "$timestamp" "$level" "$msg" >> "$LOG_FILE"
    fi
    
    # Verbose mode
    if [[ $VERBOSE -eq 1 && "$level" == "DEBUG" ]]; then
        printf "${CYAN}[DEBUG] %s${NC}\n" "$msg" >&2
    fi
}

log_info() { log_message "INFO" "$1" "$BLUE" "ℹ️"; }
log_success() { log_message "SUCCESS" "$1" "$GREEN" "✅"; }
log_warn() { 
    log_message "WARNING" "$1" "$YELLOW" "⚠️" "WARN"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "$ERR_FILE" 2>/dev/null || true
    ((ERROR_COUNT++))
}
log_error() { 
    log_message "ERROR" "$1" "$RED" "❌" "FAIL"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$ERR_FILE" 2>/dev/null || true
    ((ERROR_COUNT++))
}
log_debug() { [[ $VERBOSE -eq 1 ]] && log_message "DEBUG" "$1" "$CYAN" "🔍"; }

# Sección con diseño mejorado
log_section() {
    local title="$1"
    local width=80
    local padding=$(( (width - ${#title} - 4) / 2 ))
    local border
    border=$(printf '═%.0s' $(seq 1 $width))
    
    echo -e "\n${CYAN}┌${border}┐${NC}"
    printf "${CYAN}│%*s  ${BOLD}%s${NC}${CYAN}  %*s│${NC}\n" $padding "" "$title" $padding ""
    echo -e "${CYAN}└${border}┘${NC}\n"
    
    if [[ -f "$LOG_FILE" ]]; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] $title" >> "$LOG_FILE"
    fi
}

# Barra de progreso mejorada
show_progress() {
    local current=$1
    local total=$2
    local width=${3:-50}
    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r${BLUE}Progress: [" >&2
    printf "%0.s▓" $(seq 1 $filled) >&2
    printf "%0.s░" $(seq 1 $empty) >&2
    printf "] %3d%% (%d/%d)${NC}" "$percent" "$current" "$total" >&2
    
    if [[ $current -eq $total ]]; then
        echo "" >&2
    fi
}

# Ejecución de comandos con mejor manejo de errores
run_cmd() {
    local cmd="$*"
    local exit_code=0
    local output
    
    log_debug "Executing: $cmd"
    
    if [[ $VERBOSE -eq 1 ]]; then
        # Modo verbose: mostrar output en tiempo real
        if "$@"; then
            log_success "Command completed: $cmd"
            return 0
        else
            exit_code=$?
            log_error "Command failed (exit code $exit_code): $cmd"
            return $exit_code
        fi
    else
        # Modo silencioso: capturar output
        if output=$("$@" 2>&1); then
            log_success "Command completed: $cmd"
            return 0
        else
            exit_code=$?
            log_error "Command failed (exit code $exit_code): $cmd"
            [[ -n "$output" ]] && log_debug "Command output: $output"
            return $exit_code
        fi
    fi
}

# Manejo mejorado de sudo
ensure_sudo() {
    if [[ $EUID -eq 0 ]]; then
        log_warn "Running as root. This is not recommended."
        return 0
    fi
    
    if ! sudo -n true 2>/dev/null; then
        log_info "Requesting sudo privileges..."
        if ! sudo -v; then
            log_error "Unable to obtain sudo privileges"
            exit 1
        fi
    fi
    
    # Mantener sudo vivo en segundo plano
    if [[ -z "${DISABLE_SUDO_KEEPALIVE:-}" ]]; then
        {
            while sudo -n true 2>/dev/null; do 
                sleep 45
            done
        } &
        SUDO_PID=$!
        log_debug "Sudo keepalive started (PID: $SUDO_PID)"
    fi
}

# Funciones de limpieza
cleanup_on_exit() {
    local exit_code=$?
    
    # Detener sudo keepalive
    if [[ -n "$SUDO_PID" ]]; then
        kill "$SUDO_PID" 2>/dev/null || true
        log_debug "Sudo keepalive stopped"
    fi
    
    # Mostrar resumen final
    if [[ $ERROR_COUNT -gt 0 ]]; then
        log_warn "Script completed with $ERROR_COUNT errors. Check $ERR_FILE for details."
    else
        log_success "Script completed successfully!"
    fi
    
    # Cambiar ownership de logs al usuario real
    if [[ "$REAL_USER" != "root" && -f "$LOG_FILE" ]]; then
        chown "$REAL_USER:$REAL_USER" "$LOG_FILE" "$ERR_FILE" 2>/dev/null || true
    fi
    
    exit $exit_code
}

cleanup_on_error() {
    local line_no=$1
    local failed_command=$2
    log_error "Script failed at line $line_no: $failed_command"
}

# Validación de prerrequisitos
check_prerequisites() {
    log_section "🔍 System Prerequisites Check"
    
    # Verificar versión de Fedora
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
    
    # Verificar conexión a internet
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_success "Internet connection verified"
    else
        log_error "No internet connection available"
        return 1
    fi
    
    # Verificar filesystem BTRFS
    if findmnt -n -o FSTYPE / | grep -q btrfs; then
        log_success "BTRFS root filesystem detected"
    else
        log_warn "BTRFS not detected. Some features may not work properly."
    fi
    
    # Verificar espacio en disco
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

# ══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE INICIALIZACIÓN MEJORADAS
# ══════════════════════════════════════════════════════════════════════════════

show_help() {
    cat << EOF
${BOLD}$SCRIPT_NAME v$SCRIPT_VERSION${NC}
Fedora 42+ Post-Install Configuration Script

${BOLD}USAGE:${NC}
    sudo $SCRIPT_NAME [OPTIONS]

${BOLD}OPTIONS:${NC}
    -h, --help      Show this help message
    -u, --update    Update system before configuration
    -c, --clean     Clean system after installation
    -v, --verbose   Enable verbose output and debugging
    
${BOLD}FEATURES:${NC}
    • System hardening and security configuration
    • Network services setup (SSH, firewall, DNS)
    • BTRFS snapshots with grub-btrfs and Timeshift
    • Essential package installation and Flatpak setup
    • Automatic updates configuration
    • Comprehensive logging and error handling

${BOLD}REQUIREMENTS:${NC}
    • Fedora 42+ (recommended: BTRFS root filesystem)
    • Sudo privileges and internet connection
    • Minimum ${MIN_DISK_SPACE_MB}MB free space

${BOLD}EXAMPLES:${NC}
    sudo $SCRIPT_NAME --update --verbose
    sudo $SCRIPT_NAME --clean
    
${BOLD}LOGS:${NC}
    Logs are stored in: ~/fedora_logs/
    
EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
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
            -v|--verbose)
                VERBOSE=1
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                log_error "Unexpected argument: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

init_environment() {
    # 1. Determinar usuario real y su $HOME
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

    # 2. Validar existencia de HOME
    if [[ ! -d "$USER_HOME" ]]; then
        USER_HOME="/tmp"
    fi

    # 3. Configurar timestamp y rutas de logs
    TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
    LOG_DIR="$USER_HOME/fedora_logs"

    # Crear directorio de logs (fallback incluido)
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        LOG_DIR="/tmp/fedora_logs_$TIMESTAMP"
        mkdir -p "$LOG_DIR"
    fi

    # 4. Definir archivos de log
    LOG_FILE="$LOG_DIR/install_$TIMESTAMP.log"
    ERR_FILE="$LOG_DIR/error_$TIMESTAMP.log"

    # 5. Crear y proteger archivos de log
    touch "$LOG_FILE" "$ERR_FILE"
    chmod 644 "$LOG_FILE" "$ERR_FILE" 2>/dev/null || true

    # 6. Corregir permisos si no es root
    if [[ "$REAL_USER" != "root" ]]; then
        chown "$REAL_USER:$REAL_USER" "$LOG_FILE" "$ERR_FILE" 2>/dev/null || true
    fi

    # 7. Ahora que todo está definido, se puede usar logging
    log_section "🚀 Environment Initialization"
    log_info "Script version: $SCRIPT_VERSION"
    log_info "Real user: $REAL_USER"
    log_info "Home directory: $USER_HOME"
    log_info "Log directory: $LOG_DIR"
    log_info "Verbose mode: $([[ $VERBOSE -eq 1 ]] && echo "enabled" || echo "disabled")"
    log_success "Environment initialized successfully"
}


# ══════════════════════════════════════════════════════════════════════════════
# FUNCIONES DE CONFIGURACIÓN DEL SISTEMA OPTIMIZADAS
# ══════════════════════════════════════════════════════════════════════════════

update_system() {
    log_section "📦 System Update"
    
    # Limpiar metadatos de DNF primero
    run_cmd sudo dnf clean metadata
    
    # Actualizar el sistema
    run_cmd sudo dnf upgrade --refresh -y
    
    # Verificar si se requiere reinicio
    if [[ -f /var/run/reboot-required ]]; then
        log_warn "System reboot required after updates"
    fi
    
    log_success "System updated successfully"
}

configure_dnf() {
    log_section "⚙️ DNF Optimization"
    
    # Configurar zona horaria
    run_cmd sudo timedatectl set-local-rtc 0
    run_cmd sudo timedatectl set-ntp true
    
    # Backup de configuración original
    local dnf_conf="/etc/dnf/dnf.conf"
    local backup_conf="${dnf_conf}.backup.$(date +%Y%m%d)"
    
    if [[ ! -f "$backup_conf" ]]; then
        run_cmd sudo cp "$dnf_conf" "$backup_conf"
        log_info "DNF config backed up to: $backup_conf"
    fi
    
    # Escribir configuración optimizada
    run_cmd sudo tee "$dnf_conf" > /dev/null << 'EOF'
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
    
    log_success "DNF configuration optimized"
}

configure_automatic_updates() {
    log_section "🔄 Automatic Updates Setup"
    
    # Instalar dnf-automatic
    run_cmd sudo dnf install -y dnf-automatic
    
    # Configurar dnf-automatic
    local auto_conf="/etc/dnf/automatic.conf"
    run_cmd sudo sed -i 's/apply_updates = no/apply_updates = yes/' "$auto_conf"
    run_cmd sudo sed -i 's/emit_via = stdio/emit_via = email/' "$auto_conf"
    
    # Habilitar el timer
    run_cmd sudo systemctl enable --now dnf-automatic.timer
    
    # Verificar estado
    if systemctl is-active --quiet dnf-automatic.timer; then
        log_success "Automatic updates enabled and running"
    else
        log_warn "Automatic updates timer may not be running properly"
    fi
}

# Instalación de paquetes con manejo mejorado de errores
install_packages() {
    local package_group="$1"
    local -n packages_ref
    
    case "$package_group" in
        "essential") packages_ref=ESSENTIAL_PACKAGES ;;
        "security") packages_ref=SECURITY_PACKAGES ;;
        "network") packages_ref=NETWORK_PACKAGES ;;
        *) 
            log_error "Unknown package group: $package_group"
            return 1
            ;;
    esac
    
    log_section "📦 Installing ${package_group^} Packages"
    
    local total=${#packages_ref[@]}
    local installed=0
    local failed=0
    
    for i in "${!packages_ref[@]}"; do
        local pkg="${packages_ref[$i]}"
        
        # Verificar si el paquete ya está instalado
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

# Configuración de hostname mejorada con validación
configure_hostname() {
    log_section "🖥️ Hostname Configuration"
    
    local current_hostname
    current_hostname=$(hostnamectl --static)
    local new_hostname="${NEW_HOSTNAME:-}"
    
    log_info "Current hostname: $current_hostname"
    
    # Entrada interactiva de hostname si no está establecido
    if [[ -z "$new_hostname" && -t 0 ]]; then
        echo -ne "${BLUE}Enter new hostname (current: $current_hostname, or press Enter to skip): ${NC}"
        read -r new_hostname
    fi
    
    if [[ -z "$new_hostname" ]]; then
        log_info "Hostname configuration skipped"
        return 0
    fi
    
    # Validación de formato de hostname (RFC1123)
    if [[ ! "$new_hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?$ ]]; then
        log_error "Invalid hostname format: $new_hostname"
        log_info "Hostname must be 1-63 characters, alphanumeric with hyphens (not at start/end)"
        return 1
    fi
    
    # Verificar si el hostname ya está configurado
    if [[ "$current_hostname" == "$new_hostname" ]]; then
        log_info "Hostname already set to: $new_hostname"
        return 0
    fi
    
    # Aplicar nuevo hostname
    run_cmd sudo hostnamectl set-hostname --static "$new_hostname"
    
    # Actualizar /etc/hosts
    if grep -q "127.0.1.1" /etc/hosts; then
        sudo sed -i "s/127.0.1.1.*/127.0.1.1 $new_hostname.localdomain $new_hostname/" /etc/hosts
    else
        echo "127.0.1.1 $new_hostname.localdomain $new_hostname" | sudo tee -a /etc/hosts >/dev/null
    fi
    
    log_success "Hostname set to: $new_hostname"
}

clean_system() {
    log_section "🧹 System Cleanup"
    
    local space_before
    space_before=$(df --output=used / | tail -n1)
    
    # Limpiar paquetes huérfanos
    run_cmd sudo dnf autoremove -y
    
    # Limpiar cache de DNF
    run_cmd sudo dnf clean all
    
    # Limpiar logs antiguos
    sudo journalctl --vacuum-time=7d >/dev/null 2>&1 || true
    
    # Limpiar cache de usuario
    if [[ -d "$USER_HOME/.cache" ]]; then
        find "$USER_HOME/.cache" -type f -atime +7 -delete 2>/dev/null || true
    fi
    
    local space_after
    space_after=$(df --output=used / | tail -n1)
    local space_freed=$(( (space_before - space_after) / 1024 ))
    
    if [[ $space_freed -gt 0 ]]; then
        log_success "System cleanup completed. Space freed: ${space_freed}MB"
    else
        log_success "System cleanup completed"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# FUNCIÓN PRINCIPAL MEJORADA
# ══════════════════════════════════════════════════════════════════════════════

main() {
    local start_time
    start_time=$(date +%s)

    # 1. Inicializar colores antes de cualquier uso de variables de color
    setup_colors

    # 2. Inicializar entorno (define LOG_FILE, LOG_DIR, USER_HOME, etc.)
    init_environment

    # 3. Mostrar banner ahora que CYAN, BOLD, etc. están definidos correctamente
    cat << EOF

${CYAN}╔════════════════════════════════════════════════════════════════════════════════╗
║                      ${BOLD}Fedora $SCRIPT_VERSION Post-Install Script${NC}${CYAN}                      ║
║                           ${YELLOW}Professional Configuration Suite${NC}${CYAN}                          ║
╚════════════════════════════════════════════════════════════════════════════════╝${NC}

EOF

    # 4. Parsear argumentos de línea de comandos
    parse_arguments "$@"

    # 5. Verificar prerrequisitos de sistema
    check_prerequisites

    # 6. Elevar privilegios si es necesario
    ensure_sudo

    # 7. Actualizar sistema si se solicitó
    if [[ $UPDATE_SYSTEM -eq 1 ]]; then
        update_system
    fi

    # 8. Configurar DNF y actualizaciones automáticas
    configure_dnf
    configure_automatic_updates

    # 9. Instalar paquetes esenciales, de seguridad y de red
    install_packages "essential"
    install_packages "security"
    install_packages "network"

    # 10. Configurar nombre de host
    configure_hostname

    # 11. Configuraciones adicionales (comentadas por ahora)
    # configure_flatpak
    # configure_firewall
    # configure_selinux
    # configure_dns
    # configure_ssh_security
    # enable_system_services

    # 12. Limpieza del sistema si se indicó
    if [[ $CLEAN_SYSTEM -eq 1 ]]; then
        clean_system
    fi

    # 13. Resumen final
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


# Ejecutar función principal con todos los argumentos
main "$@"