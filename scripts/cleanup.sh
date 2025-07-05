#!/bin/bash
# ShadowTrace Sentinel Cleanup Script
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
LOG_DIR="$HONEYPOT_DIR/logs"
BACKUP_DIR="$HONEYPOT_DIR/backups"
CONFIG_FILE="$HONEYPOT_DIR/config/sentinel.conf"

# Default retention periods (days)
DEFAULT_LOG_RETENTION=30
DEFAULT_BACKUP_RETENTION=90
DEFAULT_ALERT_RETENTION=365

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  ShadowTrace Sentinel Cleanup       ${NC}"
echo -e "${BLUE}=====================================${NC}"
echo

# Function to load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        # Source configuration if it exists
        while IFS='=' read -r key value; do
            # Skip comments and empty lines
            [[ $key =~ ^[[:space:]]*# ]] && continue
            [[ -z $key ]] && continue
            
            # Remove quotes from value
            value=$(echo "$value" | sed 's/^"//;s/"$//')
            
            case $key in
                "LOG_RETENTION_DAYS")
                    LOG_RETENTION_DAYS=$value
                    ;;
                "BACKUP_RETENTION_DAYS")
                    BACKUP_RETENTION_DAYS=$value
                    ;;
                "ALERT_RETENTION_DAYS")
                    ALERT_RETENTION_DAYS=$value
                    ;;
            esac
        done < "$CONFIG_FILE"
    fi
    
    # Set defaults if not found in config
    LOG_RETENTION_DAYS=${LOG_RETENTION_DAYS:-$DEFAULT_LOG_RETENTION}
    BACKUP_RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-$DEFAULT_BACKUP_RETENTION}
    ALERT_RETENTION_DAYS=${ALERT_RETENTION_DAYS:-$DEFAULT_ALERT_RETENTION}
}

# Function to clean old log files
cleanup_logs() {
    echo -e "${BLUE}Cleaning up old log files...${NC}"
    
    if [ ! -d "$LOG_DIR" ]; then
        echo -e "${YELLOW}⚠ Log directory not found: $LOG_DIR${NC}"
        return 1
    fi
    
    local files_removed=0
    local space_freed=0
    
    # Find and remove old log files
    while IFS= read -r -d '' file; do
        local file_size=$(stat -f%z "$file" 2>/dev/null || echo "0")
        rm "$file"
        ((files_removed++))
        ((space_freed+=file_size))
    done < <(find "$LOG_DIR" -name "*.log" -type f -mtime +$LOG_RETENTION_DAYS -print0 2>/dev/null)
    
    # Convert bytes to human readable
    local space_freed_mb=$((space_freed / 1024 / 1024))
    
    echo "  Files removed: $files_removed"
    echo "  Space freed: ${space_freed_mb}MB"
}

# Function to clean old backup files
cleanup_backups() {
    echo -e "${BLUE}Cleaning up old backup files...${NC}"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}⚠ Backup directory not found: $BACKUP_DIR${NC}"
        return 1
    fi
    
    local files_removed=0
    local space_freed=0
    
    # Find and remove old backup files
    while IFS= read -r -d '' file; do
        local file_size=$(stat -f%z "$file" 2>/dev/null || echo "0")
        rm "$file"
        ((files_removed++))
        ((space_freed+=file_size))
    done < <(find "$BACKUP_DIR" -name "*.tar.gz" -type f -mtime +$BACKUP_RETENTION_DAYS -print0 2>/dev/null)
    
    # Convert bytes to human readable
    local space_freed_mb=$((space_freed / 1024 / 1024))
    
    echo "  Files removed: $files_removed"
    echo "  Space freed: ${space_freed_mb}MB"
}

# Function to clean old alert data
cleanup_alerts() {
    echo -e "${BLUE}Cleaning up old alert data...${NC}"
    
    local alert_file="$LOG_DIR/alerts.log"
    if [ ! -f "$alert_file" ]; then
        echo -e "${YELLOW}⚠ Alert file not found: $alert_file${NC}"
        return 1
    fi
    
    # Create temporary file with recent alerts only
    local temp_file=$(mktemp)
    local cutoff_date=$(date -d "$ALERT_RETENTION_DAYS days ago" '+%Y-%m-%d' 2>/dev/null || date -v-${ALERT_RETENTION_DAYS}d '+%Y-%m-%d')
    
    # Keep alerts newer than cutoff date
    grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2}" "$alert_file" | while IFS= read -r line; do
        local line_date=$(echo "$line" | cut -d' ' -f1)
        if [[ "$line_date" > "$cutoff_date" ]] || [[ "$line_date" == "$cutoff_date" ]]; then
            echo "$line" >> "$temp_file"
        fi
    done
    
    # Replace original with cleaned version
    local original_size=$(stat -f%z "$alert_file" 2>/dev/null || echo "0")
    mv "$temp_file" "$alert_file"
    local new_size=$(stat -f%z "$alert_file" 2>/dev/null || echo "0")
    
    local space_freed=$((original_size - new_size))
    local space_freed_kb=$((space_freed / 1024))
    
    echo "  Alert file cleaned"
    echo "  Space freed: ${space_freed_kb}KB"
}

# Function to optimize database files
optimize_databases() {
    echo -e "${BLUE}Optimizing database files...${NC}"
    
    local db_dir="$HONEYPOT_DIR/db"
    if [ ! -d "$db_dir" ]; then
        echo -e "${YELLOW}⚠ Database directory not found: $db_dir${NC}"
        return 1
    fi
    
    # Find and optimize SQLite databases
    local databases_optimized=0
    while IFS= read -r -d '' db_file; do
        if command -v sqlite3 >/dev/null 2>&1; then
            echo "  Optimizing: $(basename "$db_file")"
            sqlite3 "$db_file" "VACUUM; REINDEX;" 2>/dev/null || true
            ((databases_optimized++))
        fi
    done < <(find "$db_dir" -name "*.db" -type f -print0 2>/dev/null)
    
    echo "  Databases optimized: $databases_optimized"
}

# Function to clean temporary files
cleanup_temp_files() {
    echo -e "${BLUE}Cleaning up temporary files...${NC}"
    
    local temp_dirs=("$HONEYPOT_DIR/tmp" "$HONEYPOT_DIR/cache" "$HONEYPOT_DIR/temp")
    local files_removed=0
    local space_freed=0
    
    for temp_dir in "${temp_dirs[@]}"; do
        if [ -d "$temp_dir" ]; then
            while IFS= read -r -d '' file; do
                local file_size=$(stat -f%z "$file" 2>/dev/null || echo "0")
                rm "$file"
                ((files_removed++))
                ((space_freed+=file_size))
            done < <(find "$temp_dir" -type f -mtime +1 -print0 2>/dev/null)
        fi
    done
    
    local space_freed_kb=$((space_freed / 1024))
    
    echo "  Temporary files removed: $files_removed"
    echo "  Space freed: ${space_freed_kb}KB"
}

# Function to update file permissions
update_permissions() {
    echo -e "${BLUE}Updating file permissions...${NC}"
    
    if [ ! -d "$HONEYPOT_DIR" ]; then
        echo -e "${RED}✗ Honeypot directory not found${NC}"
        return 1
    fi
    
    # Set secure permissions
    chmod 700 "$HONEYPOT_DIR"
    
    if [ -d "$HONEYPOT_DIR/config" ]; then
        chmod 700 "$HONEYPOT_DIR/config"
        find "$HONEYPOT_DIR/config" -type f -exec chmod 600 {} \;
    fi
    
    if [ -d "$HONEYPOT_DIR/keys" ]; then
        chmod 700 "$HONEYPOT_DIR/keys"
        find "$HONEYPOT_DIR/keys" -type f -exec chmod 400 {} \;
    fi
    
    if [ -d "$LOG_DIR" ]; then
        chmod 750 "$LOG_DIR"
        find "$LOG_DIR" -type f -exec chmod 640 {} \;
    fi
    
    echo "  File permissions updated"
}

# Function to generate cleanup report
generate_report() {
    local report_file="$HONEYPOT_DIR/logs/cleanup-$(date +%Y%m%d_%H%M%S).log"
    
    echo -e "${BLUE}Generating cleanup report...${NC}"
    
    {
        echo "ShadowTrace Sentinel Cleanup Report"
        echo "Generated: $(date)"
        echo "========================================"
        echo
        echo "Configuration:"
        echo "  Log retention: $LOG_RETENTION_DAYS days"
        echo "  Backup retention: $BACKUP_RETENTION_DAYS days"
        echo "  Alert retention: $ALERT_RETENTION_DAYS days"
        echo
        echo "Disk usage after cleanup:"
        if [ -d "$HONEYPOT_DIR" ]; then
            du -sh "$HONEYPOT_DIR"
        fi
        echo
        echo "Directory sizes:"
        if [ -d "$LOG_DIR" ]; then
            echo "  Logs: $(du -sh "$LOG_DIR" | cut -f1)"
        fi
        if [ -d "$BACKUP_DIR" ]; then
            echo "  Backups: $(du -sh "$BACKUP_DIR" | cut -f1)"
        fi
        if [ -d "$HONEYPOT_DIR/db" ]; then
            echo "  Database: $(du -sh "$HONEYPOT_DIR/db" | cut -f1)"
        fi
    } > "$report_file"
    
    echo "  Report saved: $report_file"
}

# Function to display summary
display_summary() {
    echo
    echo -e "${BLUE}=====================================${NC}"
    echo -e "${BLUE}            Cleanup Summary           ${NC}"
    echo -e "${BLUE}=====================================${NC}"
    
    echo "Cleanup completed successfully!"
    echo
    echo "Retention policies:"
    echo "  Logs: $LOG_RETENTION_DAYS days"
    echo "  Backups: $BACKUP_RETENTION_DAYS days"
    echo "  Alerts: $ALERT_RETENTION_DAYS days"
    echo
    
    if [ -d "$HONEYPOT_DIR" ]; then
        echo "Current disk usage:"
        echo "  Total: $(du -sh "$HONEYPOT_DIR" | cut -f1)"
    fi
    
    echo
    echo "Next recommended cleanup: $(date -d '+7 days' '+%Y-%m-%d' 2>/dev/null || date -v+7d '+%Y-%m-%d')"
}

# Main execution
main() {
    echo "Starting ShadowTrace Sentinel cleanup..."
    echo "Timestamp: $(date)"
    echo
    
    # Load configuration
    load_config
    
    echo "Using retention policies:"
    echo "  Logs: $LOG_RETENTION_DAYS days"
    echo "  Backups: $BACKUP_RETENTION_DAYS days"
    echo "  Alerts: $ALERT_RETENTION_DAYS days"
    echo
    
    # Perform cleanup operations
    cleanup_logs
    echo
    
    cleanup_backups
    echo
    
    cleanup_alerts
    echo
    
    optimize_databases
    echo
    
    cleanup_temp_files
    echo
    
    update_permissions
    echo
    
    generate_report
    echo
    
    display_summary
}

# Script help
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    echo "ShadowTrace Sentinel Cleanup Script"
    echo
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help        Show this help message"
    echo "  -f, --force       Skip confirmation prompts"
    echo "  --logs-only       Clean only log files"
    echo "  --backups-only    Clean only backup files"
    echo "  --dry-run         Show what would be cleaned without doing it"
    echo
    echo "This script performs maintenance cleanup on the ShadowTrace Sentinel system."
    echo "It removes old logs, backups, and temporary files according to retention policies."
    exit 0
fi

# Handle force mode
FORCE_MODE=false
if [ "${1:-}" = "-f" ] || [ "${1:-}" = "--force" ]; then
    FORCE_MODE=true
    shift
fi

# Handle specific cleanup modes
if [ "${1:-}" = "--logs-only" ]; then
    load_config
    cleanup_logs
    exit 0
elif [ "${1:-}" = "--backups-only" ]; then
    load_config
    cleanup_backups
    exit 0
elif [ "${1:-}" = "--dry-run" ]; then
    echo "DRY RUN MODE - No files will be actually removed"
    echo
    # Override rm command for dry run
    rm() {
        echo "Would remove: $*"
    }
    export -f rm
fi

# Confirmation prompt (unless force mode)
if [ "$FORCE_MODE" = false ]; then
    echo -e "${YELLOW}This will clean up old files from the ShadowTrace Sentinel system.${NC}"
    echo -e "${YELLOW}Files older than the retention periods will be permanently deleted.${NC}"
    echo
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Cleanup cancelled."
        exit 0
    fi
    echo
fi

# Run main function
main
