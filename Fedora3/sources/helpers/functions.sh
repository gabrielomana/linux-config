#!/bin/bash
################################################################################
# FEDORA3 AUTOMATION SUITE - SHARED HELPER FUNCTIONS
# Funciones reutilizables para todos los scripts de instalación
# Author: Claude Code (Especialista Linux/Fedora/Bash)
# License: MIT
################################################################################

set -euo pipefail

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Logging directory
LOG_DIR="${HOME}/fedora_logs"
mkdir -p "$LOG_DIR"
LOG_FILE="${LOG_DIR}/fedora_$(date +%Y%m%d_%H%M%S).log"
ERROR_LOG="${LOG_DIR}/fedora_errors.log"

################################################################################
# LOGGING FUNCTIONS
################################################################################

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $message" | tee -a "$LOG_FILE"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[✓]${NC} $message" | tee -a "$LOG_FILE"
}

log_error() {
    local message="$1"
    echo -e "${RED}[ERROR]${NC} $message" | tee -a "$LOG_FILE" "$ERROR_LOG"
}

log_warn() {
    local message="$1"
    echo -e "${YELLOW}[WARN]${NC} $message" | tee -a "$LOG_FILE"
}

log_section() {
    local title="$1"
    echo -e "\n${BOLD}${BLUE}═══════════════════════════════════════${NC}"
    echo -e "${BOLD}${BLUE}  $title${NC}"
    echo -e "${BOLD}${BLUE}═══════════════════════════════════════${NC}\n" | tee -a "$LOG_FILE"
}

################################################################################
# ERROR HANDLING
################################################################################

handle_error() {
    local exit_code=$?
    local line_number=$1
    local message="${2:-Unknown error}"

    log_error "Script failed at line $line_number: $message (exit code: $exit_code)"
    exit "$exit_code"
}

run_or_fail() {
    local command="$@"
    log_info "Executing: $command"

    if ! eval "$command"; then
        log_error "Command failed: $command"
        return 1
    fi
    return 0
}

################################################################################
# COMMAND VALIDATION
################################################################################

check_command() {
    local cmd="$1"

    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command not found: $cmd"
        return 1
    fi
    return 0
}

validate_prerequisites() {
    local -a required_commands=("$@")
    local missing=()

    log_info "Validating prerequisites..."

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing+=("$cmd")
            log_warn "Missing command: $cmd"
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing[*]}"
        log_info "Install with: sudo dnf install -y ${missing[*]}"
        return 1
    fi

    log_success "All prerequisites validated"
    return 0
}

################################################################################
# PACKAGE MANAGEMENT - DNF
################################################################################

package_installed() {
    local package="$1"
    dnf list installed "$package" &>/dev/null
}

dnf_install() {
    local -a packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        log_error "No packages specified"
        return 1
    fi

    log_info "Installing packages: ${packages[*]}"

    if ! sudo dnf install -y "${packages[@]}"; then
        log_error "Failed to install packages: ${packages[*]}"
        return 1
    fi

    log_success "Packages installed successfully"
    return 0
}

dnf_update_if_needed() {
    log_info "Checking for system updates..."

    if dnf check-update -q &>/dev/null; then
        return 0
    fi

    log_info "Applying system updates..."

    if ! sudo dnf update -y; then
        log_error "Failed to update system"
        return 1
    fi

    log_success "System updated"
    return 0
}

dnf_remove() {
    local -a packages=("$@")

    if [ ${#packages[@]} -eq 0 ]; then
        log_error "No packages specified for removal"
        return 1
    fi

    log_info "Removing packages: ${packages[*]}"

    if ! sudo dnf remove -y "${packages[@]}"; then
        log_warn "Failed to remove some packages (may not exist)"
        return 0
    fi

    log_success "Packages removed"
    return 0
}

dnf_clean() {
    log_info "Cleaning DNF cache..."
    sudo dnf clean all
    log_success "DNF cache cleaned"
}

################################################################################
# REPOSITORY MANAGEMENT
################################################################################

add_repository() {
    local repo_type="$1"
    local repo_name="$2"
    local fedora_version="${FEDORA_VERSION:-$(grep -oP '(?<=VERSION_ID=)\d+' /etc/os-release)}"

    case "$repo_type" in
        "copr")
            log_info "Adding COPR repository: $repo_name"
            sudo dnf copr enable -y "$repo_name" || return 1
            log_success "COPR repository added: $repo_name"
            ;;
        "rpmfusion-free")
            log_info "Adding RPM Fusion Free repository"
            sudo dnf install -y "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${fedora_version}.noarch.rpm" || return 1
            log_success "RPM Fusion Free repository added"
            ;;
        "rpmfusion-nonfree")
            log_info "Adding RPM Fusion Non-Free repository"
            sudo dnf install -y "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${fedora_version}.noarch.rpm" || return 1
            log_success "RPM Fusion Non-Free repository added"
            ;;
        "flatpak")
            log_info "Adding Flatpak repository: $repo_name"
            flatpak remote-add --if-not-exists "$repo_name" "https://flathub.org/repo/flathub.flatpakrepo" || return 1
            log_success "Flatpak repository added: $repo_name"
            ;;
        *)
            log_error "Unknown repository type: $repo_type"
            return 1
            ;;
    esac

    return 0
}

################################################################################
# SYSTEM DETECTION
################################################################################

detect_fedora_version() {
    local version
    version=$(grep -oP '(?<=VERSION_ID=)\d+' /etc/os-release)

    if [ -z "$version" ]; then
        log_error "Cannot detect Fedora version"
        return 1
    fi

    echo "$version"
}

detect_gpu() {
    local gpu_type="unknown"

    if lspci 2>/dev/null | grep -qi "Intel"; then
        gpu_type="intel"
    elif lspci 2>/dev/null | grep -qi "AMD"; then
        gpu_type="amd"
    elif lspci 2>/dev/null | grep -qi "NVIDIA"; then
        gpu_type="nvidia"
    fi

    echo "$gpu_type"
}

is_virtual_machine() {
    systemd-detect-virt &>/dev/null && return 0 || return 1
}

################################################################################
# BTRFS UTILITIES
################################################################################

validate_btrfs_structure() {
    local required_subvols=("@" "@home")

    log_info "Validating BTRFS structure..."

    if ! btrfs subvolume list / >/dev/null 2>&1; then
        log_error "Root is not BTRFS or not mounted correctly"
        return 1
    fi

    for subvol in "${required_subvols[@]}"; do
        if ! btrfs subvolume show "/$subvol" >/dev/null 2>&1; then
            log_error "Required subvolume /$subvol not found"
            return 1
        fi
    done

    log_success "BTRFS structure validated"
    return 0
}

get_btrfs_uuid() {
    btrfs filesystem show / 2>/dev/null | grep -oP '(?<=uuid: )[a-f0-9\-]+' | head -1
}

################################################################################
# FILE OPERATIONS
################################################################################

create_backup() {
    local file="$1"
    local backup_dir="${2:-.}"

    if [ ! -f "$file" ]; then
        log_warn "File does not exist: $file"
        return 1
    fi

    local backup_file="${backup_dir}/$(basename "$file").backup.$(date +%Y%m%d_%H%M%S)"
    cp "$file" "$backup_file"
    log_success "Backup created: $backup_file"
    echo "$backup_file"
}

safe_symlink() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        log_error "Source does not exist: $source"
        return 1
    fi

    if [ -e "$target" ]; then
        if [ -L "$target" ]; then
            rm "$target"
        else
            create_backup "$target" "$LOG_DIR"
        fi
    fi

    mkdir -p "$(dirname "$target")"
    ln -s "$source" "$target"
    log_success "Symlink created: $target -> $source"
}

################################################################################
# INSTALLATION BATCHES
################################################################################

install_apps_batch() {
    local batch_name="$1"
    shift
    local -a apps=("$@")

    if [ ${#apps[@]} -eq 0 ]; then
        log_warn "No apps to install for batch: $batch_name"
        return 0
    fi

    log_info "Installing $batch_name (${#apps[@]} apps)"

    local failed_apps=()
    for app in "${apps[@]}"; do
        if ! dnf search "$app" -q &>/dev/null 2>&1; then
            failed_apps+=("$app")
            log_warn "App not found in repos: $app"
        fi
    done

    if ! dnf_install "${apps[@]}" 2>/dev/null; then
        log_warn "Some apps failed to install in batch: $batch_name"
    fi

    log_success "Batch $batch_name completed"
    return 0
}

################################################################################
# FLATPAK UTILITIES
################################################################################

install_flatpaks() {
    local -a flatpaks=("$@")

    if [ ${#flatpaks[@]} -eq 0 ]; then
        log_warn "No Flatpak apps to install"
        return 0
    fi

    if ! check_command flatpak; then
        log_error "Flatpak not installed"
        return 1
    fi

    if ! flatpak remote-list | grep -q flathub; then
        log_info "Adding Flathub remote..."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    fi

    log_info "Installing ${#flatpaks[@]} Flatpak applications"

    for flatpak_app in "${flatpaks[@]}"; do
        log_info "  Installing Flatpak: $flatpak_app"
        if ! flatpak install -y flathub "$flatpak_app" 2>/dev/null; then
            log_warn "Failed to install Flatpak: $flatpak_app"
        fi
    done

    log_success "Flatpak installation completed"
    return 0
}

################################################################################
# VS CODE UTILITIES
################################################################################

install_vscode_extensions() {
    local -a extensions=("$@")

    if [ ${#extensions[@]} -eq 0 ]; then
        log_warn "No VS Code extensions to install"
        return 0
    fi

    if ! check_command code; then
        log_error "VS Code not installed"
        return 1
    fi

    log_info "Installing ${#extensions[@]} VS Code extensions"

    for ext in "${extensions[@]}"; do
        log_info "  Installing extension: $ext"
        if ! code --install-extension "$ext" --force &>/dev/null; then
            log_warn "Failed to install extension (may already exist): $ext"
        fi
    done

    log_success "VS Code extensions installation completed"
    log_info "Installed extensions:"
    code --list-extensions | sed 's/^/    /'

    return 0
}

################################################################################
# FIREWALL UTILITIES
################################################################################

firewall_allow_service() {
    local service="$1"

    if ! check_command firewall-cmd; then
        log_error "Firewall not available"
        return 1
    fi

    log_info "Allowing firewall service: $service"
    sudo firewall-cmd --permanent --add-service="$service" || return 1
    sudo firewall-cmd --reload
    log_success "Firewall service allowed: $service"
}

firewall_allow_port() {
    local port="$1"
    local protocol="${2:-tcp}"

    if ! check_command firewall-cmd; then
        log_error "Firewall not available"
        return 1
    fi

    log_info "Allowing firewall port: $port/$protocol"
    sudo firewall-cmd --permanent --add-port="$port/$protocol" || return 1
    sudo firewall-cmd --reload
    log_success "Firewall port allowed: $port/$protocol"
}

################################################################################
# SYSTEM CONFIGURATION
################################################################################

ensure_sudo_nopass() {
    local username="$1"

    if sudo -l "$username" 2>/dev/null | grep -q "(ALL) NOPASSWD: ALL"; then
        log_success "User $username already has passwordless sudo"
        return 0
    fi

    log_info "Configuring passwordless sudo for $username"
    echo "$username ALL=(ALL) NOPASSWD: ALL" | sudo tee "/etc/sudoers.d/$username" > /dev/null
    sudo chmod 0440 "/etc/sudoers.d/$username"
    log_success "Passwordless sudo configured for $username"
}

################################################################################
# END OF FILE
################################################################################
