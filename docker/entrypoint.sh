#!/bin/bash
# ShadowTrace Sentinel Docker Entrypoint Script
set -e

# Initialize default environment variables
export SENTINEL_HOME=${SENTINEL_HOME:-/var/lib/sentinel}
export SENTINEL_LOGS=${SENTINEL_LOGS:-/var/log/sentinel}
export SENTINEL_CONFIG=${SENTINEL_CONFIG:-/etc/sentinel}

# Function to log messages
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ENTRYPOINT: $*" | tee -a "${SENTINEL_LOGS}/startup.log"
}

# Function to wait for database connection
wait_for_db() {
    local host="${POSTGRES_HOST:-localhost}"
    local port="${POSTGRES_PORT:-5432}"
    local timeout=30
    
    log "Waiting for PostgreSQL at ${host}:${port}..."
    
    until nc -z "$host" "$port" || [ $timeout -eq 0 ]; do
        log "PostgreSQL not ready, waiting... (${timeout}s remaining)"
        sleep 1
        timeout=$((timeout - 1))
    done
    
    if [ $timeout -eq 0 ]; then
        log "ERROR: PostgreSQL connection timeout"
        exit 1
    fi
    
    log "PostgreSQL is ready!"
}

# Function to initialize sentinel configuration
init_config() {
    log "Initializing Sentinel configuration..."
    
    # Create configuration directories
    mkdir -p "${SENTINEL_CONFIG}/honeypots"
    mkdir -p "${SENTINEL_CONFIG}/alerts"
    mkdir -p "${SENTINEL_CONFIG}/encryption"
    
    # Copy default configuration if not exists
    if [ ! -f "${SENTINEL_CONFIG}/sentinel.conf" ]; then
        cp /app/config/sentinel.conf.template "${SENTINEL_CONFIG}/sentinel.conf"
    fi
    
    # Set permissions
    chmod 600 "${SENTINEL_CONFIG}"/*.conf 2>/dev/null || true
    
    log "Configuration initialized"
}

# Function to initialize logging
init_logs() {
    log "Initializing logging system..."
    
    # Create log directories
    mkdir -p "${SENTINEL_LOGS}/honeypots"
    mkdir -p "${SENTINEL_LOGS}/alerts"
    mkdir -p "${SENTINEL_LOGS}/system"
    
    # Set log file permissions
    touch "${SENTINEL_LOGS}/sentinel.log"
    touch "${SENTINEL_LOGS}/alerts.log"
    touch "${SENTINEL_LOGS}/triggers.log"
    
    chmod 644 "${SENTINEL_LOGS}"/*.log
    
    log "Logging system initialized"
}

# Function to start sentinel services
start_sentinel() {
    log "Starting ShadowTrace Sentinel Honeypot Suite..."
    
    # Initialize database schema if needed
    if [ "${INIT_DB:-false}" = "true" ]; then
        log "Initializing database schema..."
        python -m sentinel.db.migrate
    fi
    
    # Start honeypot services based on configuration
    case "${1:-start}" in
        "start")
            log "Starting all honeypot services..."
            exec python -m sentinel.main --mode=production
            ;;
        "honeypot")
            log "Starting honeypot services only..."
            exec python -m sentinel.honeypot.server
            ;;
        "monitor")
            log "Starting monitoring services only..."
            exec python -m sentinel.monitor.server
            ;;
        "alerts")
            log "Starting alert services only..."
            exec python -m sentinel.alerts.server
            ;;
        "shell")
            log "Starting interactive shell..."
            exec /bin/bash
            ;;
        *)
            log "Starting with custom command: $*"
            exec "$@"
            ;;
    esac
}

# Main execution flow
main() {
    log "ShadowTrace Sentinel Docker Container Starting..."
    log "Container ID: $(hostname)"
    log "User: $(whoami)"
    log "Working Directory: $(pwd)"
    
    # Initialize directories and permissions
    init_logs
    init_config
    
    # Wait for dependencies
    if [ "${WAIT_FOR_DB:-true}" = "true" ]; then
        wait_for_db
    fi
    
    # Start services
    start_sentinel "$@"
}

# Signal handling for graceful shutdown
trap 'log "Received shutdown signal, stopping services..."; exit 0' SIGTERM SIGINT

# Execute main function
main "$@"
