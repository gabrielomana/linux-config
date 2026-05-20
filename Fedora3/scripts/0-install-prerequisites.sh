#!/bin/bash
################################################################################
# FEDORA3 AUTOMATION SUITE - SCRIPT 0: INSTALL PREREQUISITES
# Valida y prepara el entorno antes de ejecutar scripts 1-3
# Author: Claude Code (Especialista Linux/Fedora/Bash)
# License: MIT
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "${SCRIPT_DIR}/sources/helpers/functions.sh"
source "${SCRIPT_DIR}/sources/config/.env"

################################################################################
# TRAP HANDLER
################################################################################

trap 'handle_error ${LINENO} "Script interrupted"' ERR INT TERM

################################################################################
# MAIN SCRIPT
################################################################################

main() {
    log_section "FEDORA3 - SCRIPT 0: INSTALL PREREQUISITES"

    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
        log_info "Execute with: sudo $0"
        exit 1
    fi

    log_info "Fedora Version: $FEDORA_VERSION"
    log_info "GPU Type: $GPU_TYPE"
    log_info "Virtual Machine: $IS_VIRTUAL_MACHINE"

    # Validate Fedora version
    if [ "$FEDORA_VERSION" -lt 38 ]; then
        log_error "Fedora 38+ is required (detected: $FEDORA_VERSION)"
        exit 1
    fi

    # Validate BTRFS
    log_section "BTRFS VALIDATION"
    if ! validate_btrfs_structure; then
        log_error "BTRFS validation failed - ensure Fedora was installed with BTRFS"
        exit 1
    fi

    # Validate filesystem subvolumes
    log_section "FILESYSTEM SUBVOLUME VALIDATION"
    if ! btrfs subvolume show /@ >/dev/null 2>&1; then
        log_error "Required subvolume /@ not found"
        log_info "Ensure Fedora was installed with subvolumes: @ and @home"
        exit 1
    fi
    log_success "Subvolume @ found"

    if ! btrfs subvolume show /@home >/dev/null 2>&1; then
        log_error "Required subvolume /@home not found"
        log_info "Ensure Fedora was installed with subvolumes: @ and @home"
        exit 1
    fi
    log_success "Subvolume @home found"

    # Validate required commands
    log_section "COMMAND VALIDATION"
    local -a required_commands=(
        "sudo"
        "dnf"
        "git"
        "curl"
        "wget"
        "btrfs"
        "firewall-cmd"
        "systemctl"
        "sed"
        "awk"
        "grep"
        "find"
    )

    if ! validate_prerequisites "${required_commands[@]}"; then
        log_error "Some prerequisites are missing"
        exit 1
    fi

    # Validate network connectivity
    log_section "NETWORK VALIDATION"
    if ! curl -s --connect-timeout 5 https://www.google.com >/dev/null 2>&1; then
        log_warn "Network connectivity test failed - this may cause issues"
        log_info "Ensure you have a stable internet connection"
    else
        log_success "Network connectivity verified"
    fi

    # Check disk space
    log_section "DISK SPACE VALIDATION"
    local disk_usage
    disk_usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')

    if [ "$disk_usage" -gt 80 ]; then
        log_warn "Root filesystem is $disk_usage% full - recommend cleanup"
    fi

    local available_gb
    available_gb=$(($(df / | awk 'NR==2 {print $4}') / 1024 / 1024))
    log_info "Available disk space: ${available_gb} GB"

    if [ "$available_gb" -lt 20 ]; then
        log_error "Less than 20GB available - insufficient for full installation"
        exit 1
    fi

    log_success "Disk space validated"

    # Display system information
    log_section "SYSTEM INFORMATION"
    log_info "CPU Cores: $SYSTEM_CPUS"
    log_info "RAM: ${SYSTEM_RAM_MB} MB"
    log_info "GPU: $GPU_TYPE"
    log_info "Virtual Machine: $IS_VIRTUAL_MACHINE"

    # Check systemd
    log_section "SYSTEMD VALIDATION"
    if ! systemctl is-system-running &>/dev/null; then
        log_warn "Systemd is not running"
    else
        log_success "Systemd is running"
    fi

    # Verify logging directory
    log_section "LOGGING SETUP"
    mkdir -p "$LOG_DIR"
    if [ ! -w "$LOG_DIR" ]; then
        log_error "Cannot write to log directory: $LOG_DIR"
        exit 1
    fi
    log_success "Log directory ready: $LOG_DIR"

    # Summary
    log_section "PREREQUISITES VALIDATION COMPLETE"
    log_success "All prerequisites validated successfully!"
    log_info ""
    log_info "Next steps:"
    log_info "1. Review the system information above"
    log_info "2. Run: sudo $SCRIPT_DIR/scripts/1-system-core.sh"
    log_info "3. After reboot, run: sudo $SCRIPT_DIR/scripts/2-kde-minimal-snapshots.sh"
    log_info "4. Finally, run: $SCRIPT_DIR/scripts/3-user-space-apps.sh"
    log_info ""
    log_info "Logs are saved in: $LOG_DIR"
    log_info ""
}

# Execute main function
main "$@"

################################################################################
# END OF FILE
################################################################################
