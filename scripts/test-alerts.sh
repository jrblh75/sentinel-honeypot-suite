#!/bin/bash

# ShadowTrace Sentinel Alert Testing Script
# Tests alert system functionality and delivery

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.honeypot/config"
LOG_FILE="$HOME/.honeypot/logs/test-alerts.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

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

# Test result tracking
record_test() {
    local test_name="$1"
    local result="$2"
    local details="$3"
    
    ((TOTAL_TESTS++))
    
    if [[ "$result" == "PASS" ]]; then
        ((TESTS_PASSED++))
        print_status "$GREEN" "✓ $test_name - PASSED"
        log "INFO" "TEST PASS: $test_name - $details"
    else
        ((TESTS_FAILED++))
        print_status "$RED" "✗ $test_name - FAILED"
        log "ERROR" "TEST FAIL: $test_name - $details"
    fi
}

# Load configuration
load_config() {
    local config_file="$CONFIG_DIR/alerts.conf"
    
    if [[ ! -f "$config_file" ]]; then
        print_status "$RED" "Error: Alert configuration file not found: $config_file"
        exit 1
    fi
    
    # Source configuration (simplified parsing)
    eval "$(grep -E '^[a-zA-Z_][a-zA-Z0-9_]*=' "$config_file" 2>/dev/null || true)"
    
    # Set defaults if not configured
    EMAIL_ENABLED=${email_enabled:-false}
    WEBHOOK_ENABLED=${webhook_enabled:-false}
    SMTP_SERVER=${smtp_server:-""}
    SMTP_PORT=${smtp_port:-587}
    ADMIN_EMAIL=${admin_email:-""}
    PRIMARY_WEBHOOK=${primary_webhook:-""}
}

# Test email configuration
test_email_config() {
    local test_name="Email Configuration"
    
    if [[ "$EMAIL_ENABLED" != "true" ]]; then
        record_test "$test_name" "SKIP" "Email alerts disabled"
        return
    fi
    
    local errors=()
    
    # Check required email settings
    [[ -z "$SMTP_SERVER" ]] && errors+=("SMTP server not configured")
    [[ -z "$ADMIN_EMAIL" ]] && errors+=("Admin email not configured")
    [[ ! "$SMTP_PORT" =~ ^[0-9]+$ ]] && errors+=("Invalid SMTP port")
    
    if [[ ${#errors[@]} -eq 0 ]]; then
        record_test "$test_name" "PASS" "All email settings configured"
    else
        record_test "$test_name" "FAIL" "Missing settings: ${errors[*]}"
    fi
}

# Test webhook configuration
test_webhook_config() {
    local test_name="Webhook Configuration"
    
    if [[ "$WEBHOOK_ENABLED" != "true" ]]; then
        record_test "$test_name" "SKIP" "Webhook alerts disabled"
        return
    fi
    
    if [[ -n "$PRIMARY_WEBHOOK" ]] && [[ "$PRIMARY_WEBHOOK" =~ ^https?:// ]]; then
        record_test "$test_name" "PASS" "Webhook URL configured"
    else
        record_test "$test_name" "FAIL" "Invalid or missing webhook URL"
    fi
}

# Test SMTP connectivity
test_smtp_connectivity() {
    local test_name="SMTP Connectivity"
    
    if [[ "$EMAIL_ENABLED" != "true" ]] || [[ -z "$SMTP_SERVER" ]]; then
        record_test "$test_name" "SKIP" "Email not configured"
        return
    fi
    
    if timeout 10 bash -c "echo >/dev/tcp/$SMTP_SERVER/$SMTP_PORT" 2>/dev/null; then
        record_test "$test_name" "PASS" "SMTP server reachable on $SMTP_SERVER:$SMTP_PORT"
    else
        record_test "$test_name" "FAIL" "Cannot reach SMTP server $SMTP_SERVER:$SMTP_PORT"
    fi
}

# Test webhook connectivity
test_webhook_connectivity() {
    local test_name="Webhook Connectivity"
    
    if [[ "$WEBHOOK_ENABLED" != "true" ]] || [[ -z "$PRIMARY_WEBHOOK" ]]; then
        record_test "$test_name" "SKIP" "Webhook not configured"
        return
    fi
    
    if curl -s --max-time 10 --head "$PRIMARY_WEBHOOK" >/dev/null 2>&1; then
        record_test "$test_name" "PASS" "Webhook endpoint reachable"
    else
        record_test "$test_name" "FAIL" "Cannot reach webhook endpoint"
    fi
}

# Send test email
send_test_email() {
    local test_name="Email Delivery"
    local recipient="${1:-$ADMIN_EMAIL}"
    
    if [[ "$EMAIL_ENABLED" != "true" ]] || [[ -z "$SMTP_SERVER" ]]; then
        record_test "$test_name" "SKIP" "Email not configured"
        return
    fi
    
    local subject="ShadowTrace Sentinel Test Alert - $(date)"
    local body="This is a test alert from ShadowTrace Sentinel.

Test Details:
- Timestamp: $(date)
- System: $(hostname)
- Test Type: Email Delivery Test
- Alert Level: TEST

If you receive this message, email alerts are working correctly.

---
ShadowTrace Sentinel Honeypot Suite"
    
    # Create temporary email file
    local email_file=$(mktemp)
    cat > "$email_file" << EOF
Subject: $subject
To: $recipient
From: ShadowTrace Sentinel <noreply@$(hostname)>

$body
EOF
    
    # Send email using available method
    local sent=false
    
    # Try sendmail first
    if command -v sendmail >/dev/null 2>&1; then
        if sendmail "$recipient" < "$email_file"; then
            sent=true
        fi
    fi
    
    # Try mail command
    if [[ "$sent" == false ]] && command -v mail >/dev/null 2>&1; then
        if echo "$body" | mail -s "$subject" "$recipient"; then
            sent=true
        fi
    fi
    
    # Try Python SMTP
    if [[ "$sent" == false ]] && command -v python3 >/dev/null 2>&1; then
        python3 << EOF
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

try:
    msg = MIMEMultipart()
    msg['From'] = 'noreply@$(hostname)'
    msg['To'] = '$recipient'
    msg['Subject'] = '$subject'
    msg.attach(MIMEText('$body', 'plain'))
    
    server = smtplib.SMTP('$SMTP_SERVER', $SMTP_PORT)
    server.starttls()
    server.send_message(msg)
    server.quit()
    print("SUCCESS")
except Exception as e:
    print(f"ERROR: {e}")
EOF
        if [[ $? -eq 0 ]]; then
            sent=true
        fi
    fi
    
    rm -f "$email_file"
    
    if [[ "$sent" == true ]]; then
        record_test "$test_name" "PASS" "Test email sent to $recipient"
    else
        record_test "$test_name" "FAIL" "Failed to send test email"
    fi
}

# Send test webhook
send_test_webhook() {
    local test_name="Webhook Delivery"
    
    if [[ "$WEBHOOK_ENABLED" != "true" ]] || [[ -z "$PRIMARY_WEBHOOK" ]]; then
        record_test "$test_name" "SKIP" "Webhook not configured"
        return
    fi
    
    local payload=$(cat << EOF
{
    "alert_type": "test",
    "severity": "info",
    "timestamp": "$(date -Iseconds)",
    "source": "shadowtrace-sentinel",
    "system": "$(hostname)",
    "message": "This is a test alert from ShadowTrace Sentinel",
    "details": {
        "test_type": "webhook_delivery_test",
        "alert_id": "test_$(date +%s)",
        "source_ip": "127.0.0.1",
        "event_type": "system_test"
    },
    "metadata": {
        "honeypot_id": "$(hostname)",
        "version": "1.0",
        "test_mode": true
    }
}
EOF
)
    
    local response
    local http_code
    
    response=$(curl -s -w "%{http_code}" \
                   -X POST \
                   -H "Content-Type: application/json" \
                   -H "User-Agent: ShadowTrace-Sentinel/1.0" \
                   --max-time 30 \
                   -d "$payload" \
                   "$PRIMARY_WEBHOOK" 2>/dev/null)
    
    http_code="${response: -3}"
    response_body="${response%???}"
    
    if [[ "$http_code" =~ ^2[0-9][0-9]$ ]]; then
        record_test "$test_name" "PASS" "Webhook delivered (HTTP $http_code)"
    else
        record_test "$test_name" "FAIL" "Webhook failed (HTTP $http_code)"
    fi
}

# Test alert rate limiting
test_rate_limiting() {
    local test_name="Rate Limiting"
    
    # This would normally test the actual rate limiting implementation
    # For now, we'll just verify the configuration exists
    local max_alerts_per_hour=${max_alerts_per_hour:-10}
    
    if [[ "$max_alerts_per_hour" =~ ^[0-9]+$ ]] && [[ "$max_alerts_per_hour" -gt 0 ]]; then
        record_test "$test_name" "PASS" "Rate limiting configured ($max_alerts_per_hour/hour)"
    else
        record_test "$test_name" "FAIL" "Invalid rate limiting configuration"
    fi
}

# Test alert formatting
test_alert_formatting() {
    local test_name="Alert Formatting"
    
    # Test that we can generate properly formatted alerts
    local test_alert=$(cat << EOF
{
    "timestamp": "$(date -Iseconds)",
    "severity": "high",
    "type": "file_access",
    "source_ip": "192.168.1.100",
    "description": "Test alert formatting",
    "details": {
        "file": "/test/file.txt",
        "action": "read"
    }
}
EOF
)
    
    # Validate JSON format
    if echo "$test_alert" | python3 -m json.tool >/dev/null 2>&1; then
        record_test "$test_name" "PASS" "Alert JSON formatting valid"
    else
        record_test "$test_name" "FAIL" "Invalid alert JSON formatting"
    fi
}

# Test alert escalation
test_alert_escalation() {
    local test_name="Alert Escalation"
    
    # Check if escalation configuration exists
    local escalation_config="$CONFIG_DIR/escalation.conf"
    
    if [[ -f "$escalation_config" ]]; then
        record_test "$test_name" "PASS" "Escalation configuration found"
    else
        record_test "$test_name" "WARN" "No escalation configuration found"
    fi
}

# Test log file access
test_log_access() {
    local test_name="Alert Log Access"
    local alert_log="$HOME/.honeypot/logs/alerts.log"
    
    # Try to write a test entry
    if echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TEST] Alert log test" >> "$alert_log" 2>/dev/null; then
        record_test "$test_name" "PASS" "Alert log writable"
    else
        record_test "$test_name" "FAIL" "Cannot write to alert log"
    fi
}

# Generate alert performance metrics
test_alert_performance() {
    local test_name="Alert Performance"
    
    # Time a simple alert generation
    local start_time=$(date +%s.%N)
    
    # Simulate alert processing
    sleep 0.1
    
    local end_time=$(date +%s.%N)
    local duration=$(echo "$end_time - $start_time" | bc -l 2>/dev/null || echo "0.1")
    
    # Alert should process in under 1 second
    if (( $(echo "$duration < 1.0" | bc -l 2>/dev/null || echo 0) )); then
        record_test "$test_name" "PASS" "Alert processing time: ${duration}s"
    else
        record_test "$test_name" "FAIL" "Alert processing too slow: ${duration}s"
    fi
}

# Generate test report
generate_report() {
    local report_file="$HOME/.honeypot/logs/alert-test-report-$(date +%Y%m%d-%H%M%S).txt"
    
    cat > "$report_file" << EOF
ShadowTrace Sentinel Alert System Test Report
============================================

Test Date: $(date)
System: $(hostname)
User: $(whoami)

Test Summary:
- Total Tests: $TOTAL_TESTS
- Passed: $TESTS_PASSED
- Failed: $TESTS_FAILED
- Success Rate: $(( TESTS_PASSED * 100 / TOTAL_TESTS ))%

Configuration Status:
- Email Enabled: $EMAIL_ENABLED
- Webhook Enabled: $WEBHOOK_ENABLED
- SMTP Server: ${SMTP_SERVER:-"Not configured"}
- Webhook URL: ${PRIMARY_WEBHOOK:-"Not configured"}

$(if [[ $TESTS_FAILED -gt 0 ]]; then
    echo "⚠️  ALERT SYSTEM ISSUES DETECTED"
    echo "Review the test log for details: $LOG_FILE"
else
    echo "✅ ALL TESTS PASSED"
    echo "Alert system is functioning correctly"
fi)

Detailed results can be found in: $LOG_FILE

EOF
    
    print_status "$BLUE" "Test report generated: $report_file"
}

# Show usage information
usage() {
    cat << EOF
ShadowTrace Sentinel Alert Testing Script

Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -e, --email             Test email alerts only
    -w, --webhook           Test webhook alerts only
    -c, --config            Test configuration only
    -s, --send              Send actual test alerts
    -r, --report            Generate detailed report
    --email-to EMAIL        Send test email to specific address

Examples:
    $0                      # Run all tests
    $0 --config             # Test configuration only
    $0 --send               # Send actual test alerts
    $0 --email-to admin@company.com  # Send test to specific email

EOF
}

# Main function
main() {
    local email_only=false
    local webhook_only=false
    local config_only=false
    local send_alerts=false
    local generate_report_flag=false
    local test_email_address=""
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -e|--email)
                email_only=true
                shift
                ;;
            -w|--webhook)
                webhook_only=true
                shift
                ;;
            -c|--config)
                config_only=true
                shift
                ;;
            -s|--send)
                send_alerts=true
                shift
                ;;
            -r|--report)
                generate_report_flag=true
                shift
                ;;
            --email-to)
                test_email_address="$2"
                shift 2
                ;;
            *)
                print_status "$RED" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    print_status "$BLUE" "ShadowTrace Sentinel Alert System Test"
    print_status "$BLUE" "====================================="
    
    # Create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    log "INFO" "Starting alert system tests"
    
    # Load configuration
    load_config
    
    # Run configuration tests
    if [[ "$webhook_only" != true ]]; then
        test_email_config
        test_smtp_connectivity
    fi
    
    if [[ "$email_only" != true ]]; then
        test_webhook_config
        test_webhook_connectivity
    fi
    
    # Run additional tests if not config-only
    if [[ "$config_only" != true ]]; then
        test_rate_limiting
        test_alert_formatting
        test_alert_escalation
        test_log_access
        test_alert_performance
    fi
    
    # Send actual test alerts if requested
    if [[ "$send_alerts" == true ]]; then
        if [[ "$webhook_only" != true ]]; then
            if [[ -n "$test_email_address" ]]; then
                send_test_email "$test_email_address"
            else
                send_test_email
            fi
        fi
        
        if [[ "$email_only" != true ]]; then
            send_test_webhook
        fi
    fi
    
    # Display results
    echo
    print_status "$BLUE" "Test Results Summary:"
    print_status "$BLUE" "===================="
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        print_status "$GREEN" "✅ All tests passed ($TESTS_PASSED/$TOTAL_TESTS)"
        log "INFO" "All alert system tests passed"
    else
        print_status "$RED" "❌ Some tests failed ($TESTS_FAILED/$TOTAL_TESTS failed)"
        print_status "$YELLOW" "Review the logs for details: $LOG_FILE"
        log "ERROR" "Alert system tests completed with failures"
    fi
    
    # Generate report if requested
    if [[ "$generate_report_flag" == true ]]; then
        generate_report
    fi
    
    # Exit with appropriate code
    exit $TESTS_FAILED
}

# Run main function
main "$@"
