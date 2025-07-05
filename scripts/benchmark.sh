#!/bin/bash

# ShadowTrace Sentinel Benchmark Script
# Performance testing and benchmarking

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_FILE="$HOME/.honeypot/logs/benchmark.log"
RESULTS_FILE="$HOME/.honeypot/logs/benchmark-results-$(date +%Y%m%d-%H%M%S).json"

# Default benchmark parameters
DEFAULT_DURATION=300  # 5 minutes
DEFAULT_CONNECTIONS=10
DEFAULT_REQUESTS_PER_SECOND=5

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Benchmark results
declare -A BENCHMARK_RESULTS

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

# Store benchmark result
store_result() {
    local test_name="$1"
    local metric="$2"
    local value="$3"
    local unit="$4"
    
    BENCHMARK_RESULTS["${test_name}_${metric}"]="$value"
    BENCHMARK_RESULTS["${test_name}_${metric}_unit"]="$unit"
    
    print_status "$BLUE" "  $metric: $value $unit"
    log "INFO" "BENCHMARK: $test_name - $metric: $value $unit"
}

# Get system information
get_system_info() {
    print_status "$BLUE" "System Information"
    print_status "$BLUE" "=================="
    
    local cpu_info memory_info disk_info
    
    case "$(uname)" in
        "Linux")
            cpu_info=$(grep "model name" /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)
            memory_info=$(grep "MemTotal" /proc/meminfo | awk '{print $2, $3}')
            disk_info=$(df -h "$HOME" | tail -1 | awk '{print $2}')
            ;;
        "Darwin")
            cpu_info=$(sysctl -n machdep.cpu.brand_string)
            memory_info=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024) " GB"}')
            disk_info=$(df -h "$HOME" | tail -1 | awk '{print $2}')
            ;;
        *)
            cpu_info="Unknown"
            memory_info="Unknown"
            disk_info="Unknown"
            ;;
    esac
    
    print_status "$GREEN" "CPU: $cpu_info"
    print_status "$GREEN" "Memory: $memory_info"
    print_status "$GREEN" "Disk: $disk_info"
    print_status "$GREEN" "OS: $(uname -s) $(uname -r)"
    
    BENCHMARK_RESULTS["system_cpu"]="$cpu_info"
    BENCHMARK_RESULTS["system_memory"]="$memory_info"
    BENCHMARK_RESULTS["system_disk"]="$disk_info"
    BENCHMARK_RESULTS["system_os"]="$(uname -s) $(uname -r)"
}

# Benchmark system performance
benchmark_system_performance() {
    print_status "$BLUE" "\nSystem Performance Benchmark"
    print_status "$BLUE" "============================"
    
    # CPU benchmark
    print_status "$YELLOW" "Running CPU benchmark..."
    local cpu_start=$(date +%s.%N)
    
    # Simple CPU stress test
    for i in {1..1000000}; do
        echo "scale=10; sqrt($i)" | bc -l >/dev/null 2>&1
    done
    
    local cpu_end=$(date +%s.%N)
    local cpu_time=$(echo "$cpu_end - $cpu_start" | bc -l)
    store_result "system" "cpu_computation_time" "$cpu_time" "seconds"
    
    # Memory benchmark
    print_status "$YELLOW" "Running memory benchmark..."
    local mem_start=$(date +%s.%N)
    
    # Create and manipulate large arrays in memory
    python3 << 'EOF'
import time
import sys

start_time = time.time()

# Allocate and manipulate memory
data = []
for i in range(100000):
    data.append(str(i) * 10)

# Sort the data (memory intensive)
data.sort()

end_time = time.time()
print(f"{end_time - start_time:.6f}")
EOF
    
    local mem_time=$(python3 << 'EOF'
import time
start_time = time.time()
data = []
for i in range(100000):
    data.append(str(i) * 10)
data.sort()
end_time = time.time()
print(f"{end_time - start_time:.6f}")
EOF
)
    
    store_result "system" "memory_operation_time" "$mem_time" "seconds"
    
    # Disk I/O benchmark
    print_status "$YELLOW" "Running disk I/O benchmark..."
    local disk_start=$(date +%s.%N)
    
    # Write test
    dd if=/dev/zero of=/tmp/benchmark_test bs=1M count=100 2>/dev/null
    sync
    
    # Read test
    dd if=/tmp/benchmark_test of=/dev/null bs=1M 2>/dev/null
    
    local disk_end=$(date +%s.%N)
    local disk_time=$(echo "$disk_end - $disk_start" | bc -l)
    
    rm -f /tmp/benchmark_test
    
    store_result "system" "disk_io_time" "$disk_time" "seconds"
}

# Benchmark network performance
benchmark_network_performance() {
    print_status "$BLUE" "\nNetwork Performance Benchmark"
    print_status "$BLUE" "============================="
    
    # Localhost latency test
    print_status "$YELLOW" "Testing localhost latency..."
    local ping_results
    ping_results=$(ping -c 10 127.0.0.1 2>/dev/null | grep "round-trip" | awk -F'/' '{print $5}')
    
    if [[ -n "$ping_results" ]]; then
        store_result "network" "localhost_latency" "$ping_results" "ms"
    else
        store_result "network" "localhost_latency" "N/A" "ms"
    fi
    
    # TCP connection speed test
    print_status "$YELLOW" "Testing TCP connection speed..."
    local tcp_start=$(date +%s.%N)
    
    # Test multiple rapid connections to localhost
    for i in {1..100}; do
        timeout 1 bash -c "echo test | nc 127.0.0.1 22" 2>/dev/null || true
    done
    
    local tcp_end=$(date +%s.%N)
    local tcp_time=$(echo "$tcp_end - $tcp_start" | bc -l)
    local connections_per_second=$(echo "scale=2; 100 / $tcp_time" | bc -l)
    
    store_result "network" "tcp_connections_per_second" "$connections_per_second" "conn/sec"
    
    # DNS resolution test
    print_status "$YELLOW" "Testing DNS resolution speed..."
    local dns_start=$(date +%s.%N)
    
    for domain in google.com github.com cloudflare.com; do
        nslookup "$domain" >/dev/null 2>&1 || true
    done
    
    local dns_end=$(date +%s.%N)
    local dns_time=$(echo "$dns_end - $dns_start" | bc -l)
    local dns_per_second=$(echo "scale=2; 3 / $dns_time" | bc -l)
    
    store_result "network" "dns_lookups_per_second" "$dns_per_second" "lookups/sec"
}

# Benchmark honeypot performance
benchmark_honeypot_performance() {
    print_status "$BLUE" "\nHoneypot Performance Benchmark"
    print_status "$BLUE" "=============================="
    
    # Service startup time
    print_status "$YELLOW" "Testing service startup time..."
    
    # Stop service if running
    if "$SCRIPT_DIR/status.sh" --quiet 2>/dev/null; then
        "$SCRIPT_DIR/../scripts/stop-service.sh" 2>/dev/null || true
        sleep 2
    fi
    
    # Time service startup
    local startup_start=$(date +%s.%N)
    "$SCRIPT_DIR/../scripts/start-service.sh" 2>/dev/null || true
    
    # Wait for service to be ready
    local ready=false
    for i in {1..30}; do
        if "$SCRIPT_DIR/status.sh" --quiet 2>/dev/null; then
            ready=true
            break
        fi
        sleep 1
    done
    
    local startup_end=$(date +%s.%N)
    local startup_time=$(echo "$startup_end - $startup_start" | bc -l)
    
    if [[ "$ready" == true ]]; then
        store_result "honeypot" "startup_time" "$startup_time" "seconds"
    else
        store_result "honeypot" "startup_time" "timeout" "seconds"
    fi
    
    # Response time test
    print_status "$YELLOW" "Testing response time..."
    local response_times=()
    
    for i in {1..10}; do
        local resp_start=$(date +%s.%N)
        "$SCRIPT_DIR/status.sh" --quiet 2>/dev/null || true
        local resp_end=$(date +%s.%N)
        local resp_time=$(echo "$resp_end - $resp_start" | bc -l)
        response_times+=("$resp_time")
    done
    
    # Calculate average response time
    local total_time=0
    for time in "${response_times[@]}"; do
        total_time=$(echo "$total_time + $time" | bc -l)
    done
    local avg_response_time=$(echo "scale=6; $total_time / ${#response_times[@]}" | bc -l)
    
    store_result "honeypot" "average_response_time" "$avg_response_time" "seconds"
    
    # Memory usage
    print_status "$YELLOW" "Testing memory usage..."
    local memory_usage
    case "$(uname)" in
        "Linux")
            if pgrep -f "shadowtrace" >/dev/null; then
                memory_usage=$(ps -o rss= -p $(pgrep -f "shadowtrace") | awk '{sum+=$1} END {print sum}')
                memory_usage=$((memory_usage / 1024))  # Convert to MB
            else
                memory_usage="N/A"
            fi
            ;;
        "Darwin")
            if pgrep -f "shadowtrace" >/dev/null; then
                memory_usage=$(ps -o rss= -p $(pgrep -f "shadowtrace") | awk '{sum+=$1} END {print sum/1024}')
            else
                memory_usage="N/A"
            fi
            ;;
        *)
            memory_usage="N/A"
            ;;
    esac
    
    store_result "honeypot" "memory_usage" "$memory_usage" "MB"
}

# Benchmark alert system performance
benchmark_alert_system() {
    print_status "$BLUE" "\nAlert System Performance Benchmark"
    print_status "$BLUE" "=================================="
    
    # Alert generation speed
    print_status "$YELLOW" "Testing alert generation speed..."
    local alert_start=$(date +%s.%N)
    
    # Generate test alerts
    for i in {1..100}; do
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] [TEST] Benchmark alert $i" >> "$HOME/.honeypot/logs/alerts.log" 2>/dev/null || true
    done
    
    local alert_end=$(date +%s.%N)
    local alert_time=$(echo "$alert_end - $alert_start" | bc -l)
    local alerts_per_second=$(echo "scale=2; 100 / $alert_time" | bc -l)
    
    store_result "alerts" "generation_speed" "$alerts_per_second" "alerts/sec"
    
    # Alert processing time
    print_status "$YELLOW" "Testing alert processing time..."
    
    if [[ -x "$SCRIPT_DIR/test-alerts.sh" ]]; then
        local process_start=$(date +%s.%N)
        "$SCRIPT_DIR/test-alerts.sh" --config 2>/dev/null || true
        local process_end=$(date +%s.%N)
        local process_time=$(echo "$process_end - $process_start" | bc -l)
        
        store_result "alerts" "processing_time" "$process_time" "seconds"
    else
        store_result "alerts" "processing_time" "N/A" "seconds"
    fi
}

# Benchmark file monitoring performance
benchmark_file_monitoring() {
    print_status "$BLUE" "\nFile Monitoring Performance Benchmark"
    print_status "$BLUE" "======================================"
    
    # File creation detection speed
    print_status "$YELLOW" "Testing file monitoring speed..."
    
    local test_dir="/tmp/honeypot_benchmark"
    mkdir -p "$test_dir"
    
    local monitor_start=$(date +%s.%N)
    
    # Create multiple files rapidly
    for i in {1..100}; do
        echo "test content $i" > "$test_dir/test_file_$i.txt"
    done
    
    local monitor_end=$(date +%s.%N)
    local monitor_time=$(echo "$monitor_end - $monitor_start" | bc -l)
    local files_per_second=$(echo "scale=2; 100 / $monitor_time" | bc -l)
    
    store_result "monitoring" "file_creation_speed" "$files_per_second" "files/sec"
    
    # Clean up test files
    rm -rf "$test_dir"
}

# Stress test the honeypot
stress_test_honeypot() {
    local duration="$1"
    local concurrent_connections="$2"
    local requests_per_second="$3"
    
    print_status "$BLUE" "\nHoneypot Stress Test"
    print_status "$BLUE" "===================="
    print_status "$YELLOW" "Duration: ${duration}s, Connections: $concurrent_connections, RPS: $requests_per_second"
    
    # Check if service is running
    if ! "$SCRIPT_DIR/status.sh" --quiet 2>/dev/null; then
        print_status "$RED" "Honeypot service not running, skipping stress test"
        return
    fi
    
    local stress_start=$(date +%s)
    local total_requests=0
    local successful_requests=0
    local failed_requests=0
    
    # Run stress test
    while [[ $(($(date +%s) - stress_start)) -lt $duration ]]; do
        for ((i=1; i<=concurrent_connections; i++)); do
            {
                if timeout 5 bash -c "echo test | nc 127.0.0.1 22" >/dev/null 2>&1; then
                    ((successful_requests++))
                else
                    ((failed_requests++))
                fi
                ((total_requests++))
            } &
        done
        
        # Wait between batches to control request rate
        sleep $(echo "scale=2; $concurrent_connections / $requests_per_second" | bc -l)
        
        # Clean up background processes
        wait
    done
    
    local stress_end=$(date +%s)
    local actual_duration=$((stress_end - stress_start))
    local actual_rps=$(echo "scale=2; $total_requests / $actual_duration" | bc -l)
    local success_rate=$(echo "scale=2; $successful_requests * 100 / $total_requests" | bc -l)
    
    store_result "stress" "total_requests" "$total_requests" "requests"
    store_result "stress" "successful_requests" "$successful_requests" "requests"
    store_result "stress" "failed_requests" "$failed_requests" "requests"
    store_result "stress" "actual_rps" "$actual_rps" "req/sec"
    store_result "stress" "success_rate" "$success_rate" "percent"
    store_result "stress" "duration" "$actual_duration" "seconds"
}

# Generate benchmark report
generate_benchmark_report() {
    print_status "$BLUE" "\nGenerating Benchmark Report"
    print_status "$BLUE" "==========================="
    
    # JSON report
    cat > "$RESULTS_FILE" << EOF
{
  "benchmark_info": {
    "timestamp": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "os": "$(uname -s)",
    "arch": "$(uname -m)",
    "version": "1.0"
  },
  "results": {
EOF
    
    local first=true
    for key in "${!BENCHMARK_RESULTS[@]}"; do
        if [[ ! "$key" =~ _unit$ ]]; then
            local unit_key="${key}_unit"
            local unit="${BENCHMARK_RESULTS[$unit_key]:-""}"
            local value="${BENCHMARK_RESULTS[$key]}"
            
            if [[ "$first" == true ]]; then
                first=false
            else
                echo "," >> "$RESULTS_FILE"
            fi
            
            echo "    \"$key\": {" >> "$RESULTS_FILE"
            echo "      \"value\": \"$value\"," >> "$RESULTS_FILE"
            echo "      \"unit\": \"$unit\"" >> "$RESULTS_FILE"
            echo -n "    }" >> "$RESULTS_FILE"
        fi
    done
    
    cat >> "$RESULTS_FILE" << EOF

  }
}
EOF
    
    # Human-readable report
    local text_report="${RESULTS_FILE%.json}.txt"
    cat > "$text_report" << EOF
ShadowTrace Sentinel Benchmark Report
=====================================

Benchmark Date: $(date)
System: $(hostname) ($(uname -s) $(uname -m))

System Information:
$(for key in "${!BENCHMARK_RESULTS[@]}"; do
    if [[ "$key" =~ ^system_ ]] && [[ ! "$key" =~ _unit$ ]]; then
        local display_name=$(echo "$key" | sed 's/system_//' | tr '_' ' ' | sed 's/\b\w/\U&/g')
        echo "- $display_name: ${BENCHMARK_RESULTS[$key]}"
    fi
done)

Performance Results:
$(for category in system network honeypot alerts monitoring stress; do
    echo ""
    echo "${category^} Performance:"
    for key in "${!BENCHMARK_RESULTS[@]}"; do
        if [[ "$key" =~ ^${category}_ ]] && [[ ! "$key" =~ _unit$ ]]; then
            local unit_key="${key}_unit"
            local unit="${BENCHMARK_RESULTS[$unit_key]:-""}"
            local value="${BENCHMARK_RESULTS[$key]}"
            local display_name=$(echo "$key" | sed "s/${category}_//" | tr '_' ' ' | sed 's/\b\w/\U&/g')
            echo "- $display_name: $value $unit"
        fi
    done
done)

Files Generated:
- JSON Report: $RESULTS_FILE
- Text Report: $text_report
- Detailed Log: $LOG_FILE

EOF
    
    print_status "$GREEN" "Benchmark report generated:"
    print_status "$GREEN" "- JSON: $RESULTS_FILE"
    print_status "$GREEN" "- Text: $text_report"
}

# Show usage information
usage() {
    cat << EOF
ShadowTrace Sentinel Benchmark Script

Usage: $0 [OPTIONS]

Options:
    -h, --help              Show this help message
    -d, --duration SECONDS  Stress test duration (default: $DEFAULT_DURATION)
    -c, --connections NUM   Concurrent connections (default: $DEFAULT_CONNECTIONS)
    -r, --rps NUM          Requests per second (default: $DEFAULT_REQUESTS_PER_SECOND)
    -s, --system           Run system benchmarks only
    -n, --network          Run network benchmarks only
    -p, --honeypot         Run honeypot benchmarks only
    -a, --alerts           Run alert system benchmarks only
    -m, --monitoring       Run monitoring benchmarks only
    --stress               Run stress test only
    --no-stress            Skip stress test
    --quick                Quick benchmark (reduced duration)

Examples:
    $0                      # Full benchmark suite
    $0 --system --network   # System and network only
    $0 --stress -d 600 -c 20 -r 10  # Custom stress test
    $0 --quick              # Quick benchmark

EOF
}

# Main function
main() {
    local duration=$DEFAULT_DURATION
    local connections=$DEFAULT_CONNECTIONS
    local rps=$DEFAULT_REQUESTS_PER_SECOND
    local run_system=false
    local run_network=false
    local run_honeypot=false
    local run_alerts=false
    local run_monitoring=false
    local run_stress=true
    local run_all=true
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -d|--duration)
                duration="$2"
                shift 2
                ;;
            -c|--connections)
                connections="$2"
                shift 2
                ;;
            -r|--rps)
                rps="$2"
                shift 2
                ;;
            -s|--system)
                run_system=true
                run_all=false
                shift
                ;;
            -n|--network)
                run_network=true
                run_all=false
                shift
                ;;
            -p|--honeypot)
                run_honeypot=true
                run_all=false
                shift
                ;;
            -a|--alerts)
                run_alerts=true
                run_all=false
                shift
                ;;
            -m|--monitoring)
                run_monitoring=true
                run_all=false
                shift
                ;;
            --stress)
                run_stress=true
                run_all=false
                shift
                ;;
            --no-stress)
                run_stress=false
                shift
                ;;
            --quick)
                duration=60
                connections=5
                rps=2
                shift
                ;;
            *)
                print_status "$RED" "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    print_status "$BLUE" "ShadowTrace Sentinel Benchmark Suite"
    print_status "$BLUE" "====================================="
    
    # Create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE"
    
    log "INFO" "Starting benchmark suite"
    
    # Get system information
    get_system_info
    
    # Run selected benchmarks
    if [[ "$run_all" == true ]] || [[ "$run_system" == true ]]; then
        benchmark_system_performance
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_network" == true ]]; then
        benchmark_network_performance
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_honeypot" == true ]]; then
        benchmark_honeypot_performance
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_alerts" == true ]]; then
        benchmark_alert_system
    fi
    
    if [[ "$run_all" == true ]] || [[ "$run_monitoring" == true ]]; then
        benchmark_file_monitoring
    fi
    
    if [[ "$run_stress" == true ]]; then
        stress_test_honeypot "$duration" "$connections" "$rps"
    fi
    
    # Generate report
    generate_benchmark_report
    
    print_status "$GREEN" "\nBenchmark completed successfully!"
    log "INFO" "Benchmark suite completed"
}

# Run main function
main "$@"
