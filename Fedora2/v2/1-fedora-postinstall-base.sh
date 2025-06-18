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
# Version: 2.0 (Refactored)
# License: MIT
# Created: 2025-06-17
# Compatible with: Fedora 42+ (Bash 5.1+, systemd, BTRFS root)
# 
# Usage: sudo ./fedora_postinstall.sh [--update] [--clean]
# ──────────────────────────────────────────────────────────────────────────────

set -euo pipefail
IFS=$'\n\t'

# ══════════════════════════════════════════════════════════════════════════════
# GLOBAL CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly SCRIPT_NAME="${0##*/}"
readonly SCRIPT_VERSION="2.0"
readonly MIN_DISK_SPACE_MB=5000

# User and environment detection
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$REAL_USER")
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')

# Logging setup
LOG_DIR="$USER_HOME/fedora_logs"
LOG_FILE="$LOG_DIR/install_$TIMESTAMP.log"
ERR_FILE="$LOG_DIR/error_$TIMESTAMP.log"
ERROR_COUNT=0

# Command line options
UPDATE_SYSTEM=0
CLEAN_SYSTEM=0

# Package collections
readonly ESSENTIAL_PACKAGES=(
    vim nano git curl wget htop neofetch unzip p7zip p7zip-plugins
    tar gzip bzip2 zsh bash-completion
)

readonly SECURITY_PACKAGES=(
    firewalld firewall-config selinux-policy selinux-policy-targeted
    policycoreutils policycoreutils-python-utils fail2ban
)

readonly NETWORK_PACKAGES=(
    samba samba-client avahi nss-mdns ftp lftp openssh-clients bluez-obexd
    kde-connect qt6-qml kde-connectd rclone fuse
)

# ══════════════════════════════════════════════════════════════════════════════
# UTILITY FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

# Color definitions for terminal output
setup_colors() {
    if [[ -t 1 ]]; then
        readonly RED="\033[0;31m"
        readonly GREEN="\033[0;32m"
        readonly YELLOW="\033[1;33m"
        readonly BLUE="\033[1;34m"
        readonly CYAN="\033[0;36m"
        readonly BOLD="\033[1m"
        readonly NC="\033[0m"
    else
        readonly RED="" GREEN="" YELLOW="" BLUE="" CYAN="" BOLD="" NC=""
    fi
}

# Enhanced logging functions
log_message() {
    local level="$1" && shift
    local msg="$1" && shift
    local color="${1:-$NC}"
    local icon="${2:-ℹ️}"
    local status="${3:-INFO}"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    printf "${color}%-70s %s${NC}\n" "[$icon $level] $msg" "[$status]"
    [[ -f "$LOG_FILE" ]] && echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"
}

log_info() { log_message "INFO" "$1" "$BLUE" "ℹ️" "OK"; }
log_success() { log_message "SUCCESS" "$1" "$GREEN" "✅" "OK"; }
log_warn() { 
    log_message "WARNING" "$1" "$YELLOW" "⚠️" "WARN"
    [[ -f "$ERR_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [WARNING] $1" >> "$ERR_FILE"
    ((ERROR_COUNT++))
}
log_error() { 
    log_message "ERROR" "$1" "$RED" "❌" "FAIL"
    [[ -f "$ERR_FILE" ]] && echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$ERR_FILE"
    ((ERROR_COUNT++))
}

log_section() {
    local title="$1"
    local border=$(printf '─%.0s' $(seq 1 $((${#title} + 4))))
    
    echo -e "\n${CYAN}┌$border┐${NC}"
    echo -e "${CYAN}│  ${BOLD}$title${NC}${CYAN}  │${NC}"
    echo -e "${CYAN}└$border┘${NC}\n"
    
    [[ -f "$LOG_FILE" ]] && echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] $title" >> "$LOG_FILE"
}

# Progress bar utility
show_progress() {
    local current=$1 total=$2 width=50
    local percent=$((current * 100 / total))
    local filled=$((width * current / total))
    local empty=$((width - filled))
    
    printf "\r[" >&2
    printf "%0.s▓" $(seq 1 $filled) >&2
    printf "%0.s░" $(seq 1 $empty) >&2
    printf "] %3d%% (%d/%d)" "$percent" "$current" "$total" >&2
    [[ $current -eq $total ]] && echo "" >&2
}

# Command execution with error handling
run_cmd() {
    log_info "Executing: $*"
    if "$@"; then
        log_success "Command completed successfully"
        return 0
    else
        local exit_code=$?
        log_error "Command failed with exit code $exit_code: $*"
        return $exit_code
    fi
}

# Safe sudo execution
ensure_sudo() {
    if ! sudo -n true 2>/dev/null; then
        log_info "Requesting sudo privileges..."
        sudo -v || { log_error "Unable to obtain sudo privileges"; exit 1; }
    fi
    
    # Keep sudo alive in background
    if [[ -z "${DISABLE_SUDO_KEEPALIVE:-}" ]]; then
        (while sudo -n true 2>/dev/null; do sleep 50; done) &
        SUDO_PID=$!
        trap "kill -9 $SUDO_PID 2>/dev/null || true" EXIT
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# INITIALIZATION FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

show_help() {
    cat << EOF
${BOLD}$SCRIPT_NAME v$SCRIPT_VERSION${NC}
Fedora 42 Post-Install Configuration Script

${BOLD}USAGE:${NC}
    sudo $SCRIPT_NAME [OPTIONS]

${BOLD}OPTIONS:${NC}
    -h, --help      Show this help message
    -u, --update    Update system before configuration
    -c, --clean     Clean system after installation
    
${BOLD}FEATURES:${NC}
    • System hardening and security configuration
    • Network services setup (SSH, firewall, DNS)
    • BTRFS snapshots with grub-btrfs and Timeshift
    • Essential package installation and Flatpak setup
    • Automatic updates configuration

${BOLD}REQUIREMENTS:${NC}
    • Fedora 42+ with BTRFS root filesystem
    • Sudo privileges and internet connection
    • Minimum ${MIN_DISK_SPACE_MB}MB free space

EOF
}

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help) show_help; exit 0 ;;
            -u|--update) UPDATE_SYSTEM=1; shift ;;
            -c|--clean) CLEAN_SYSTEM=1; shift ;;
            *) log_error "Unknown option: $1"; show_help; exit 1 ;;
        esac
    done
}

init_environment() {
    log_section "🚀 Environment Initialization"
    
    setup_colors
    
    # Validate user and home directory
    if ! id "$REAL_USER" &>/dev/null; then
        log_warn "User '$REAL_USER' not found, using /root"
        USER_HOME="/root"
        REAL_USER="root"
    fi
    
    [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]] && USER_HOME="/root"
    
    # Setup logging directory
    local fallback_log_dir="/tmp/fedora_logs_$TIMESTAMP"
    LOG_DIR="$USER_HOME/fedora_logs"
    
    if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
        log_warn "Cannot create $LOG_DIR, using fallback"
        LOG_DIR="$fallback_log_dir"
        mkdir -p "$LOG_DIR"
    fi
    
    LOG_FILE="$LOG_DIR/install_$TIMESTAMP.log"
    ERR_FILE="$LOG_DIR/error_$TIMESTAMP.log"
    
    touch "$LOG_FILE" "$ERR_FILE"
    chmod 664 "$LOG_FILE" "$ERR_FILE" 2>/dev/null || true
    chown "$REAL_USER:$REAL_USER" "$LOG_FILE" "$ERR_FILE" 2>/dev/null || true
    
    # Validate disk space
    local available_kb=$(df --output=avail "$LOG_DIR" | tail -n1 | tr -d ' ')
    local required_kb=$((MIN_DISK_SPACE_MB * 1024))
    
    if [[ -z "$available_kb" || "$available_kb" -lt "$required_kb" ]]; then
        log_error "Insufficient disk space. Required: ${MIN_DISK_SPACE_MB}MB, Available: $((available_kb / 1024))MB"
        exit 1
    fi
    
    log_info "Real user: $REAL_USER"
    log_info "Home directory: $USER_HOME"
    log_info "Log directory: $LOG_DIR"
    log_info "Available space: $((available_kb / 1024))MB"
    log_success "Environment initialized successfully"
}

# ══════════════════════════════════════════════════════════════════════════════
# SYSTEM CONFIGURATION FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════════

update_system() {
    log_section "📦 System Update"
    run_cmd sudo dnf upgrade --refresh -y
    log_success "System updated successfully"
}

configure_dnf() {
    log_section "⚙️ DNF Optimization"
    
    # Configure time settings
    run_cmd sudo timedatectl set-local-rtc 0 || log_warn "Unable to set UTC time"
    
    # Write optimized DNF configuration
    local dnf_conf="/etc/dnf/dnf.conf"
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
EOF
    
    log_success "DNF configuration optimized"
}

configure_automatic_updates() {
    log_section "🔄 Automatic Updates Setup"
    
    run_cmd sudo dnf install -y dnf-automatic
    run_cmd sudo cp /usr/lib/systemd/system/dnf-automatic.timer /etc/systemd/system/
    run_cmd sudo systemctl enable --now dnf-automatic.timer
    
    log_success "Automatic updates configured"
}

install_packages() {
    local package_group="$1"
    local packages=()
    
    case "$package_group" in
        "essential") packages=("${ESSENTIAL_PACKAGES[@]}") ;;
        "security") packages=("${SECURITY_PACKAGES[@]}") ;;
        "network") packages=("${NETWORK_PACKAGES[@]}") ;;
        *) log_error "Unknown package group: $package_group"; return 1 ;;
    esac
    
    log_section "📦 Installing ${package_group^} Packages"
    
    local total=${#packages[@]}
    for i in "${!packages[@]}"; do
        local pkg="${packages[$i]}"
        log_info "Installing: $pkg"
        
        if sudo dnf install -y --allowerasing --skip-broken --skip-unavailable "$pkg"; then
            log_success "Installed: $pkg"
        else
            log_warn "Failed to install: $pkg"
        fi
        
        show_progress "$((i + 1))" "$total"
    done
    
    log_success "Package installation completed"
}

configure_hostname() {
    log_section "🖥️ Hostname Configuration"
    
    local new_hostname="${NEW_HOSTNAME:-}"
    
    # Interactive hostname input if not set
    if [[ -z "$new_hostname" && -t 0 ]]; then
        echo -ne "${BLUE}Enter new hostname (or press Enter to skip): ${NC}"
        read -r new_hostname
    fi
    
    if [[ -z "$new_hostname" ]]; then
        log_info "Hostname configuration skipped"
        return 0
    fi
    
    # Validate hostname format (RFC1123)
    if [[ ! "$new_hostname" =~ ^[a-zA-Z0-9][-a-zA-Z0-9]{0,61}[a-zA-Z0-9]$ ]]; then
        log_error "Invalid hostname format: $new_hostname"
        return 1
    fi
    
    run_cmd sudo hostnamectl set-hostname --static "$new_hostname"
    log_success "Hostname set to: $new_hostname"
}

clean_system() {
    log_section "🧹 System Cleanup"
    
    run_cmd sudo dnf autoremove -y
    run_cmd sudo dnf clean all
    
    log_success "System cleanup completed"
}

# ══════════════════════════════════════════════════════════════════════════════
# FLATPAK CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

configure_flatpak() {
    log_section "📦 Flatpak Configuration"
    
    # Install Flatpak if not present
    if ! command -v flatpak &>/dev/null; then
        run_cmd sudo dnf install -y flatpak
    fi
    
    # Configure repositories
    declare -A flatpak_remotes=(
        [flathub]="https://flathub.org/repo/flathub.flatpakrepo"
        [kde]="https://distribute.kde.org/kdeapps.flatpakrepo"
        [elementary]="https://flatpak.elementary.io/repo.flatpakrepo"
        [fedora]="oci+https://registry.fedoraproject.org"
    )
    
    local total=${#flatpak_remotes[@]}
    local current=0
    
    for remote in "${!flatpak_remotes[@]}"; do
        local url="${flatpak_remotes[$remote]}"
        log_info "Adding Flatpak remote: $remote"
        
        if [[ "$url" == *.flatpakrepo ]]; then
            sudo flatpak remote-add --if-not-exists --from "$remote" "$url" &>/dev/null || true
        else
            sudo flatpak remote-add --if-not-exists "$remote" "$url" &>/dev/null || true
        fi
        
        sudo flatpak remote-modify --system --prio=$((++current)) "$remote" &>/dev/null || true
        show_progress "$current" "$total"
    done
    
    log_success "Flatpak repositories configured"
}

# ══════════════════════════════════════════════════════════════════════════════
# SECURITY CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

configure_firewall() {
    log_section "🔥 Firewall Configuration"
    
    # Enable firewalld
    run_cmd sudo systemctl enable --now firewalld
    run_cmd sudo firewall-cmd --set-default-zone=FedoraWorkstation
    
    # Configure services
    local services=(ssh http https samba mdns ipp dhcpv6-client ftp)
    for service in "${services[@]}"; do
        if sudo firewall-cmd --get-services | grep -qw "$service"; then
            sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-service="$service"
            log_info "Added service: $service"
        fi
    done
    
    # Configure ports
    declare -A tcp_ports=(
        [22]="SSH" [2222]="Hardened SSH" [3389]="RDP" [5900]="VNC"
        [80]="HTTP" [443]="HTTPS" [8080]="Web Apps" [32400]="Plex"
        [8096]="Jellyfin" [21]="FTP" [22000]="Syncthing"
    )
    
    declare -A udp_ports=(
        [1900]="UPnP" [5353]="mDNS" [21027]="Syncthing" [123]="NTP"
        [5355]="LLMNR" [53]="DNS"
    )
    
    for port in "${!tcp_ports[@]}"; do
        sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port="${port}/tcp"
        log_info "Opened TCP port: $port (${tcp_ports[$port]})"
    done
    
    for port in "${!udp_ports[@]}"; do
        sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port="${port}/udp"
        log_info "Opened UDP port: $port (${udp_ports[$port]})"
    done
    
    # Port ranges
    sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port="8000-8100/tcp"
    sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port="60000-61000/tcp"
    sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port="1714-1764/tcp"
    sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port="1714-1764/udp"
    sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port="67-68/udp"
    
    run_cmd sudo firewall-cmd --reload
    log_success "Firewall configured successfully"
}

configure_selinux() {
    log_section "🔒 SELinux Configuration"
    
    run_cmd sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
    sudo semanage permissive -a firewalld_t &>/dev/null || true
    
    log_success "SELinux configured in enforcing mode"
}

configure_dns() {
    log_section "🌐 DNS Configuration"
    
    run_cmd sudo mkdir -p /etc/systemd/resolved.conf.d
    run_cmd sudo tee /etc/systemd/resolved.conf.d/99-dns-over-tls.conf > /dev/null << 'EOF'
[Resolve]
DNS=94.140.14.14        # AdGuard primary
DNS=94.140.15.15        # AdGuard secondary
DNS=1.1.1.1             # Cloudflare primary
DNS=1.0.0.1             # Cloudflare secondary
DNSOverTLS=no
EOF
    
    run_cmd sudo systemctl restart systemd-resolved
    
    # Install hblock for DNS-level blocking
    sudo dnf -y copr enable pesader/hblock &>/dev/null || true
    if sudo dnf install -y hblock &>/dev/null && command -v hblock &>/dev/null; then
        sudo hblock &>/dev/null || true
        log_success "hblock DNS blocker installed"
    fi
    
    log_success "DNS configuration completed"
}

configure_ssh_security() {
    log_section "🔐 SSH Security Hardening"
    
    # Install and configure fail2ban
    run_cmd sudo dnf install -y fail2ban
    run_cmd sudo systemctl enable --now fail2ban
    
    run_cmd sudo tee /etc/fail2ban/jail.local > /dev/null << 'EOF'
[sshd]
enabled = true
port    = 2222
logpath = /var/log/secure
maxretry = 3
bantime = 1h
EOF
    
    run_cmd sudo systemctl restart fail2ban
    
    # Harden SSH configuration
    local ssh_config="/etc/ssh/sshd_config"
    local ssh_backup="/etc/ssh/sshd_config.bak.$(date +%Y%m%d_%H%M%S)"
    
    run_cmd sudo cp "$ssh_config" "$ssh_backup"
    log_info "SSH config backed up to: $ssh_backup"
    
    # Apply hardened settings
    sudo sed -i -E 's/^#?\s*Port\s+.*/Port 2222/' "$ssh_config"
    sudo sed -i -E 's/^#?\s*PermitRootLogin\s+.*/PermitRootLogin no/' "$ssh_config"
    sudo sed -i -E 's/^#?\s*PasswordAuthentication\s+.*/PasswordAuthentication no/' "$ssh_config"
    
    # Ensure settings are present
    grep -q "^Port " "$ssh_config" || echo "Port 2222" | sudo tee -a "$ssh_config" > /dev/null
    grep -q "^PermitRootLogin " "$ssh_config" || echo "PermitRootLogin no" | sudo tee -a "$ssh_config" > /dev/null
    grep -q "^PasswordAuthentication " "$ssh_config" || echo "PasswordAuthentication no" | sudo tee -a "$ssh_config" > /dev/null
    
    # Validate and apply configuration
    if sudo sshd -t; then
        # Configure SELinux for custom SSH port
        sudo semanage port -a -t ssh_port_t -p tcp 2222 2>/dev/null || \
        sudo semanage port -m -t ssh_port_t -p tcp 2222
        
        run_cmd sudo systemctl restart sshd
        
        # Restrict SSH to LAN
        sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="2222" protocol="tcp" accept' --zone=FedoraWorkstation --permanent
        sudo firewall-cmd --remove-service=ssh --zone=FedoraWorkstation --permanent
        sudo firewall-cmd --reload
        
        log_success "SSH hardening completed (port 2222, LAN access only)"
    else
        log_error "SSH configuration validation failed, restoring backup"
        sudo cp "$ssh_backup" "$ssh_config"
        sudo systemctl restart sshd
        return 1
    fi
}

enable_system_services() {
    log_section "🚀 System Services"
    
    local services=(avahi-daemon bluetooth)
    for service in "${services[@]}"; do
        sudo systemctl enable --now "$service" &>/dev/null || log_warn "Failed to enable $service"
        log_info "Enabled service: $service"
    done
    
    log_success "System services configured"
}

# ══════════════════════════════════════════════════════════════════════════════
# BTRFS SNAPSHOT CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

install_grub_btrfs() {
    log_section "📦 grub-btrfs Installation"
    
    local workdir="/tmp/grub-btrfs-src"
    local repo_url="https://github.com/Antynea/grub-btrfs.git"
    
    # Install dependencies
    run_cmd sudo dnf install -y git make gcc grub2-tools grub2-tools-extra
    
    # Clone and build
    run_cmd rm -rf "$workdir"
    run_cmd git clone --depth=1 "$repo_url" "$workdir"
    
    pushd "$workdir" >/dev/null || return 1
    
    # Patch for Fedora
    run_cmd sed -i 's|/boot/grub/|/boot/grub2/|g' Makefile
    run_cmd sed -i 's|/boot/grub|/boot/grub2|g' Makefile
    
    # Set environment variables
    export GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"
    export GRUB_BTRFS_MKCONFIG="/sbin/grub2-mkconfig"
    export GRUB_BTRFS_SCRIPT_CHECK="grub2-script-check"
    
    run_cmd sudo make install
    
    popd >/dev/null
    run_cmd rm -rf "$workdir"
    
    log_success "grub-btrfs installed successfully"
}

configure_grub_btrfs() {
    log_section "⚙️ grub-btrfs Configuration"
    
    local config_file="/etc/default/grub-btrfs/config"
    run_cmd sudo mkdir -p "$(dirname "$config_file")"
    
    run_cmd sudo tee "$config_file" > /dev/null << 'EOF'
GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"
GRUB_BTRFS_MKCONFIG="/sbin/grub2-mkconfig"
GRUB_BTRFS_SCRIPT_CHECK="grub2-script-check"
GRUB_BTRFS_SUBMENUNAME="Snapshots BTRFS"
GRUB_BTRFS_SNAPSHOT_FORMAT="%Y-%m-%d %H:%M | %c"
GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="rootflags=subvol=@ quiet"
EOF
    
    # Create systemd service
    run_cmd sudo tee /etc/systemd/system/grub-btrfsd.service > /dev/null << 'EOF'
[Unit]
Description=grub-btrfs daemon - detects BTRFS snapshots and updates GRUB
After=multi-user.target

[Service]
ExecStart=/usr/bin/grub-btrfsd -r /mnt -g
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Create path monitor
    run_cmd sudo tee /etc/systemd/system/grub-btrfs.path > /dev/null << 'EOF'
[Unit]
Description=Monitor Timeshift snapshots for GRUB integration

[Path]
PathModified=/run/timeshift/backup/timeshift-btrfs/snapshots

[Install]
WantedBy=multi-user.target
EOF
    
    run_cmd sudo systemctl daemon-reload
    run_cmd sudo systemctl enable --now grub-btrfsd.service
    
    log_success "grub-btrfs services configured"
}

setup_timeshift() {
    log_section "🕰️ Timeshift Configuration"
    
    # Install Timeshift
    if ! command -v timeshift &>/dev/null; then
        run_cmd sudo dnf install -y timeshift
    fi
    
    # Prepare directories
    run_cmd sudo mkdir -p /.snapshots /etc/timeshift
    run_cmd sudo chown root:root /.snapshots
    
    # Launch Timeshift GUI for initial setup
    local user="${REAL_USER:-$(logname 2>/dev/null || echo "$USER")}"
    if [[ -n "$user" && "$user" != "root" ]]; then
        local uid=$(id -u "$user")
        
        log_info "Launching Timeshift GUI for initial configuration..."
        sudo env \
            DISPLAY="$DISPLAY" \
            XAUTHORITY="/home/$user/.Xauthority" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$uid/bus" \
            XDG_RUNTIME_DIR="/run/user/$uid" \
            HOME="/home/$user" \
            nohup timeshift-gtk >/dev/null 2>&1 &
        
        local gtk_pid=$!
        sleep 5
        
        if ps -p "$gtk_pid" &>/dev/null; then
            sudo kill "$gtk_pid" 2>/dev/null || true
        fi
    fi
    
    # Verify configuration
    if [[ ! -f /etc/timeshift/timeshift.json ]]; then
        log_error "Timeshift configuration not found"
        return 1
    fi
    
    log_success "Timeshift configured successfully"
}

create_initial_snapshot() {
    log_section "📸 Initial Snapshot Creation"
    
    if ! command -v timeshift &>/dev/null; then
        log_error "Timeshift not installed"
        return 1
    fi
    
    if ! sudo test -f /etc/timeshift/timeshift.json; then
        log_error "Timeshift not configured"
        return 1
    fi
    
    # Check if snapshots already exist
    if sudo timeshift --list | grep -q "Snapshot"; then
        log_info "Timeshift snapshots already exist"
        return 0
    fi
    
    # Create initial snapshot
    run_cmd sudo timeshift --create --comments "Initial system snapshot" --tags D
    
    log_success "Initial snapshot created"
}

finalize_grub_btrfs() {
    log_section "🔄 Finalizing GRUB Integration"
    
    # Enable monitoring if Timeshift is ready
    if [[ -d /run/timeshift ]]; then
        run_cmd sudo systemctl restart grub-btrfsd.service
        run_cmd sudo systemctl enable --now grub-btrfs.path
    fi
    
    # Regenerate GRUB configuration
    run_cmd sudo grub2-mkconfig -o /boot/grub2/grub.cfg
    
    log_success "GRUB configuration updated"
}

verify_snapshot_setup() {
    log_section "🔍 Snapshot Setup Verification"
    
    local checks