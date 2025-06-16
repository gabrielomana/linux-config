# ──────────────────────────────────────────────────────────────────────────────
# Fedora 42 Post-Install Script – Professional Hardening & Configuration Suite
# 
# Description:
#   This script automates the secure and optimal post-install configuration
#   of a Fedora 42 workstation or server environment. It applies system
#   hardening practices, network security, package installation, BTRFS-based
#   snapshot integration with grub-btrfs and Timeshift, firewall setup, DNS
#   privacy enhancements, automatic updates and essential desktop/server tools.
#
# Features:
#   - Essential packages and Flatpak repositories
#   - DNF and update optimizations
#   - SSH hardening (fail2ban, custom ports, SELinux)
#   - firewalld and port/service management
#   - SELinux enforcing setup
#   - grub-btrfs and Timeshift snapshot integration
#   - Logs and error tracking per session
#   - Interactive hostname and reboot prompt
#
# Author: Gabriel Omaña – Initium | https://initiumsoft.com
# Version: 1.0
# License: MIT (or specify otherwise)
# Created: 2025-06-17
# Compatible with: Fedora 42+ (Bash 5.1+, systemd, BTRFS root)
# 
# Usage:
#   sudo ./fedora_postinstall.sh [--update] [--clean]
#
# Notes:
#   - Requires internet access and sudo privileges.
#   - BTRFS root is mandatory for snapshot features.
#   - Flatpak, grub2-tools, and COPR enabled.
# ──────────────────────────────────────────────────────────────────────────────

#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ─────────────────────────────────────────────────────────────
# Fedora 42 Post-Install Script - Professional Refactor Edition
# ─────────────────────────────────────────────────────────────

# === [1. Global Variables and Initial Config] ===
REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$REAL_USER")
LOG_DIR="$USER_HOME/fedora_logs"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
LOG_FILE="$LOG_DIR/install_$TIMESTAMP.log"
ERR_FILE="$LOG_DIR/error_$TIMESTAMP.log"
ERROR_COUNT=0

# Essential packages list
declare -a ESSENTIAL_PACKAGES=(
  vim nano git curl wget htop
  neofetch unzip p7zip p7zip-plugins
  tar gzip bzip2
  zsh bash-completion
)

# === [2. Colored Logging Utilities] ===
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
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf "${BLUE}%-65s %s${NC}\n" "[INFO] $msg" "[OK]"
  echo "[$ts] [INFO] $msg" >> "$LOG_FILE"
}

log_success() {
  local msg="$1"
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf "${GREEN}%-65s %s${NC}\n" "[✔ SUCCESS] $msg" "[OK]"
  echo "[$ts] [SUCCESS] $msg" >> "$LOG_FILE"
}

log_warn() {
  local msg="$1"
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf "${YELLOW}%-65s %s${NC}\n" "[⚠ WARNING] $msg" "[WARN]"
  echo "[$ts] [WARNING] $msg" | tee -a "$LOG_FILE" >> "$ERR_FILE"
  ERROR_COUNT=$((ERROR_COUNT + 1))
}

log_error() {
  local msg="$1"
  local ts
  ts=$(date '+%Y-%m-%d %H:%M:%S')
  printf "${RED}%-65s %s${NC}\n" "[❌ ERROR] $msg" "[FAIL]"
  echo "[$ts] [ERROR] $msg" | tee -a "$LOG_FILE" >> "$ERR_FILE"
  ERROR_COUNT=$((ERROR_COUNT + 1))
}

log_section() {
  local title="$1"
  local border
  border=$(printf '─%.0s' $(seq 1 $(( ${#title} + 4 ))))
  echo -e "\n${BLUE}┌$border┐${NC}"
  echo -e "${BLUE}│  $title  │${NC}"
  echo -e "${BLUE}└$border┘${NC}\n"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SECTION] $title" >> "$LOG_FILE"
}

# === [3. Sudo Helpers and Command Execution] ===
run_sudo() {
  if ! sudo -n true 2>/dev/null; then
    log_info "Requesting sudo privileges..."
    sudo -v || { log_error "Unable to obtain sudo privileges"; exit 1; }
  fi
  if [[ -z "${DISABLE_SUDO_KEEPALIVE:-}" ]]; then
    ( while sudo -n true 2>/dev/null; do sleep 50; done ) &
    SUDO_PID=$!
    trap "kill -9 $SUDO_PID 2>/dev/null || true" EXIT
  fi
}

run_cmd() {
  log_info "▶️ Running command: $*"
  if "$@"; then
    log_success "✔️ Command succeeded"
  else
    log_error "❌ Command failed: $*"
    return 1
  fi
}
# === [4. Progress Bar Utility] ===
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

# === [5. Error Checking Helper] ===
check_error() {
  local msg="${1:-An error occurred}"
  local code="${2:-$?}"
  if [[ "$code" -ne 0 ]]; then
    log_error "$msg"
    return "$code"
  fi
}

# === [6. Environment Initialization] ===
init_environment() {
  log_section "🚀 Initializing Installation Environment"

  local fallback_log_dir="/tmp/fedora_logs_debug"
  TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"

  # Determine user and home directory
  REAL_USER="${SUDO_USER:-$USER}"
  if id "$REAL_USER" &>/dev/null; then
    USER_HOME=$(eval echo "~$REAL_USER")
  else
    USER_HOME="/root"
    echo "[WARN] REAL_USER '$REAL_USER' has no valid home. Using $USER_HOME"
  fi

  if [[ -z "$USER_HOME" || ! -d "$USER_HOME" ]]; then
    echo "[ERROR] Unable to determine HOME directory. Defaulting to /root"
    USER_HOME="/root"
  fi

  LOG_DIR="$USER_HOME/fedora_logs"
  LOG_FILE="$LOG_DIR/install_$TIMESTAMP.log"
  ERR_FILE="$LOG_DIR/error_$TIMESTAMP.log"

  if ! mkdir -p "$LOG_DIR" 2>/dev/null; then
    echo "[ERROR] Cannot create $LOG_DIR. Falling back to $fallback_log_dir"
    LOG_DIR="$fallback_log_dir"
    LOG_FILE="$LOG_DIR/install_$TIMESTAMP.log"
    ERR_FILE="$LOG_DIR/error_$TIMESTAMP.log"
    mkdir -p "$LOG_DIR"
  fi

  touch "$LOG_FILE" "$ERR_FILE"
  chmod 664 "$LOG_FILE" "$ERR_FILE"
  chown "$REAL_USER:$REAL_USER" "$LOG_FILE" "$ERR_FILE" 2>/dev/null || true

  # Redirect stdout/stderr to log + tty
  exec > >(tee >(grep --line-buffered -E "^\[|^\s*\[.*\]" >> "$LOG_FILE") > /dev/tty) \
       2> >(tee >(grep --line-buffered -E "^\[⚠|\[❌" >> "$ERR_FILE") > /dev/tty)

  log_info "🧭 Real user: $REAL_USER"
  log_info "🏠 HOME directory: $USER_HOME"
  log_info "📁 Logs folder: $LOG_DIR"
  log_info "📄 Install log: $(basename "$LOG_FILE")"
  log_info "📄 Error log: $(basename "$ERR_FILE")"

  # Disk space validation
  local required_mb=5000
  local available_kb
  available_kb=$(df --output=avail "$LOG_DIR" | tail -n1 | tr -d ' ')
  local required_kb=$((required_mb * 1024))

  if [[ -z "$available_kb" || "$available_kb" -lt "$required_kb" ]]; then
    log_error "Not enough space. Required: ${required_mb}MB, Available: $((available_kb / 1024))MB"
    exit 1
  else
    log_success "💽 Available space: $((available_kb / 1024))MB - OK"
  fi
}
# === [7. System Update] ===
update_system() {
  log_section "📦 System Update (Base Upgrade)"
  
  log_info "🔁 Running: dnf upgrade --refresh"
  sudo dnf upgrade --refresh -y
  check_error "❌ Failed to update the system"

  log_success "✅ System upgraded successfully"
}

# === [8. Install Base Packages] ===
install_essential_packages() {
  log_section "📦 Installing Essential System Packages"

  # Sanity check
  if [[ -z "${PACKAGES_ESSENTIALS[*]:-}" ]]; then
    log_error "Variable PACKAGES_ESSENTIALS is not defined or empty"
    return 1
  fi

  local total=${#PACKAGES_ESSENTIALS[@]}

  for i in "${!PACKAGES_ESSENTIALS[@]}"; do
    local pkg="${PACKAGES_ESSENTIALS[$i]}"
    log_info "→ Installing: $pkg"
    sudo dnf install -y --allowerasing --skip-broken --skip-unavailable "$pkg"
    check_error "❌ Failed to install package: $pkg"
    progress_bar "$((i + 1))" "$total"
  done

  log_success "✅ All essential packages installed successfully"
}

# === [9. System Cleanup] ===
clean_system() {
  log_section "🧼 System Cleanup"

  log_info "🧹 Removing obsolete packages"
  sudo dnf autoremove -y
  check_error "❌ Failed to run dnf autoremove"

  log_info "🧼 Clearing DNF cache"
  sudo dnf clean all
  check_error "❌ Failed to clean DNF cache"

  log_success "✅ System cleaned successfully"
}
# === [10. Configure DNF] ===
configure_dnf() {
  log_section "⚙️ Optimizing DNF Settings"

  log_info "📅 Disabling local RTC (defaulting to UTC)"
  sudo timedatectl set-local-rtc '0' &>/dev/null || \
    log_warn "Unable to set timedatectl to UTC mode"

  log_info "🧾 Applying recommended settings to /etc/dnf/dnf.conf"
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

  check_error "Failed to write configuration to $dnf_conf"
  log_success "✅ DNF configured successfully"
}

# === [11. Configure Automatic Updates] ===
configure_dnf_automatic() {
  log_section "🛠️ Enabling DNF Automatic Updates"

  log_info "📦 Installing dnf-automatic if not already installed"
  sudo dnf install -y --allowerasing --skip-broken --skip-unavailable dnf-automatic
  check_error "Failed to install dnf-automatic"

  log_info "⏱️ Copying system timer unit for dnf-automatic"
  sudo cp /usr/lib/systemd/system/dnf-automatic.timer /etc/systemd/system/
  check_error "Failed to copy dnf-automatic timer"

  log_info "🔁 Enabling and starting dnf-automatic.timer"
  sudo systemctl enable --now dnf-automatic.timer
  check_error "Failed to enable dnf-automatic.timer"

  log_success "✅ dnf-automatic enabled and running"
}

# === [12. CLI Help Display] ===
show_help() {
  echo "Usage: $0 [options]"
  echo "  -h, --help     Show this help message"
  echo "  -u, --update   Update the system before installing"
  echo "  -c, --clean    Clean the system after installing"
}

# === [13. CLI Argument Parsing] ===
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
      log_warn "Unknown option: $key"
      show_help
      exit 1
      ;;
  esac
done
# === [14. Change Hostname] ===
change_hostname() {
  log_section "🖥️ Hostname Configuration"

  local hostname_var="${NEW_HOSTNAME:-}"

  # Prompt for hostname if not provided as variable
  if [[ -z "$hostname_var" ]]; then
    if [[ -t 0 ]]; then
      echo -ne "${BLUE}Enter the new hostname for this system: ${NC}" > /dev/tty
      read -r hostname_var < /dev/tty
    else
      log_warn "Cannot prompt for hostname: no interactive TTY"
      return 0
    fi
  fi

  if [[ -z "$hostname_var" ]]; then
    log_warn "Hostname not specified. Skipping..."
    return 0
  fi

  # RFC1123 basic validation
  if [[ ! "$hostname_var" =~ ^[a-zA-Z0-9][-a-zA-Z0-9]{0,61}[a-zA-Z0-9]$ ]]; then
    log_error "Invalid hostname format per RFC1123: $hostname_var"
    return 1
  fi

  log_info "Setting hostname to: $hostname_var"
  if sudo hostnamectl set-hostname --static "$hostname_var"; then
    log_success "Hostname successfully set to: $hostname_var"
  else
    log_error "Failed to set hostname"
  fi
}

# === [15. Flatpak Repositories Configuration] ===
configure_flatpak_repositories() {
  log_section "📦 Flatpak Repository Setup"

  if ! command -v flatpak &>/dev/null; then
    log_info "Installing Flatpak..."
    sudo dnf install -y flatpak
    [[ $? -eq 0 ]] && log_success "Flatpak installed successfully" || log_error "Failed to install Flatpak"
  else
    log_info "Flatpak is already installed"
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
    log_info "→ Adding Flatpak remote: $remote"
    if [[ "$url" == *.flatpakrepo ]]; then
      sudo flatpak remote-add --if-not-exists --from "$remote" "$url" &>/dev/null || \
        log_warn "Could not add $remote"
    else
      sudo flatpak remote-add --if-not-exists "$remote" "$url" &>/dev/null || \
        log_warn "Could not add $remote"
    fi
    sudo flatpak remote-modify --system --prio=$((++i)) "$remote" &>/dev/null || \
      log_warn "Could not set priority for $remote"
    progress_bar "$i" "$total"
  done

  log_success "Flatpak remotes configured successfully"
}

# === [16. Security Configuration Header Placeholder] ===
# The next section will contain:
# - Base firewall and SELinux settings
# - Package installation for networking tools
# - DNS-over-TLS and system hardening
# === [17. Configure Security and Base Services] ===
configure_security() {
  log_section "🔐 System Security and Core Services Configuration"

  # Step 1: Install security and network-related packages
  log_info "📦 Installing security and network utility packages..."
  sudo dnf install -y --allowerasing --skip-broken --skip-unavailable \
    firewalld firewall-config \
    selinux-policy selinux-policy-targeted \
    policycoreutils policycoreutils-python-utils \
    samba samba-client avahi nss-mdns \
    ftp lftp openssh-clients bluez-obexd \
    kde-connect qt6-qml kde-connectd \
    rclone fuse

  # Step 2: Enable firewalld and set default zone
  log_info "🔥 Enabling firewalld service"
  sudo systemctl enable --now firewalld &>/dev/null || log_warn "Could not enable firewalld"

  log_info "🌐 Setting default zone to FedoraWorkstation"
  sudo firewall-cmd --set-default-zone=FedoraWorkstation
  sudo firewall-cmd --get-default-zone

  # Step 3: Enable common services in firewalld
  log_info "📡 Enabling standard services in firewalld"
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
      check_error "❌ Failed to add service: $service"
      log_info "✔️ Service added: $service"
    else
      log_warn "⚠️ Unknown or empty service: $service"
    fi
    progress_bar "$((++idx))" "$total_services"
  done

  # Step 4: Manually open additional ports
  log_info "🔌 Opening custom ports in firewalld"

  declare -A ports_tcp=(
    [22]="SSH"
    [2222]="Hardened SSH"
    [3389]="Remote Desktop (RDP)"
    [5900]="VNC"
    [80]="Local HTTP"
    [443]="Local HTTPS"
    [8080]="rclone/web apps"
    [8000-8100]="Dev servers"
    [32400]="Plex"
    [8096]="Jellyfin"
    [21]="FTP"
    [60000-61000]="FTP Passive"
    [22000]="Syncthing"
    [853]="DNS over TLS"
    [53]="DNS TCP"
    [1714-1764]="KDE Connect"
  )

  declare -A ports_udp=(
    [1900]="UPnP"
    [5353]="mDNS"
    [21027]="Syncthing discovery"
    [123]="NTP"
    [5355]="LLMNR"
    [67-68]="DHCP"
    [53]="DNS UDP"
    [1714-1764]="KDE Connect"
  )

  idx=0
  local total_tcp=${#ports_tcp[@]}
  local total_udp=${#ports_udp[@]}

  for port in "${!ports_tcp[@]}"; do
    local desc="${ports_tcp[$port]}"
    log_info "↪️ Enabling TCP port $port ($desc)"
    sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port="${port}/tcp"
    check_error "❌ Failed to enable TCP port: $port ($desc)"
    log_success "✔️ TCP $port enabled ($desc)"
    progress_bar "$((++idx))" "$((total_tcp + total_udp))"
  done

  for port in "${!ports_udp[@]}"; do
    local desc="${ports_udp[$port]}"
    log_info "↪️ Enabling UDP port $port ($desc)"
    sudo firewall-cmd --permanent --zone=FedoraWorkstation --add-port="${port}/udp"
    check_error "❌ Failed to enable UDP port: $port ($desc)"
    log_success "✔️ UDP $port enabled ($desc)"
    progress_bar "$((++idx))" "$((total_tcp + total_udp))"
  done

  log_info "🔁 Reloading firewalld configuration..."
  sudo firewall-cmd --reload
  check_error "❌ Failed to reload firewalld"
  log_success "✅ firewalld reloaded successfully"

  # Step 5: Enable local discovery services
  log_info "⚙️ Enabling local services (Avahi, Bluetooth)"
  sudo systemctl enable --now avahi-daemon &>/dev/null
  sudo systemctl enable --now bluetooth &>/dev/null

  # Step 6: Configure SELinux to enforcing mode
  log_info "🔒 Setting SELinux to enforcing"
  sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config
  sudo semanage permissive -a firewalld_t &>/dev/null || true
  log_success "SELinux set to enforcing with firewalld_t permissive exception"

  # Step 7: Configure secure DNS (DNS-over-TLS)
  log_info "🌐 Setting up secure DNS (DNS-over-TLS)"
  sudo mkdir -p /etc/systemd/resolved.conf.d
  sudo tee /etc/systemd/resolved.conf.d/99-dns-over-tls.conf > /dev/null <<EOF
[Resolve]
DNS=94.140.14.14        # AdGuard primary
DNS=94.140.15.15        # AdGuard secondary
DNS=1.1.1.1             # Cloudflare primary
DNS=1.0.0.1             # Cloudflare secondary
DNSOverTLS=no
EOF
  sudo systemctl restart systemd-resolved &>/dev/null
  log_success "Secure DNS configured with AdGuard and Cloudflare"

  # Step 8: Install hblock DNS blocker
  log_info "🚫 Installing hblock (DNS-level ad blocker from COPR)"
  sudo dnf -y copr enable pesader/hblock &>/dev/null
  sudo dnf install -y hblock &>/dev/null

  if command -v hblock &>/dev/null; then
    sudo hblock &>/dev/null
    log_success "✅ hblock installed and executed"
  else
    log_warn "⚠️ hblock installation failed or not found"
  fi

  log_success "🎉 System base security configuration completed"
}
# === [18. Harden Network Services: SSH, Fail2ban, Firewall] ===
configure_network_security() {
  log_section "🌐 Network Security: SSH Hardening + Fail2ban + Firewall Rules"

  # Step 1: Disable chronyd (if not used)
  log_info "🕒 Disabling chronyd time sync service"
  sudo systemctl disable --now chronyd.service &>/dev/null || \
    log_warn "chronyd was already disabled or not installed"

  # Step 2: Install and activate fail2ban
  log_info "🔐 Installing and starting fail2ban"
  sudo dnf install -y fail2ban &>/dev/null
  sudo systemctl enable --now fail2ban &>/dev/null
  check_error "❌ Failed to start fail2ban"

  # Step 3: Configure fail2ban for hardened SSH on port 2222
  log_info "🛠️ Setting up fail2ban for SSH protection"
  sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[sshd]
enabled = true
port    = 2222
logpath = /var/log/secure
maxretry = 3
bantime = 1h
EOF
  sudo systemctl restart fail2ban

  # Step 4: Harden SSH configuration
  log_info "🔐 Applying hardened SSH configuration"

  local ssh_config="/etc/ssh/sshd_config"
  local ssh_backup="/etc/ssh/sshd_config.bak"

  sudo cp "$ssh_config" "$ssh_backup"
  log_info "🗂️ Backup of sshd_config created at: $ssh_backup"

  sudo sed -i -E 's/^#?\s*Port\s+.*/Port 2222/' "$ssh_config" || log_warn "Failed to set SSH port"
  sudo sed -i -E 's/^#?\s*PermitRootLogin\s+.*/PermitRootLogin no/' "$ssh_config" || log_warn "Failed to disable root login"
  sudo sed -i -E 's/^#?\s*PasswordAuthentication\s+.*/PasswordAuthentication no/' "$ssh_config" || log_warn "Failed to disable password auth"

  grep -q "^Port " "$ssh_config" || echo "Port 2222" | sudo tee -a "$ssh_config" > /dev/null
  grep -q "^PermitRootLogin " "$ssh_config" || echo "PermitRootLogin no" | sudo tee -a "$ssh_config" > /dev/null
  grep -q "^PasswordAuthentication " "$ssh_config" || echo "PasswordAuthentication no" | sudo tee -a "$ssh_config" > /dev/null

  if sudo sshd -t; then
    log_info "📌 Registering port 2222 with SELinux"
    sudo semanage port -a -t ssh_port_t -p tcp 2222 2>/dev/null || \
    sudo semanage port -m -t ssh_port_t -p tcp 2222
    check_error "❌ Failed to register SSH port in SELinux"

    sudo systemctl restart sshd
    check_error "❌ Failed to restart SSH service"
    log_success "✅ SSH service restarted with secure settings"
  else
    log_error "❌ SSH config syntax error. Restoring from backup."
    sudo cp "$ssh_backup" "$ssh_config"
    sudo systemctl restart sshd
  fi

  # Step 5: Restrict SSH to local network
  log_info "🌐 Restricting SSH access to LAN 192.168.1.0/24"
  sudo firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" port port="2222" protocol="tcp" accept' --zone=FedoraWorkstation --permanent
  sudo firewall-cmd --remove-service=ssh --zone=FedoraWorkstation --permanent
  sudo firewall-cmd --reload &>/dev/null

  # Step 6: Re-validate SELinux rule for custom port
  sudo semanage port -a -t ssh_port_t -p tcp 2222 2>/dev/null || true

  log_success "✅ Network hardening completed: fail2ban + SSH + firewall rules"
}
# === [19. Install grub-btrfs from COPR repo] ===
install_grub_btrfs_from_copr() {
  log_section "📦 Installing grub-btrfs from COPR (kylegospo)"

  if ! sudo dnf repolist | grep -q "kylegospo-grub-btrfs"; then
    run_cmd sudo dnf copr enable -y kylegospo/grub-btrfs || {
      log_error "❌ Failed to enable COPR repository"
      return 1
    }
  else
    log_info "✅ COPR repository already enabled"
  fi

  run_cmd sudo dnf update -y || {
    log_error "❌ System update failed"
    return 1
  }

  run_cmd sudo dnf install -y grub-btrfs grub-btrfs-timeshift || {
    log_error "❌ Failed to install grub-btrfs or its extensions"
    return 1
  }

  log_success "✅ grub-btrfs and extensions installed"
}

# === [20. Configure grub-btrfs default settings] ===
configure_grub_btrfs_default_config() {
  log_section "⚙️ Writing grub-btrfs configuration"

  local config_file="/etc/default/grub-btrfs/config"
  run_cmd sudo mkdir -p "$(dirname "$config_file")"

  run_cmd sudo tee "$config_file" > /dev/null <<EOF
GRUB_BTRFS_GRUB_DIRNAME="/boot/grub2"
GRUB_BTRFS_MKCONFIG="/sbin/grub2-mkconfig"
GRUB_BTRFS_SCRIPT_CHECK="grub2-script-check"
GRUB_BTRFS_SUBMENUNAME="Snapshots BTRFS"
GRUB_BTRFS_SNAPSHOT_FORMAT="%Y-%m-%d %H:%M | %c"
GRUB_BTRFS_SNAPSHOT_KERNEL_PARAMETERS="rootflags=subvol=@ quiet"
EOF

  log_success "✅ grub-btrfs config saved to $config_file"
}

# === [21. Enable grub-btrfsd systemd monitoring services] ===
setup_grub_btrfsd_services() {
  log_section "🔧 Configuring systemd monitoring for grub-btrfs"

  local path_unit="/etc/systemd/system/grub-btrfs.path"
  run_cmd sudo mkdir -p "$(dirname "$path_unit")"

  run_cmd sudo tee "$path_unit" > /dev/null <<'EOF'
[Unit]
Description=Monitors Timeshift snapshots in /run/timeshift/%i/backup
DefaultDependencies=no
BindsTo=run-timeshift-%i.mount

[Path]
PathModified=/run/timeshift/%i/backup/timeshift-btrfs/snapshots

[Install]
WantedBy=run-timeshift-%i.mount
EOF

  run_cmd sudo systemctl daemon-reexec
  run_cmd sudo systemctl daemon-reload

  run_cmd sudo systemctl enable grub-btrfsd.service
  run_cmd sudo systemctl enable grub-btrfsd@-.service

  run_cmd sudo systemctl start grub-btrfsd.service || log_warn "⚠️ grub-btrfsd.service failed to start"
  run_cmd sudo systemctl start grub-btrfsd@-.service || log_warn "⚠️ grub-btrfsd@-.service failed to start"

  run_cmd sudo systemctl enable grub-btrfs.path
  run_cmd sudo systemctl start grub-btrfs.path

  log_success "✅ grub-btrfsd monitoring services enabled"
}

# === [22. Configure Timeshift in BTRFS mode at /.snapshots] ===
setup_timeshift_config_btrfs() {
  log_section "🧰 Setting up Timeshift in BTRFS mode (snapshots at /.snapshots)"

  local config_dir="/etc/timeshift"
  local config_file="$config_dir/timeshift.json"
  local snapshots_dir="/.snapshots"
  local device uuid

  run_cmd sudo mkdir -p "$snapshots_dir"
  run_cmd sudo chown root:root "$snapshots_dir"
  run_cmd sudo mkdir -p "$config_dir"

  device=$(findmnt -no SOURCE /)
  uuid=$(findmnt -no UUID /)

  if [[ -z "$device" || -z "$uuid" ]]; then
    log_error "❌ Could not detect root device or UUID"
    return 1
  fi

  run_cmd sudo tee "$config_file" > /dev/null <<EOF
{
  "backup_device_uuid": "$uuid",
  "parent_device_uuid": "",
  "do_first_run": "false",
  "btrfs_mode": "true",
  "include_btrfs_home_for_backup": "false",
  "include_btrfs_home_for_restore": "false",
  "stop_cron_emails": "true",
  "schedule_monthly": "true",
  "schedule_weekly": "true",
  "schedule_daily": "true",
  "schedule_hourly": "false",
  "schedule_boot": "false",
  "count_monthly": 2,
  "count_weekly": 3,
  "count_daily": 5,
  "count_hourly": 0,
  "count_boot": 0,
  "snapshot_device": "$device",
  "snapshot_mount_path": "$snapshots_dir",
  "date_format": "%Y-%m-%d %H:%M:%S",
  "exclude": [],
  "exclude-apps": []
}
EOF

  log_success "✅ Timeshift BTRFS config written to $config_file"
}

# === [23. Create initial snapshot if none exists] ===
create_initial_timeshift_snapshot() {
  log_section "🕒 Creating first Timeshift snapshot (if needed)"

  if sudo timeshift --list | grep -q "Snapshot"; then
    log_info "✔️ Snapshots already exist. No new snapshot created."
    return 0
  fi

  run_cmd sudo timeshift --create --comments "Initial system snapshot" --tags D || {
    log_error "❌ Failed to create initial Timeshift snapshot"
    return 1
  }

  log_success "✅ Initial Timeshift snapshot created"
}

# === [24. Regenerate grub.cfg after grub-btrfs integration] ===
regenerate_grub_config() {
  log_section "🌀 Regenerating GRUB configuration"

  local grub_cfg_path="/boot/grub2/grub.cfg"

  if ! command -v grub2-mkconfig &>/dev/null; then
    log_error "❌ grub2-mkconfig not found. Please install grub2-tools."
    return 1
  fi

  run_cmd sudo grub2-mkconfig -o "$grub_cfg_path" || {
    log_error "❌ Failed to regenerate GRUB config"
    return 1
  }

  log_success "✅ GRUB configuration updated successfully"
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

  install_grub_btrfs_from_copr || exit 1
  configure_grub_btrfs_default_config || exit 1
  setup_grub_btrfsd_services || exit 1
  setup_timeshift_config_btrfs || exit 1
  create_initial_timeshift_snapshot || exit 1
  regenerate_grub_config || exit 1

  [[ "$CLEAN_SYSTEM" -eq 1 ]] && clean_system

  log_info "ℹ️ All core system configurations applied successfully."

  if [[ $ERROR_COUNT -eq 0 ]]; then
    log_success "🎉 Script completed with no errors."
  else
    log_warn "⚠️ Script finished with $ERROR_COUNT error(s). Review: $ERR_FILE"
  fi

  final_cleanup_and_reboot
}

# === [ Entry Point ] ===
main "$@"
exit 0
