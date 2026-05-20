#!/usr/bin/env bash
################################################################################
# SCRIPT 1: FEDORA 42+ CLI SYSTEM CORE, HARDENING & HARDWARE OPTIMIZATION
# Refactored: Uses centralized helpers and .env configuration
# Autor: Gabriel Omaña – Initium
################################################################################

set -euo pipefail
IFS=$'\n\t'

REAL_USER="${SUDO_USER:-$USER}"
USER_HOME=$(eval echo "~$REAL_USER")
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "${SCRIPT_DIR}/sources/helpers/functions.sh"
source "${SCRIPT_DIR}/sources/config/.env"

trap 'handle_error ${LINENO} "Script interrupted"' ERR INT TERM

declare -a FALLBACK_PACKAGES=(
  vim nano git curl wget htop fastfetch unzip p7zip p7zip-plugins tar gzip bzip2 zsh bash-completion
  firewalld policycoreutils policycoreutils-python-utils openssh-clients fail2ban rclone
  bat jq ripgrep fd-find eza cpuid cpu-x npm python3-pip pipx
)

init_environment() {
  [[ $EUID -ne 0 ]] && { log_error "Run with: sudo $0"; exit 1; }

  mkdir -p "$LOG_DIR"
  touch "$LOG_FILE" "$ERROR_LOG"
  chmod 664 "$LOG_FILE" "$ERROR_LOG"
  chown "$REAL_USER:$REAL_USER" "$LOG_FILE" "$ERROR_LOG" 2>/dev/null || true

  log_info "👤 Running as: $REAL_USER"
  log_info "📁 Logs: $LOG_DIR"

  local required_kb=$((5000 * 1024))
  local available_kb=$(df --output=avail "$LOG_DIR" | tail -n1 | tr -d ' ')
  [[ "$available_kb" -lt "$required_kb" ]] && { log_error "Insufficient disk space"; exit 1; }
}

show_welcome_banner() {
  log_section "FEDORA3 - SCRIPT 1: SYSTEM CORE HARDENING"
  log_info "Kernel: $(uname -r) | Fedora: $FEDORA_VERSION | GPU: $GPU_TYPE"
  log_info ""
  log_info "This script will:"
  log_info "  1. Tune DNF (parallel downloads=$DNF_MAXPARALLEL)"
  log_info "  2. Install essential CLI tools & development packages"
  log_info "  3. Deploy network security (Firewall, DNS-over-TLS, fail2ban)"
  log_info "  4. Inject CPU microcode (Intel/AMD)"
  log_info "  5. Configure BTRFS for Timeshift snapshots"
  log_info ""

  echo -ne "Proceed? (y/n): " > /dev/tty
  read -r proceed < /dev/tty
  [[ ! "$proceed" =~ ^[Yy]$ ]] && { log_info "Cancelled"; exit 0; }
}

change_hostname() {
  log_section "🖥️ System Hostname Setup"

  local default_hostname="hal9k"
  local hostname_var=""

  [[ -t 0 ]] && {
    echo -ne "Enter hostname [default: $default_hostname]: " > /dev/tty
    read -r hostname_var < /dev/tty
  }

  hostname_var="${hostname_var:-$default_hostname}"

  if [[ "$hostname_var" =~ ^[a-zA-Z0-9][-a-zA-Z0-9]{0,61}[a-zA-Z0-9]$ ]]; then
    sudo hostnamectl set-hostname --static "$hostname_var"
    log_success "Hostname set to: $hostname_var"
  else
    log_error "Invalid hostname (RFC1123) - skipping"
  fi
}

configure_dnf() {
  log_section "⚙️ DNF Tuning"

  sudo timedatectl set-local-rtc 1 --adjust-system-clock &>/dev/null || log_warn "RTC local not available"

  local dnf_conf="/etc/dnf/dnf.conf"
  create_backup "$dnf_conf" || true

  sudo tee "$dnf_conf" > /dev/null <<EOF
[main]
gpgcheck=1
installonly_limit=3
clean_requirements_on_remove=True
best=False
skip_if_unavailable=True
fastestmirror=$DNF_FASTESTMIRROR
max_parallel_downloads=$DNF_MAXPARALLEL
defaultyes=True
keepcache=$DNF_KEEPCACHE
deltarpm=True
EOF
  log_success "DNF configured: $DNF_MAXPARALLEL parallel downloads"
}

configure_dnf_automatic() {
  log_section "🛠️ Automatic Security Updates"

  [[ "$ENABLE_AUTOMATIC_UPDATES" != "true" ]] && { log_info "Auto-updates disabled"; return 0; }

  sudo dnf install -y dnf-automatic &>> "$LOG_FILE"
  sudo systemctl enable --now dnf-automatic.timer
  log_success "Automatic updates enabled"
}

configure_repositories() {
  log_section "🌐 Essential Repositories"

  add_repository "rpmfusion-free" "free" || log_warn "RPM Fusion Free already enabled"
  add_repository "rpmfusion-nonfree" "nonfree" || log_warn "RPM Fusion Non-Free already enabled"

  log_success "RPM Fusion repositories linked"
}

install_essential_packages() {
  log_section "📦 CLI Utilities & Development Tools"

  local list_file="${SCRIPT_DIR}/sources/lists/cli_tools.list"
  local -a packages_to_install=()

  if [[ -f "$list_file" ]]; then
    log_info "Reading packages from: $(basename "$list_file")"
    mapfile -t raw_lines < "$list_file"
    for line in "${raw_lines[@]}"; do
      local clean_line=$(echo "$line" | sed 's/#.*//' | xargs)
      [[ -z "$clean_line" ]] && continue
      packages_to_install+=("$clean_line")
    done
  else
    log_warn "cli_tools.list not found - using fallback packages"
    packages_to_install=("${FALLBACK_PACKAGES[@]}")
  fi

  log_info "Installing development-tools and c-development"
  sudo dnf group install -y --allowerasing --skip-broken \
    "development-tools" "c-development" &>> "$LOG_FILE"

  local total=${#packages_to_install[@]}
  local i=0
  for pkg in "${packages_to_install[@]}"; do
    ((i++))
    sudo dnf install -y --allowerasing --skip-broken "$pkg" &>> "$LOG_FILE"
    draw_progress_bar "$i" "$total"
  done

  log_success "CLI tools and development packages installed"
}

configure_flatpak_repositories() {
  log_section "📦 Flatpak Integration"

  sudo dnf install -y flatpak &>> "$LOG_FILE"

  sudo flatpak remote-add --if-not-exists flathub "$FLATPAK_FLATHUB_URL" 2>/dev/null || true
  sudo flatpak remote-add --if-not-exists kde "https://distribute.kde.org/kdeapps.flatpakrepo" 2>/dev/null || true

  log_success "Flatpak configured with flathub and KDE remotes"
}

configure_security() {
  log_section "🔐 Network Hardening & DNS Privacy"

  sudo systemctl enable --now firewalld &>/dev/null
  sudo firewall-cmd --set-default-zone="$FIREWALL_ZONE"

  log_info "Adding firewall rules..."
  sudo firewall-cmd --permanent --zone="$FIREWALL_ZONE" --add-service=mdns &>> "$LOG_FILE" || true
  sudo firewall-cmd --permanent --zone="$FIREWALL_ZONE" --add-service=bluetooth &>> "$LOG_FILE" || true
  sudo firewall-cmd --permanent --zone="$FIREWALL_ZONE" --add-port=32400/tcp &>> "$LOG_FILE" || true
  sudo firewall-cmd --permanent --zone="$FIREWALL_ZONE" --add-port=1714-1764/tcp &>> "$LOG_FILE" || true
  sudo firewall-cmd --permanent --zone="$FIREWALL_ZONE" --add-port=1714-1764/udp &>> "$LOG_FILE" || true
  sudo firewall-cmd --permanent --zone="$FIREWALL_ZONE" --add-port=3389/tcp &>> "$LOG_FILE" || true
  sudo firewall-cmd --permanent --zone="$FIREWALL_ZONE" --add-port=22000/tcp &>> "$LOG_FILE" || true

  log_info "Configuring DNS-over-TLS..."
  sudo mkdir -p /etc/systemd/resolved.conf.d
  sudo tee /etc/systemd/resolved.conf.d/99-dns-over-tls.conf > /dev/null <<EOF
[Resolve]
DNS=$DNS_PRIMARY $DNS_SECONDARY $DNS_FALLBACK1 $DNS_FALLBACK2
DNSOverTLS=yes
EOF
  sudo systemctl restart systemd-resolved &>/dev/null

  [[ "$ENABLE_SELINUX" == "true" ]] && sudo sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

  log_success "Firewall, DNS-over-TLS, and SELinux enforcing enabled"
}

configure_network_security() {
  log_section "🌐 SSH Hardening & Fail2Ban"

  [[ "$ENABLE_FAIL2BAN" == "true" ]] && sudo systemctl enable --now fail2ban &>/dev/null

  log_info "Configuring fail2ban for port $SSH_PORT..."
  sudo tee /etc/fail2ban/jail.local > /dev/null <<EOF
[sshd]
enabled = true
port    = $SSH_PORT
logpath = /var/log/secure
maxretry = $FAIL2BAN_MAXRETRY
bantime = $FAIL2BAN_BANTIME
findtime = $FAIL2BAN_FINDTIME
EOF
  sudo systemctl restart fail2ban

  local ssh_config="/etc/ssh/sshd_config"
  create_backup "$ssh_config" || true

  sudo sed -i -E "s/^#?\s*Port\s+.*/Port $SSH_PORT/" "$ssh_config"
  sudo sed -i -E 's/^#?\s*PermitRootLogin\s+.*/PermitRootLogin no/' "$ssh_config"
  sudo sed -i -E 's/^#?\s*PasswordAuthentication\s+.*/PasswordAuthentication no/' "$ssh_config"
  sudo sed -i -E "s/^#?\s*ClientAliveInterval\s+.*/ClientAliveInterval $SSH_TIMEOUT/" "$ssh_config"

  if sudo sshd -t; then
    sudo semanage port -a -t ssh_port_t -p tcp "$SSH_PORT" 2>/dev/null || \
    sudo semanage port -m -t ssh_port_t -p tcp "$SSH_PORT" 2>/dev/null || true
    sudo systemctl restart sshd
    log_success "SSH hardened on port $SSH_PORT (root login disabled)"
  else
    log_error "SSH config syntax error - restoring backup"
    sudo cp "${ssh_config}.bak" "$ssh_config"
    sudo systemctl restart sshd
    return 1
  fi

  sudo firewall-cmd --permanent --zone="$FIREWALL_ZONE" \
    --add-rich-rule="rule family=\"ipv4\" source address=\"192.168.1.0/24\" port port=\"$SSH_PORT\" protocol=\"tcp\" accept" &>> "$LOG_FILE" || true
  sudo firewall-cmd --permanent --zone="$FIREWALL_ZONE" --remove-service=ssh &>> "$LOG_FILE" || true
  sudo firewall-cmd --reload &>> "$LOG_FILE" || true

  log_success "Fail2Ban and SSH hardening complete"
}

configure_cpu_hardware() {
  log_section "🧠 CPU Microcode Injection"

  [[ "$IS_VIRTUAL_MACHINE" == "true" ]] && { log_info "Virtual machine - skipping microcode"; return 0; }
  [[ "$ENABLE_MICROCODE" != "true" ]] && { log_warn "Microcode injection disabled"; return 0; }

  local cpu_name=$(lscpu | grep -Ei 'Model name' | head -1 | cut -d':' -f2 | xargs)
  log_info "Physical CPU: $cpu_name"

  case "$cpu_name" in
    *Intel*)
      log_info "Injecting Intel microcode..."
      sudo dnf install -y --enablerepo=rpmfusion-nonfree microcode_ctl &>> "$LOG_FILE"
      log_success "Intel microcode injected"
      ;;
    *AMD*)
      log_info "Injecting AMD microcode..."
      sudo dnf install -y --enablerepo=rpmfusion-nonfree amd-ucode &>> "$LOG_FILE"
      log_info "Regenerating initramfs..."
      sudo dracut -f &>> "$LOG_FILE"
      log_success "AMD microcode injected and initramfs updated"
      ;;
    *)
      log_warn "CPU vendor not recognized - skipping microcode injection"
      ;;
  esac
}

configure_btrfs_volumes() {
  log_section "🗂️ BTRFS Subvolume Architecture"

  local fs_type=$(findmnt -n -o FSTYPE /)
  [[ "$fs_type" != "btrfs" ]] && { log_warn "Not BTRFS - skipping"; return 0; }

  validate_btrfs_structure || { log_error "BTRFS validation failed"; return 1; }

  sudo dnf install -y btrfs-progs &>> "$LOG_FILE"

  local root_device=$(findmnt -n -o SOURCE /)
  local uuid=$(get_btrfs_uuid)
  local tmp_mnt="/tmp/btrfs_toplevel"

  sudo mkdir -p "$tmp_mnt"
  sudo mount -o subvolid=5 "$root_device" "$tmp_mnt" || { log_error "Cannot mount BTRFS root"; return 1; }

  # Clone legacy subvolumes to new names
  [[ -d "$tmp_mnt/root" && ! -d "$tmp_mnt/@" ]] && \
    sudo btrfs subvolume snapshot "$tmp_mnt/root" "$tmp_mnt/@" 2>/dev/null || true

  [[ -d "$tmp_mnt/home" && ! -d "$tmp_mnt/@home" ]] && \
    sudo btrfs subvolume snapshot "$tmp_mnt/home" "$tmp_mnt/@home" 2>/dev/null || true

  # Create missing subvolumes
  for subvol in "${BTRFS_SUBVOLS[@]}"; do
    [[ ! -d "$tmp_mnt/$subvol" ]] && \
      sudo btrfs subvolume create "$tmp_mnt/$subvol" &>> "$LOG_FILE"
  done

  sudo umount "$tmp_mnt" && sudo rm -rf "$tmp_mnt"

  log_info "Updating fstab with optimal mount options..."
  create_backup "/etc/fstab" || true
  sudo sed -i -E '/\s+(\/|\/var\/log|\/var\/tmp|\/\.snapshots)\s+btrfs/d' /etc/fstab

  declare -A subvols=(
    ["/"]="@"
    ["/var/log"]="@log"
    ["/var/tmp"]="@var_tmp"
    ["/.snapshots"]="@snapshots"
  )

  for mount_point in "${!subvols[@]}"; do
    echo "UUID=$uuid $mount_point btrfs rw,$BTRFS_MOUNT_OPTS,subvol=${subvols[$mount_point]} 0 0" | \
      sudo tee -a /etc/fstab > /dev/null
  done

  log_info "Updating kernel bootloader configuration..."
  [[ -f "/etc/kernel/cmdline" ]] && \
    sudo sed -i 's/rootflags=subvol=root/rootflags=subvol=@/g' /etc/kernel/cmdline
  [[ -d "/boot/loader/entries" ]] && \
    sudo sed -i 's/rootflags=subvol=root/rootflags=subvol=@/g' /boot/loader/entries/*.conf 2>/dev/null || true
  sudo sed -i 's/rootflags=subvol=root/rootflags=subvol=@/g' /etc/default/grub 2>/dev/null || true

  log_success "BTRFS subvolume architecture configured"
}

cleanup() {
  log_section "🧼 Cleanup & Finalization"
  log_info "Removing orphaned dependencies..."
  sudo dnf autoremove -y &>> "$LOG_FILE"
  sudo dnf clean all &>> "$LOG_FILE"
  log_success "Cleanup complete"
}

main() {
  init_environment
  show_welcome_banner

  configure_dnf
  configure_dnf_automatic
  change_hostname
  configure_repositories
  install_essential_packages
  configure_flatpak_repositories
  configure_security
  configure_network_security

  configure_cpu_hardware
  configure_btrfs_volumes

  cleanup

  log_section "🎉 SCRIPT 1 COMPLETE"
  log_success "System core hardened and optimized"
  log_warn "⚠️  REBOOT REQUIRED - Kernel and BTRFS changes need reboot"
  log_info ""

  echo -ne "Reboot now? (y/n): " > /dev/tty
  read -r choice < /dev/tty
  [[ "$choice" =~ ^[Yy]$ ]] && sudo reboot
}

main "$@"
exit 0
