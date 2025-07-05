#!/bin/bash

# ShadowTrace Sentinel Test Suite
# Comprehensive testing script for honeypot functionality

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$HOME/.honeypot/config"
LOG_FILE="$HOME/.honeypot/logs/test-suite.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Test categories
declare -A TEST_CATEGORIES=(
    ["config"]="Configuration Tests"
    ["service"]="Service Tests"
    ["network"]="Network Tests"
    ["security"]="Security Tests"
    ["performance"]="Performance Tests"
    ["integration"]="Integration Tests"
)

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

# Record test result
record_test() {
    local category="$1"
    local test_name="$2"
    local result="$3"
    local details="$4"
    
    ((TOTAL_TESTS++))
    
    if [[ "$result" == "PASS" ]]; then
        ((TESTS_PASSED++))
        print_status "$GREEN" "  ✓ $test_name"
        log "INFO" "TEST PASS [$category]: $test_name - $details"
    elif [[ "$result" == "FAIL" ]]; then
        ((TESTS_FAILED++))
        print_status "$RED" "  ✗ $test_name"
        log "ERROR" "TEST FAIL [$category]: $test_name - $details"
    else
        print_status "$YELLOW" "  ~ $test_name (SKIP)"
        log "WARN" "TEST SKIP [$category]: $test_name - $details"
    fi
}

# Configuration Tests
run_config_tests() {
    print_status "$BLUE" "\n${TEST_CATEGORIES["config"]}"
    print_status "$BLUE" "=================="
    
    # Test configuration directory
    if [[ -d "$CONFIG_DIR" ]]; then
        record_test "config" "Configuration directory exists" "PASS" "Found at $CONFIG_DIR"
    else
        record_test "config" "Configuration directory exists" "FAIL" "Not found at $CONFIG_DIR"
    fi
    
    # Test main configuration file
    if [[ -f "$CONFIG_DIR/sentinel.conf" ]]; then
        record_test "config" "Main configuration file exists" "PASS" "sentinel.conf found"
    else
        record_test "config" "Main configuration file exists" "FAIL" "sentinel.conf not found"
    fi
    
    # Test configuration syntax
    if "$SCRIPT_DIR/../scripts/validate-config.sh" 2>/dev/null; then
        record_test "config" "Configuration syntax valid" "PASS" "No syntax errors"
    else
        record_test "config" "Configuration syntax valid" "FAIL" "Syntax errors found"
    fi
    
    # Test permissions
    if [[ -r "$CONFIG_DIR" ]] && [[ -w "$CONFIG_DIR" ]]; then
        record_test "config" "Configuration permissions" "PASS" "Read/write access available"
    else
        record_test "config" "Configuration permissions" "FAIL" "Insufficient permissions"
    fi
}

# Service Tests
run_service_tests() {
    print_status "$BLUE" "\n${TEST_CATEGORIES["service"]}"
    print_status "$BLUE" "=============="
    
    # Test service status
    if "$SCRIPT_DIR/status.sh" --quiet 2>/dev/null; then
        record_test "service" "Service is running" "PASS" "ShadowTrace Sentinel active"
    else
        record_test "service" "Service is running" "FAIL" "Service not responding"
    fi
    
    # Test log files
    local log_dir="$HOME/.honeypot/logs"
    if [[ -d "$log_dir" ]] && [[ -w "$log_dir" ]]; then
        record_test "service" "Log directory accessible" "PASS" "Can write to logs"
    else
        record_test "service" "Log directory accessible" "FAIL" "Cannot access log directory"
    fi
    
    # Test process existence
    if pgrep -f "shadowtrace" >/dev/null 2>&1; then
        record_test "service" "Process running" "PASS" "ShadowTrace process found"
    else
        record_test "service" "Process running" "FAIL" "No ShadowTrace process found"
    fi
    
    # Test service responsiveness
    local start_time=$(date +%s)
    if timeout 5 "$SCRIPT_DIR/status.sh" --health-check 2>/dev/null; then
        local duration=$(($(date +%s) - start_time))
        record_test "service" "Service responsiveness" "PASS" "Response time: ${duration}s"
    else
        record_test "service" "Service responsiveness" "FAIL" "Service not responding to health check"
    fi
}

# Network Tests
run_network_tests() {
    print_status "$BLUE" "\n${TEST_CATEGORIES["network"]}"
    print_status "$BLUE" "=============="
    
    # Test network connectivity
    if ping -c 1 127.0.0.1 >/dev/null 2>&1; then
        record_test "network" "Localhost connectivity" "PASS" "Can ping localhost"
    else
        record_test "network" "Localhost connectivity" "FAIL" "Cannot ping localhost"
    fi
    
    # Test port binding
    local test_ports=(22 80 443)
    for port in "${test_ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            record_test "network" "Port $port binding" "PASS" "Port is bound"
        else
            record_test "network" "Port $port binding" "SKIP" "Port not configured"
        fi
    done
    
    # Test firewall rules
    case "$(uname)" in
        "Linux")
            if command -v iptables >/dev/null 2>&1; then
                if iptables -L >/dev/null 2>&1; then
                    record_test "network" "Firewall accessible" "PASS" "Can access iptables"
                else
                    record_test "network" "Firewall accessible" "FAIL" "Cannot access iptables"
                fi
            else
                record_test "network" "Firewall accessible" "SKIP" "iptables not available"
            fi
            ;;
        "Darwin")
            if command -v pfctl >/dev/null 2>&1; then
                record_test "network" "Firewall accessible" "PASS" "pfctl available"
            else
                record_test "network" "Firewall accessible" "SKIP" "pfctl not available"
            fi
            ;;
    esac
}

# Security Tests
run_security_tests() {
    print_status "$BLUE" "\n${TEST_CATEGORIES["security"]}"
    print_status "$BLUE" "=============="
    
    # Test file permissions
    local secure_files=("$CONFIG_DIR" "$HOME/.honeypot/keys" "$HOME/.honeypot/logs")
    for file_path in "${secure_files[@]}"; do
        if [[ -e "$file_path" ]]; then
            local perms=$(stat -c "%a" "$file_path" 2>/dev/null || stat -f "%A" "$file_path" 2>/dev/null)
            if [[ "${perms: -1}" -le 5 ]]; then
                record_test "security" "File permissions $(basename "$file_path")" "PASS" "Permissions: $perms"
            else
                record_test "security" "File permissions $(basename "$file_path")" "FAIL" "Too permissive: $perms"
            fi
        else
            record_test "security" "File permissions $(basename "$file_path")" "SKIP" "File not found"
        fi
    done
    
    # Test encryption availability
    case "$(uname)" in
        "Linux")
            if command -v gpg >/dev/null 2>&1; then
                record_test "security" "GPG encryption available" "PASS" "GPG found"
            else
                record_test "security" "GPG encryption available" "FAIL" "GPG not found"
            fi
            ;;
        "Darwin")
            if command -v security >/dev/null 2>&1; then
                record_test "security" "Keychain available" "PASS" "Security framework found"
            else
                record_test "security" "Keychain available" "FAIL" "Security framework not found"
            fi
            ;;
    esac
    
    # Test alert system
    if "$SCRIPT_DIR/test-alerts.sh" --config 2>/dev/null; then
        record_test "security" "Alert system configured" "PASS" "Alert configuration valid"
    else
        record_test "security" "Alert system configured" "FAIL" "Alert configuration invalid"
    fi
}

# Performance Tests
run_performance_tests() {
    print_status "$BLUE" "\n${TEST_CATEGORIES["performance"]}"
    print_status "$BLUE" "=================="
    
    # Test CPU usage
    local cpu_usage
    case "$(uname)" in
        "Linux")
            cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
            ;;
        "Darwin")
            cpu_usage=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//')
            ;;
        *)
            cpu_usage="0"
            ;;
    esac
    
    if [[ "${cpu_usage%.*}" -lt 80 ]]; then
        record_test "performance" "CPU usage acceptable" "PASS" "CPU usage: $cpu_usage%"
    else
        record_test "performance" "CPU usage acceptable" "FAIL" "High CPU usage: $cpu_usage%"
    fi
    
    # Test memory usage
    local mem_usage
    case "$(uname)" in
        "Linux")
            mem_usage=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')
            ;;
        "Darwin")
            mem_usage=$(memory_pressure | grep "System-wide memory free percentage" | awk '{print 100-$5}' | sed 's/%//')
            ;;
        *)
            mem_usage="0"
            ;;
    esac
    
    if [[ "${mem_usage%.*}" -lt 90 ]]; then
        record_test "performance" "Memory usage acceptable" "PASS" "Memory usage: $mem_usage%"
    else
        record_test "performance" "Memory usage acceptable" "FAIL" "High memory usage: $mem_usage%"
    fi
    
    # Test disk space
    local disk_usage
    disk_usage=$(df "$HOME" | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [[ "$disk_usage" -lt 90 ]]; then
        record_test "performance" "Disk space acceptable" "PASS" "Disk usage: $disk_usage%"
    else
        record_test "performance" "Disk space acceptable" "FAIL" "Low disk space: $disk_usage%"
    fi
    
    # Test response time
    local start_time=$(date +%s.%N)
    "$SCRIPT_DIR/status.sh" --quiet >/dev/null 2>&1
    local end_time=$(date +%s.%N)
    local response_time=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "1.0")
    
    if (( $(echo "$response_time < 2.0" | bc -l 2>/dev/null || echo 0) )); then
        record_test "performance" "Response time acceptable" "PASS" "Response: ${response_time}s"
    else
        record_test "performance" "Response time acceptable" "FAIL" "Slow response: ${response_time}s"
    fi
}

# Integration Tests
run_integration_tests() {
    print_status "$BLUE" "\n${TEST_CATEGORIES["integration"]}"
    print_status "$BLUE" "=================="
    
    # Test Python dependencies
    local python_deps=("cryptography" "requests" "psutil" "watchdog" "pyyaml")
    for dep in "${python_deps[@]}"; do
        if python3 -c "import $dep" 2>/dev/null; then
            record_test "integration" "Python $dep module" "PASS" "Module available"
        else
            record_test "integration" "Python $dep module" "FAIL" "Module not found"
        fi
    done
    
    # Test system commands
    local system_commands=("curl" "grep" "awk" "sed" "tar")
    for cmd in "${system_commands[@]}"; do
        if command -v "$cmd" >/dev/null 2>&1; then
            record_test "integration" "Command $cmd available" "PASS" "Command found"
        else
            record_test "integration" "Command $cmd available" "FAIL" "Command not found"
        fi
    done
    
    # Test log rotation
    if command -v logrotate >/dev/null 2>&1 || [[ -f "/etc/newsyslog.conf" ]]; then
        record_test "integration" "Log rotation available" "PASS" "Log rotation configured"
    else
        record_test "integration" "Log rotation available" "WARN" "Log rotation not configured"
    fi
    
    # Test cron/scheduling
    if command -v crontab >/dev/null 2>&1; then
        record_test "integration" "Task scheduling available" "PASS" "crontab available"
    else
        record_test "integration" "Task scheduling available" "FAIL" "crontab not available"
    fi
}

# Generate test report
generate_test_report() {
    local report_file="$HOME/.honeypot/logs/test-report-$(date +%Y%m%d-%H%M%S).html"
    local success_rate=$((TESTS_PASSED * 100 / TOTAL_TESTS))
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>ShadowTrace Sentinel Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background: #f0f0f0; padding: 10px; border-radius: 5px; }
        .pass { color: green; }
        .fail { color: red; }
        .skip { color: orange; }
        .summary { background: #e9f4ff; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .category { margin: 20px 0; }
        .test-result { margin: 5px 0; padding: 5px; }
    </style>
</head>
<body>
    <div class="header">
        <h1>ShadowTrace Sentinel Test Report</h1>
        <p><strong>Generated:</strong> $(date)</p>
        <p><strong>System:</strong> $(hostname) ($(uname -s))</p>
        <p><strong>User:</strong> $(whoami)</p>
    </div>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <p><strong>Total Tests:</strong> $TOTAL_TESTS</p>
        <p><strong>Passed:</strong> <span class="pass">$TESTS_PASSED</span></p>
        <p><strong>Failed:</strong> <span class="fail">$TESTS_FAILED</span></p>
        <p><strong>Success Rate:</strong> $success_rate%</p>
    </div>
    
    <div class="category">
        <h2>Test Categories</h2>
        $(for category in "${!TEST_CATEGORIES[@]}"; do
            echo "<h3>${TEST_CATEGORIES[$category]}</h3>"
            grep "TEST.*\[$category\]" "$LOG_FILE" | while IFS= read -r line; do
                if [[ "$line" =~ "PASS" ]]; then
                    echo "<div class='test-result pass'>✓ $(echo "$line" | awk -F': ' '{print $3}')</div>"
                elif [[ "$line" =~ "FAIL" ]]; then
                    echo "<div class='test-result fail'>✗ $(echo "$line" | awk -F': ' '{print $3}')</div>"
                else
                    echo "<div class='test-result skip'>~ $(echo "$line" | awk -F': ' '{print $3}')</div>"
                fi
            done
        done)
    </div>
    
    <div class="footer">
        <p><em>Detailed logs available at: $LOG_FILE</em></p>
    </div>
</body>
</html>
EOF
    
    print_status "$BLUE" "Test report generated: $report_file"
}

# Show usage information
usage() {
    cat << EOF
ShadowTrace Sentinel Test Suite

Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -c, --config            Run configuration tests only
    -s, --service           Run service tests only
    -n, --network           Run network tests only
    -e, --security          Run security tests only
    -p, --performance       Run performance tests only
    -i, --integration       Run integration tests only
    -r, --report            Generate HTML report
    -q, --quiet             Suppress output (exit code only)
    -v, --verbose           Verbose output

Examples:
    $0                      # Run all tests
    $0 --config --service   # Run specific test categories
    $0 --report             # Generate HTML report
    $0 --quiet              # Silent mode for automation

EOF
}

# Main function
main() {
    local run_config=false
    local run_service=false
    local run_network=false
    local run_security=false
    local run_performance=false
    local run_integration=false
    local generate_report=false
    local quiet_mode=false
    local verbose_mode=false
    local run_all=true
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -c|--config)
                run_config=true
                run_all=false
                shift
                ;;
            -s|--service)
                run_service=true
                run_all=false
                shift
                ;;
            -n|--network)
                run_network=true
                run_all=false
                shift
                ;;
            -e|--security)
                run_security=true
                run_all=false
                shift
                ;;
            -p|--performance)
                run_performance=true
                run_all=false
                shift
                ;;
            -i|--integration)
                run_integration=true
                run_all=false
                shift
                ;;
            -r|--report)
                generate_report=true
                shift
                ;;
            -q|--quiet)
                quiet_mode=true
                shift
                ;;
            -v|--verbose)
                verbose_mode=true
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
        print_status "$BLUE" "ShadowTrace Sentinel Test Suite"
        print_status "$BLUE" "==============================="
    fi
    
    # Create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    log "INFO" "Starting test suite"
    
    # Run selected test categories
    if [[ "$run_all" == true ]] || [[ "$run_config" == true ]]; then
        run_config_tests
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_service" == true ]]; then
        run_service_tests
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_network" == true ]]; then
        run_network_tests
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_security" == true ]]; then
        run_security_tests
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_performance" == true ]]; then
        run_performance_tests
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_integration" == true ]]; then
        run_integration_tests
    fi
    
    # Display results
    if [[ "$quiet_mode" != true ]]; then
        echo
        print_status "$BLUE" "Test Results:"
        print_status "$BLUE" "============="
        
        if [[ $TESTS_FAILED -eq 0 ]]; then
            print_status "$GREEN" "✅ All tests passed ($TESTS_PASSED/$TOTAL_TESTS)"
        else
            print_status "$RED" "❌ Some tests failed ($TESTS_FAILED/$TOTAL_TESTS)"
            print_status "$YELLOW" "Success rate: $((TESTS_PASSED * 100 / TOTAL_TESTS))%"
        fi
    fi
    
    # Generate report if requested
    if [[ "$generate_report" == true ]]; then
        generate_test_report
    fi
    
    log "INFO" "Test suite completed - Passed: $TESTS_PASSED, Failed: $TESTS_FAILED"
    
    # Exit with failure code if any tests failed
    exit $TESTS_FAILED
}

# Run main function
main "$@"
