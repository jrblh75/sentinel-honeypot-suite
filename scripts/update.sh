#!/bin/bash

# ShadowTrace Sentinel Update Script
# Updates honeypot system and components

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$HOME/.honeypot/config"
LOG_FILE="$HOME/.honeypot/logs/update.log"
BACKUP_DIR="$HOME/.honeypot/backups"
GITHUB_REPO="jrblh75/sentinel-honeypot-suite"
CURRENT_VERSION="1.0"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Print colored output
print_status() {
    local color="$1"
    shift
    local message="$*"
    echo -e "${color}${message}${NC}"
}

# Check if running as root/admin when required
check_privileges() {
    if [[ $EUID -eq 0 ]]; then
        log "INFO" "Running with root privileges"
    else
        case "$(uname)" in
            "Darwin")
                if ! groups | grep -q admin; then
                    print_status "$RED" "Error: This script requires admin privileges on macOS"
                    exit 1
                fi
                ;;
            "Linux")
                print_status "$YELLOW" "Warning: Some operations may require sudo privileges"
                ;;
        esac
    fi
}

# Create necessary directories
setup_directories() {
    log "INFO" "Setting up directories"
    mkdir -p "$HOME/.honeypot/"{config,logs,backups,keys,signatures}
    mkdir -p "$BACKUP_DIR/$(date '+%Y-%m-%d')"
}

# Backup current configuration
backup_config() {
    log "INFO" "Creating configuration backup"
    local backup_file="$BACKUP_DIR/$(date '+%Y-%m-%d')/config-backup-$(date '+%H%M%S').tar.gz"
    
    if [[ -d "$CONFIG_DIR" ]]; then
        tar -czf "$backup_file" -C "$HOME/.honeypot" config/ 2>/dev/null || {
            log "ERROR" "Failed to create configuration backup"
            return 1
        }
        log "INFO" "Configuration backed up to: $backup_file"
    else
        log "WARN" "No configuration directory found to backup"
    fi
}

# Check current version
get_current_version() {
    if [[ -f "$PROJECT_DIR/VERSION" ]]; then
        cat "$PROJECT_DIR/VERSION"
    elif [[ -f "$CONFIG_DIR/version" ]]; then
        cat "$CONFIG_DIR/version"
    else
        echo "$CURRENT_VERSION"
    fi
}

# Check for available updates
check_updates() {
    log "INFO" "Checking for updates"
    
    # Check GitHub releases
    local latest_release
    latest_release=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | \
                    grep '"tag_name":' | \
                    sed -E 's/.*"([^"]+)".*/\1/' | \
                    sed 's/^v//')
    
    if [[ -z "$latest_release" ]]; then
        log "ERROR" "Unable to check for updates"
        return 1
    fi
    
    local current_version
    current_version=$(get_current_version)
    
    print_status "$BLUE" "Current version: $current_version"
    print_status "$BLUE" "Latest version:  $latest_release"
    
    if [[ "$current_version" != "$latest_release" ]]; then
        print_status "$GREEN" "Update available: $current_version -> $latest_release"
        echo "$latest_release"
        return 0
    else
        print_status "$GREEN" "System is up to date"
        return 1
    fi
}

# Download and verify update
download_update() {
    local version="$1"
    local download_dir="$BACKUP_DIR/$(date '+%Y-%m-%d')/update-$version"
    
    log "INFO" "Downloading update version $version"
    mkdir -p "$download_dir"
    
    # Download release archive
    local download_url="https://github.com/$GITHUB_REPO/archive/refs/tags/v$version.tar.gz"
    local archive_file="$download_dir/sentinel-$version.tar.gz"
    
    if ! curl -L -o "$archive_file" "$download_url"; then
        log "ERROR" "Failed to download update"
        return 1
    fi
    
    # Verify download
    if [[ ! -f "$archive_file" ]] || [[ ! -s "$archive_file" ]]; then
        log "ERROR" "Downloaded file is invalid"
        return 1
    fi
    
    # Extract archive
    if ! tar -xzf "$archive_file" -C "$download_dir"; then
        log "ERROR" "Failed to extract update archive"
        return 1
    fi
    
    log "INFO" "Update downloaded and extracted to: $download_dir"
    echo "$download_dir"
}

# Update signatures and rules
update_signatures() {
    log "INFO" "Updating detection signatures"
    
    local signatures_dir="$HOME/.honeypot/signatures"
    mkdir -p "$signatures_dir"
    
    # Download signature updates from GitHub
    local signatures_url="https://raw.githubusercontent.com/$GITHUB_REPO/main/signatures"
    
    for sig_file in "common-attacks.yml" "malware-signatures.yml" "behavioral-patterns.yml"; do
        if curl -s "$signatures_url/$sig_file" -o "$signatures_dir/$sig_file.new"; then
            if [[ -s "$signatures_dir/$sig_file.new" ]]; then
                mv "$signatures_dir/$sig_file.new" "$signatures_dir/$sig_file"
                log "INFO" "Updated signature file: $sig_file"
            else
                rm -f "$signatures_dir/$sig_file.new"
                log "WARN" "Failed to download signature file: $sig_file"
            fi
        fi
    done
}

# Update threat intelligence feeds
update_threat_intel() {
    log "INFO" "Updating threat intelligence feeds"
    
    local intel_dir="$HOME/.honeypot/threat-intel"
    mkdir -p "$intel_dir"
    
    # Download threat intelligence feeds
    local feeds=(
        "https://rules.emergingthreats.net/open/suricata/rules/emerging-malware.rules"
        "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset"
    )
    
    for feed_url in "${feeds[@]}"; do
        local filename=$(basename "$feed_url")
        if curl -s "$feed_url" -o "$intel_dir/$filename.new"; then
            if [[ -s "$intel_dir/$filename.new" ]]; then
                mv "$intel_dir/$filename.new" "$intel_dir/$filename"
                log "INFO" "Updated threat intel: $filename"
            else
                rm -f "$intel_dir/$filename.new"
                log "WARN" "Failed to download threat intel: $filename"
            fi
        fi
    done
}

# Update system packages (if needed)
update_system_packages() {
    log "INFO" "Checking system package updates"
    
    case "$(uname)" in
        "Linux")
            if command -v apt-get > /dev/null; then
                log "INFO" "Updating system packages (apt)"
                sudo apt-get update -qq
                sudo apt-get upgrade -y python3-pip curl gnupg
            elif command -v yum > /dev/null; then
                log "INFO" "Updating system packages (yum)"
                sudo yum update -y python3-pip curl gnupg2
            fi
            ;;
        "Darwin")
            if command -v brew > /dev/null; then
                log "INFO" "Updating Homebrew packages"
                brew update
                brew upgrade python3 curl gnupg
            fi
            ;;
    esac
}

# Update Python dependencies
update_python_deps() {
    log "INFO" "Updating Python dependencies"
    
    # Update pip itself
    python3 -m pip install --upgrade pip
    
    # Update required packages
    local packages=(
        "cryptography"
        "requests"
        "psutil"
        "watchdog"
        "pyyaml"
    )
    
    for package in "${packages[@]}"; do
        if python3 -m pip install --upgrade "$package"; then
            log "INFO" "Updated Python package: $package"
        else
            log "WARN" "Failed to update Python package: $package"
        fi
    done
}

# Apply configuration updates
apply_config_updates() {
    local update_dir="$1"
    
    log "INFO" "Applying configuration updates"
    
    # Look for configuration updates in the downloaded update
    local new_config_dir="$update_dir/sentinel-honeypot-suite-*/config"
    
    if [[ -d "$new_config_dir" ]]; then
        # Copy new configuration templates
        cp -r "$new_config_dir"/* "$CONFIG_DIR/" 2>/dev/null || true
        log "INFO" "Configuration templates updated"
    fi
    
    # Update version file
    echo "$(basename "$update_dir" | sed 's/update-//')" > "$CONFIG_DIR/version"
}

# Restart services
restart_services() {
    log "INFO" "Restarting ShadowTrace Sentinel services"
    
    case "$(uname)" in
        "Linux")
            if systemctl is-active --quiet shadowtrace-sentinel; then
                sudo systemctl restart shadowtrace-sentinel
                log "INFO" "Systemd service restarted"
            fi
            ;;
        "Darwin")
            if launchctl list | grep -q com.shadowtrace.sentinel; then
                sudo launchctl unload /Library/LaunchDaemons/com.shadowtrace.sentinel.plist
                sudo launchctl load /Library/LaunchDaemons/com.shadowtrace.sentinel.plist
                log "INFO" "LaunchDaemon restarted"
            fi
            ;;
    esac
}

# Verify update success
verify_update() {
    log "INFO" "Verifying update"
    
    # Check if service is running
    if "$SCRIPT_DIR/status.sh" --quiet; then
        log "INFO" "Update verification successful"
        return 0
    else
        log "ERROR" "Update verification failed"
        return 1
    fi
}

# Rollback update
rollback_update() {
    log "WARN" "Rolling back update"
    
    # Find latest backup
    local latest_backup
    latest_backup=$(find "$BACKUP_DIR" -name "config-backup-*.tar.gz" -type f -printf '%T@ %p\n' | sort -n | tail -1 | cut -d' ' -f2-)
    
    if [[ -n "$latest_backup" ]] && [[ -f "$latest_backup" ]]; then
        log "INFO" "Restoring configuration from: $latest_backup"
        tar -xzf "$latest_backup" -C "$HOME/.honeypot/"
        restart_services
        log "INFO" "Rollback completed"
    else
        log "ERROR" "No backup found for rollback"
        return 1
    fi
}

# Show usage information
usage() {
    cat << EOF
ShadowTrace Sentinel Update Script

Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -c, --check             Check for updates only
    -f, --force             Force update even if up to date
    -s, --signatures        Update signatures only
    -t, --threat-intel      Update threat intelligence only
    -p, --packages          Update system packages only
    --no-backup             Skip configuration backup
    --no-restart            Skip service restart
    --rollback              Rollback to previous version

Examples:
    $0                      # Full update check and install
    $0 --check              # Check for updates only
    $0 --signatures         # Update signatures only
    $0 --rollback           # Rollback to previous version

EOF
}

# Main function
main() {
    local check_only=false
    local force_update=false
    local signatures_only=false
    local threat_intel_only=false
    local packages_only=false
    local no_backup=false
    local no_restart=false
    local rollback=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -c|--check)
                check_only=true
                shift
                ;;
            -f|--force)
                force_update=true
                shift
                ;;
            -s|--signatures)
                signatures_only=true
                shift
                ;;
            -t|--threat-intel)
                threat_intel_only=true
                shift
                ;;
            -p|--packages)
                packages_only=true
                shift
                ;;
            --no-backup)
                no_backup=true
                shift
                ;;
            --no-restart)
                no_restart=true
                shift
                ;;
            --rollback)
                rollback=true
                shift
                ;;
            *)
                print_status "$RED" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    print_status "$BLUE" "ShadowTrace Sentinel Update Script"
    print_status "$BLUE" "=================================="
    
    # Create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    log "INFO" "Starting update process"
    
    # Handle rollback
    if [[ "$rollback" == true ]]; then
        rollback_update
        exit $?
    fi
    
    # Setup directories
    setup_directories
    
    # Handle component-specific updates
    if [[ "$signatures_only" == true ]]; then
        update_signatures
        exit $?
    fi
    
    if [[ "$threat_intel_only" == true ]]; then
        update_threat_intel
        exit $?
    fi
    
    if [[ "$packages_only" == true ]]; then
        check_privileges
        update_system_packages
        update_python_deps
        exit $?
    fi
    
    # Check for updates
    if ! latest_version=$(check_updates); then
        if [[ "$force_update" != true ]]; then
            log "INFO" "No updates available"
            exit 0
        else
            latest_version=$(get_current_version)
            log "INFO" "Forcing update to version $latest_version"
        fi
    fi
    
    # Exit if only checking
    if [[ "$check_only" == true ]]; then
        exit 0
    fi
    
    # Backup configuration
    if [[ "$no_backup" != true ]]; then
        backup_config
    fi
    
    # Download update
    if update_dir=$(download_update "$latest_version"); then
        log "INFO" "Update downloaded successfully"
    else
        log "ERROR" "Failed to download update"
        exit 1
    fi
    
    # Apply updates
    update_signatures
    update_threat_intel
    update_python_deps
    apply_config_updates "$update_dir"
    
    # Restart services
    if [[ "$no_restart" != true ]]; then
        restart_services
        sleep 5  # Wait for services to start
    fi
    
    # Verify update
    if verify_update; then
        print_status "$GREEN" "Update completed successfully!"
        log "INFO" "Update to version $latest_version completed successfully"
    else
        print_status "$RED" "Update verification failed"
        if [[ "$no_backup" != true ]]; then
            print_status "$YELLOW" "Attempting rollback..."
            rollback_update
        fi
        exit 1
    fi
}

# Run main function
main "$@"
