#!/bin/bash
# ShadowTrace Sentinel Status Checker
# © 2025 Brannon-Lee Hollis Jr.

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HONEYPOT_DIR="$HOME/.honeypot"
LOG_FILE="$HONEYPOT_DIR/logs/sentinel.log"
PID_FILE="$HONEYPOT_DIR/run/sentinel.pid"
CONFIG_FILE="$HONEYPOT_DIR/config/sentinel.conf"

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  ShadowTrace Sentinel Status Check  ${NC}"
echo -e "${BLUE}=====================================${NC}"
echo

# Function to check if honeypot directory exists
check_installation() {
    echo -n "Checking installation... "
    if [ -d "$HONEYPOT_DIR" ]; then
        echo -e "${GREEN}✓ Installed${NC}"
        return 0
    else
        echo -e "${RED}✗ Not installed${NC}"
        return 1
    fi
}

# Function to check service status
check_service_status() {
    echo -n "Checking service status... "
    
    # Check if PID file exists and process is running
    if [ -f "$PID_FILE" ]; then
        local pid=$(cat "$PID_FILE")
        if ps -p "$pid" > /dev/null 2>&1; then
            echo -e "${GREEN}✓ Running (PID: $pid)${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠ PID file exists but process not running${NC}"
            return 1
        fi
    else
        echo -e "${RED}✗ Not running${NC}"
        return 1
    fi
}

# Function to check configuration
check_configuration() {
    echo -n "Checking configuration... "
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${GREEN}✓ Configuration found${NC}"
        
        # Check for critical configuration values
        if grep -q "ALERT_EMAIL" "$CONFIG_FILE" 2>/dev/null; then
            local email=$(grep "ALERT_EMAIL" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '"')
            echo "  Alert email: $email"
        fi
        
        if grep -q "LOG_LEVEL" "$CONFIG_FILE" 2>/dev/null; then
            local log_level=$(grep "LOG_LEVEL" "$CONFIG_FILE" | cut -d'=' -f2 | tr -d '"')
            echo "  Log level: $log_level"
        fi
        
        return 0
    else
        echo -e "${RED}✗ Configuration not found${NC}"
        return 1
    fi
}

# Function to check honeypot traps
check_traps() {
    echo -n "Checking honeypot traps... "
    local trap_count=0
    
    if [ -d "$HONEYPOT_DIR/traps" ]; then
        trap_count=$(find "$HONEYPOT_DIR/traps" -type f | wc -l)
        echo -e "${GREEN}✓ $trap_count traps deployed${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠ No traps directory found${NC}"
        return 1
    fi
}

# Function to check recent activity
check_recent_activity() {
    echo "Checking recent activity..."
    
    if [ -f "$LOG_FILE" ]; then
        echo "  Recent log entries (last 10):"
        tail -n 10 "$LOG_FILE" | while IFS= read -r line; do
            echo "    $line"
        done
        
        # Check for recent alerts
        local alert_count=$(grep -c "ALERT" "$LOG_FILE" 2>/dev/null || echo "0")
        echo "  Total alerts in log: $alert_count"
        
        # Check for recent access attempts
        local access_count=$(grep -c "ACCESS_ATTEMPT" "$LOG_FILE" 2>/dev/null || echo "0")
        echo "  Total access attempts: $access_count"
    else
        echo -e "  ${YELLOW}⚠ No log file found${NC}"
    fi
}

# Function to check disk usage
check_disk_usage() {
    echo -n "Checking disk usage... "
    if [ -d "$HONEYPOT_DIR" ]; then
        local usage=$(du -sh "$HONEYPOT_DIR" | cut -f1)
        echo -e "${GREEN}✓ $usage used${NC}"
        
        # Check if logs are getting large
        if [ -f "$LOG_FILE" ]; then
            local log_size=$(du -sh "$LOG_FILE" | cut -f1)
            echo "  Log file size: $log_size"
        fi
    else
        echo -e "${RED}✗ Directory not found${NC}"
    fi
}

# Function to check network connectivity
check_connectivity() {
    echo -n "Checking network connectivity... "
    if curl -s --max-time 5 https://api.ipify.org > /dev/null 2>&1; then
        local external_ip=$(curl -s --max-time 5 https://api.ipify.org)
        echo -e "${GREEN}✓ Connected (IP: $external_ip)${NC}"
        return 0
    else
        echo -e "${RED}✗ No connectivity${NC}"
        return 1
    fi
}

# Function to check system resources
check_resources() {
    echo "Checking system resources..."
    
    # Memory usage
    local mem_info=$(free -h | grep '^Mem:')
    echo "  Memory: $mem_info"
    
    # CPU load
    local load_avg=$(uptime | awk '{print $10,$11,$12}')
    echo "  Load average: $load_avg"
    
    # Disk space for honeypot directory
    if [ -d "$HONEYPOT_DIR" ]; then
        local disk_info=$(df -h "$HONEYPOT_DIR" | tail -1)
        echo "  Disk usage: $disk_info"
    fi
}

# Function to display summary
display_summary() {
    echo
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}              Summary                 ${NC}"
    echo -e "${BLUE}=====================================${NC}"
    
    # Run all checks and count results
    local total_checks=0
    local passed_checks=0
    
    echo "Running comprehensive status check..."
    
    ((total_checks++))
    if check_installation > /dev/null 2>&1; then ((passed_checks++)); fi
    
    ((total_checks++))
    if check_service_status > /dev/null 2>&1; then ((passed_checks++)); fi
    
    ((total_checks++))
    if check_configuration > /dev/null 2>&1; then ((passed_checks++)); fi
    
    ((total_checks++))
    if check_traps > /dev/null 2>&1; then ((passed_checks++)); fi
    
    ((total_checks++))
    if check_connectivity > /dev/null 2>&1; then ((passed_checks++)); fi
    
    echo
    echo "Status: $passed_checks/$total_checks checks passed"
    
    if [ "$passed_checks" -eq "$total_checks" ]; then
        echo -e "${GREEN}✓ All systems operational${NC}"
    elif [ "$passed_checks" -gt "$((total_checks / 2))" ]; then
        echo -e "${YELLOW}⚠ Some issues detected${NC}"
    else
        echo -e "${RED}✗ Multiple issues detected${NC}"
    fi
}

# Main execution
main() {
    # Check if running as root (warn if so)
    if [ "$EUID" -eq 0 ]; then
        echo -e "${YELLOW}⚠ Warning: Running as root. Consider using regular user account.${NC}"
        echo
    fi
    
    # Run individual checks
    check_installation
    echo
    
    check_service_status
    echo
    
    check_configuration
    echo
    
    check_traps
    echo
    
    check_connectivity
    echo
    
    check_disk_usage
    echo
    
    check_resources
    echo
    
    check_recent_activity
    echo
    
    display_summary
    
    echo
    echo "For detailed logs, check: $LOG_FILE"
    echo "For configuration, check: $CONFIG_FILE"
    echo
    echo "Use './scripts/test-alerts.sh' to test alert system"
    echo "Use './scripts/cleanup.sh' to perform maintenance"
}

# Script help
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    echo "ShadowTrace Sentinel Status Checker"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help    Show this help message"
    echo "  -q, --quiet   Suppress verbose output"
    echo "  -s, --summary Show summary only"
    echo
    echo "This script checks the status of the ShadowTrace Sentinel honeypot system."
    exit 0
fi

# Handle quiet mode
if [ "${1:-}" = "-q" ] || [ "${1:-}" = "--quiet" ]; then
    exec > /dev/null 2>&1
fi

# Handle summary mode
if [ "${1:-}" = "-s" ] || [ "${1:-}" = "--summary" ]; then
    display_summary
    exit 0
fi

# Run main function
main
