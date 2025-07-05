#!/bin/bash

# ShadowTrace Sentinel Validation Script
# Validates installation and configuration

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$HOME/.honeypot/config"
LOG_FILE="$HOME/.honeypot/logs/validation.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Validation counters
VALIDATIONS_PASSED=0
VALIDATIONS_FAILED=0
TOTAL_VALIDATIONS=0

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

# Record validation result
record_validation() {
    local check_name="$1"
    local result="$2"
    local details="$3"
    
    ((TOTAL_VALIDATIONS++))
    
    if [[ "$result" == "PASS" ]]; then
        ((VALIDATIONS_PASSED++))
        print_status "$GREEN" "✓ $check_name"
        log "INFO" "VALIDATION PASS: $check_name - $details"
    else
        ((VALIDATIONS_FAILED++))
        print_status "$RED" "✗ $check_name"
        log "ERROR" "VALIDATION FAIL: $check_name - $details"
    fi
}

# Validate directory structure
validate_directory_structure() {
    print_status "$BLUE" "\nValidating Directory Structure"
    print_status "$BLUE" "==============================="
    
    local required_dirs=(
        "$HOME/.honeypot"
        "$HOME/.honeypot/config"
        "$HOME/.honeypot/logs"
        "$HOME/.honeypot/keys"
    )
    
    for dir in "${required_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            record_validation "Directory $(basename "$dir") exists" "PASS" "Found at $dir"
        else
            record_validation "Directory $(basename "$dir") exists" "FAIL" "Not found at $dir"
        fi
    done
}

# Validate configuration files
validate_configuration_files() {
    print_status "$BLUE" "\nValidating Configuration Files"
    print_status "$BLUE" "=============================="
    
    local required_configs=(
        "sentinel.conf:Main configuration"
        "alerts.conf:Alert configuration"
        "logging.conf:Logging configuration"
    )
    
    for config_entry in "${required_configs[@]}"; do
        local config_file=$(echo "$config_entry" | cut -d: -f1)
        local description=$(echo "$config_entry" | cut -d: -f2)
        local config_path="$CONFIG_DIR/$config_file"
        
        if [[ -f "$config_path" ]]; then
            if [[ -r "$config_path" ]]; then
                record_validation "$description readable" "PASS" "File exists and readable"
            else
                record_validation "$description readable" "FAIL" "File exists but not readable"
            fi
        else
            record_validation "$description exists" "FAIL" "File not found: $config_path"
        fi
    done
}

# Validate configuration syntax
validate_configuration_syntax() {
    print_status "$BLUE" "\nValidating Configuration Syntax"
    print_status "$BLUE" "==============================="
    
    local main_config="$CONFIG_DIR/sentinel.conf"
    
    if [[ -f "$main_config" ]]; then
        # Check for basic configuration syntax
        local syntax_errors=()
        
        # Check for required sections
        if ! grep -q "^\[general\]" "$main_config"; then
            syntax_errors+=("Missing [general] section")
        fi
        
        if ! grep -q "^\[monitoring\]" "$main_config"; then
            syntax_errors+=("Missing [monitoring] section")
        fi
        
        # Check for basic settings
        if ! grep -q "honeypot_id" "$main_config"; then
            syntax_errors+=("Missing honeypot_id setting")
        fi
        
        # Check for invalid characters in config
        if grep -q "[^[:print:][:space:]]" "$main_config"; then
            syntax_errors+=("Contains non-printable characters")
        fi
        
        if [[ ${#syntax_errors[@]} -eq 0 ]]; then
            record_validation "Configuration syntax" "PASS" "No syntax errors found"
        else
            record_validation "Configuration syntax" "FAIL" "Errors: ${syntax_errors[*]}"
        fi
    else
        record_validation "Configuration syntax" "FAIL" "Main configuration file not found"
    fi
}

# Validate system dependencies
validate_system_dependencies() {
    print_status "$BLUE" "\nValidating System Dependencies"
    print_status "$BLUE" "=============================="
    
    local required_commands=(
        "python3:Python 3 interpreter"
        "curl:HTTP client"
        "grep:Text search"
        "awk:Text processing"
        "sed:Stream editor"
        "tar:Archive utility"
    )
    
    for cmd_entry in "${required_commands[@]}"; do
        local cmd=$(echo "$cmd_entry" | cut -d: -f1)
        local description=$(echo "$cmd_entry" | cut -d: -f2)
        
        if command -v "$cmd" >/dev/null 2>&1; then
            local version
            case "$cmd" in
                "python3")
                    version=$(python3 --version 2>&1 | awk '{print $2}')
                    ;;
                "curl")
                    version=$(curl --version 2>&1 | head -1 | awk '{print $2}')
                    ;;
                *)
                    version="available"
                    ;;
            esac
            record_validation "$description available" "PASS" "Version: $version"
        else
            record_validation "$description available" "FAIL" "Command not found: $cmd"
        fi
    done
}

# Validate Python dependencies
validate_python_dependencies() {
    print_status "$BLUE" "\nValidating Python Dependencies"
    print_status "$BLUE" "=============================="
    
    local required_modules=(
        "cryptography:Encryption support"
        "requests:HTTP requests"
        "psutil:System utilities"
        "watchdog:File monitoring"
        "yaml:YAML parsing"
    )
    
    for module_entry in "${required_modules[@]}"; do
        local module=$(echo "$module_entry" | cut -d: -f1)
        local description=$(echo "$module_entry" | cut -d: -f2)
        
        if python3 -c "import $module" 2>/dev/null; then
            local version
            version=$(python3 -c "import $module; print(getattr($module, '__version__', 'unknown'))" 2>/dev/null || echo "unknown")
            record_validation "$description module" "PASS" "Version: $version"
        else
            record_validation "$description module" "FAIL" "Module not found: $module"
        fi
    done
}

# Validate network configuration
validate_network_configuration() {
    print_status "$BLUE" "\nValidating Network Configuration"
    print_status "$BLUE" "================================"
    
    # Check if localhost is reachable
    if ping -c 1 127.0.0.1 >/dev/null 2>&1; then
        record_validation "Localhost connectivity" "PASS" "Can ping 127.0.0.1"
    else
        record_validation "Localhost connectivity" "FAIL" "Cannot ping localhost"
    fi
    
    # Check for network interfaces
    local interface_count
    case "$(uname)" in
        "Linux")
            interface_count=$(ip link show | grep -c "^[0-9]")
            ;;
        "Darwin")
            interface_count=$(ifconfig | grep -c "^[a-z]")
            ;;
        *)
            interface_count=1
            ;;
    esac
    
    if [[ "$interface_count" -gt 0 ]]; then
        record_validation "Network interfaces available" "PASS" "Found $interface_count interfaces"
    else
        record_validation "Network interfaces available" "FAIL" "No network interfaces found"
    fi
    
    # Check DNS resolution
    if nslookup github.com >/dev/null 2>&1 || dig github.com >/dev/null 2>&1; then
        record_validation "DNS resolution" "PASS" "Can resolve external domains"
    else
        record_validation "DNS resolution" "FAIL" "Cannot resolve external domains"
    fi
}

# Validate security settings
validate_security_settings() {
    print_status "$BLUE" "\nValidating Security Settings"
    print_status "$BLUE" "============================"
    
    # Check file permissions
    local secure_dirs=("$CONFIG_DIR" "$HOME/.honeypot/keys" "$HOME/.honeypot/logs")
    
    for dir in "${secure_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local perms
            case "$(uname)" in
                "Linux")
                    perms=$(stat -c "%a" "$dir")
                    ;;
                "Darwin")
                    perms=$(stat -f "%A" "$dir")
                    ;;
            esac
            
            # Check if directory is not world-writable
            if [[ "${perms: -1}" -le 5 ]]; then
                record_validation "$(basename "$dir") permissions secure" "PASS" "Permissions: $perms"
            else
                record_validation "$(basename "$dir") permissions secure" "FAIL" "Too permissive: $perms"
            fi
        else
            record_validation "$(basename "$dir") permissions secure" "FAIL" "Directory not found"
        fi
    done
    
    # Check encryption capabilities
    case "$(uname)" in
        "Linux")
            if command -v gpg >/dev/null 2>&1; then
                record_validation "GPG encryption available" "PASS" "GPG command found"
            else
                record_validation "GPG encryption available" "FAIL" "GPG not installed"
            fi
            ;;
        "Darwin")
            if command -v security >/dev/null 2>&1; then
                record_validation "Keychain encryption available" "PASS" "Security command found"
            else
                record_validation "Keychain encryption available" "FAIL" "Security command not found"
            fi
            ;;
        "Windows"|"MINGW"*|"CYGWIN"*)
            # Windows DPAPI is built-in, so always available
            record_validation "DPAPI encryption available" "PASS" "Windows DPAPI built-in"
            ;;
    esac
}

# Validate service installation
validate_service_installation() {
    print_status "$BLUE" "\nValidating Service Installation"
    print_status "$BLUE" "==============================="
    
    case "$(uname)" in
        "Linux")
            if systemctl list-unit-files | grep -q "shadowtrace-sentinel"; then
                record_validation "Systemd service installed" "PASS" "Service unit found"
                
                if systemctl is-enabled shadowtrace-sentinel >/dev/null 2>&1; then
                    record_validation "Service enabled" "PASS" "Service enabled for startup"
                else
                    record_validation "Service enabled" "FAIL" "Service not enabled"
                fi
            else
                record_validation "Systemd service installed" "FAIL" "Service unit not found"
            fi
            ;;
        "Darwin")
            if [[ -f "/Library/LaunchDaemons/com.shadowtrace.sentinel.plist" ]]; then
                record_validation "LaunchDaemon installed" "PASS" "Plist file found"
            else
                record_validation "LaunchDaemon installed" "FAIL" "Plist file not found"
            fi
            ;;
        *)
            record_validation "Service installation" "SKIP" "Platform-specific validation not implemented"
            ;;
    esac
}

# Validate log files
validate_log_files() {
    print_status "$BLUE" "\nValidating Log Files"
    print_status "$BLUE" "===================="
    
    local log_dir="$HOME/.honeypot/logs"
    
    if [[ -d "$log_dir" ]]; then
        if [[ -w "$log_dir" ]]; then
            record_validation "Log directory writable" "PASS" "Can write to log directory"
        else
            record_validation "Log directory writable" "FAIL" "Cannot write to log directory"
        fi
        
        # Check if we can create a test log file
        local test_log="$log_dir/validation_test.log"
        if echo "Test log entry" > "$test_log" 2>/dev/null; then
            record_validation "Log file creation" "PASS" "Can create log files"
            rm -f "$test_log"
        else
            record_validation "Log file creation" "FAIL" "Cannot create log files"
        fi
    else
        record_validation "Log directory exists" "FAIL" "Log directory not found"
    fi
}

# Validate installation completeness
validate_installation_completeness() {
    print_status "$BLUE" "\nValidating Installation Completeness"
    print_status "$BLUE" "===================================="
    
    local required_scripts=(
        "scripts/status.sh:Status script"
        "scripts/cleanup.sh:Cleanup script"
        "scripts/update.sh:Update script"
        "scripts/test.sh:Test script"
    )
    
    for script_entry in "${required_scripts[@]}"; do
        local script_path=$(echo "$script_entry" | cut -d: -f1)
        local description=$(echo "$script_entry" | cut -d: -f2)
        local full_path="$PROJECT_DIR/$script_path"
        
        if [[ -f "$full_path" ]]; then
            if [[ -x "$full_path" ]]; then
                record_validation "$description executable" "PASS" "Script is executable"
            else
                record_validation "$description executable" "FAIL" "Script not executable"
            fi
        else
            record_validation "$description exists" "FAIL" "Script not found: $full_path"
        fi
    done
    
    # Check for platform-specific installers
    case "$(uname)" in
        "Linux")
            if [[ -f "$PROJECT_DIR/linux/ShadowTrace Sentinel Server - Ubuntu.Debian.sh" ]]; then
                record_validation "Linux installer present" "PASS" "Ubuntu/Debian installer found"
            else
                record_validation "Linux installer present" "FAIL" "Linux installer not found"
            fi
            ;;
        "Darwin")
            if [[ -f "$PROJECT_DIR/macos/ShadowTrace Sentinel Server - macOS.sh" ]]; then
                record_validation "macOS installer present" "PASS" "macOS installer found"
            else
                record_validation "macOS installer present" "FAIL" "macOS installer not found"
            fi
            ;;
    esac
}

# Generate validation report
generate_validation_report() {
    local report_file="$HOME/.honeypot/logs/validation-report-$(date +%Y%m%d-%H%M%S).txt"
    local success_rate=$((VALIDATIONS_PASSED * 100 / TOTAL_VALIDATIONS))
    
    cat > "$report_file" << EOF
ShadowTrace Sentinel Installation Validation Report
===================================================

Validation Date: $(date)
System: $(hostname) ($(uname -s) $(uname -r))
User: $(whoami)

Validation Summary:
- Total Validations: $TOTAL_VALIDATIONS
- Passed: $VALIDATIONS_PASSED
- Failed: $VALIDATIONS_FAILED
- Success Rate: $success_rate%

$(if [[ $VALIDATIONS_FAILED -eq 0 ]]; then
    echo "✅ INSTALLATION VALIDATED SUCCESSFULLY"
    echo "All validation checks passed. The ShadowTrace Sentinel installation"
    echo "appears to be complete and properly configured."
else
    echo "⚠️  INSTALLATION VALIDATION ISSUES DETECTED"
    echo "Some validation checks failed. Review the detailed log for specific"
    echo "issues that need to be addressed."
fi)

System Information:
- Operating System: $(uname -s)
- Architecture: $(uname -m)
- Kernel Version: $(uname -r)
- Python Version: $(python3 --version 2>&1 | awk '{print $2}' || echo "Not available")
- Shell: $SHELL

Configuration Paths:
- Project Directory: $PROJECT_DIR
- Configuration Directory: $CONFIG_DIR
- Log Directory: $HOME/.honeypot/logs

Detailed validation results can be found in: $LOG_FILE

EOF
    
    print_status "$BLUE" "Validation report generated: $report_file"
}

# Show usage information
usage() {
    cat << EOF
ShadowTrace Sentinel Validation Script

Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -q, --quiet             Suppress output (exit code only)
    -r, --report            Generate detailed validation report
    -f, --fix               Attempt to fix common issues (coming soon)

Examples:
    $0                      # Run full validation
    $0 --quiet              # Silent validation for scripts
    $0 --report             # Generate detailed report

Exit Codes:
    0    All validations passed
    >0   Number of failed validations

EOF
}

# Main function
main() {
    local quiet_mode=false
    local generate_report=false
    local fix_issues=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -q|--quiet)
                quiet_mode=true
                shift
                ;;
            -r|--report)
                generate_report=true
                shift
                ;;
            -f|--fix)
                fix_issues=true
                shift
                ;;
            *)
                print_status "$RED" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    if [[ "$quiet_mode" != true ]]; then
        print_status "$BLUE" "ShadowTrace Sentinel Installation Validator"
        print_status "$BLUE" "==========================================="
    fi
    
    # Create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    log "INFO" "Starting installation validation"
    
    # Run validation checks
    validate_directory_structure
    validate_configuration_files
    validate_configuration_syntax
    validate_system_dependencies
    validate_python_dependencies
    validate_network_configuration
    validate_security_settings
    validate_service_installation
    validate_log_files
    validate_installation_completeness
    
    # Display results
    if [[ "$quiet_mode" != true ]]; then
        echo
        print_status "$BLUE" "Validation Results:"
        print_status "$BLUE" "==================="
        
        if [[ $VALIDATIONS_FAILED -eq 0 ]]; then
            print_status "$GREEN" "✅ All validations passed ($VALIDATIONS_PASSED/$TOTAL_VALIDATIONS)"
            print_status "$GREEN" "Installation appears to be complete and properly configured."
        else
            print_status "$RED" "❌ Some validations failed ($VALIDATIONS_FAILED/$TOTAL_VALIDATIONS)"
            print_status "$YELLOW" "Success rate: $((VALIDATIONS_PASSED * 100 / TOTAL_VALIDATIONS))%"
            print_status "$YELLOW" "Review the log file for details: $LOG_FILE"
        fi
    fi
    
    # Generate report if requested
    if [[ "$generate_report" == true ]]; then
        generate_validation_report
    fi
    
    log "INFO" "Installation validation completed - Passed: $VALIDATIONS_PASSED, Failed: $VALIDATIONS_FAILED"
    
    # Exit with failure count
    exit $VALIDATIONS_FAILED
}

# Run main function
main "$@"
