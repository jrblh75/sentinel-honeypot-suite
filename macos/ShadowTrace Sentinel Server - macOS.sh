#!/bin/bash
# ShadowTrace Sentinel Honeypot Suite - macOS Installation Script
# Version: 1.0
# Platform: macOS (Intel/Apple Silicon)
# Requires: Administrator privileges

set -euo pipefail

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SENTINEL_HOME="/usr/local/sentinel"
SENTINEL_USER="sentinel"
SENTINEL_SERVICE="com.shadowtrace.sentinel"
LOG_FILE="/var/log/sentinel-install.log"

# Functions
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
    fi
}

check_macos() {
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script is designed for macOS only"
    fi
    
    local version=$(sw_vers -productVersion)
    local major_version=$(echo "$version" | cut -d. -f1)
    
    if [[ $major_version -lt 10 ]]; then
        error "macOS 10.0 or later is required"
    fi
    
    info "Detected macOS $version"
}

install_dependencies() {
    log "Installing dependencies..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install required packages
    brew update
    brew install python3 postgresql redis git openssl
    
    # Install Python packages
    pip3 install --upgrade pip
    pip3 install virtualenv
}

create_user() {
    log "Creating sentinel user..."
    
    if ! id "$SENTINEL_USER" &>/dev/null; then
        # Create user account
        dscl . -create /Users/$SENTINEL_USER
        dscl . -create /Users/$SENTINEL_USER UserShell /bin/bash
        dscl . -create /Users/$SENTINEL_USER RealName "Sentinel Service User"
        dscl . -create /Users/$SENTINEL_USER UniqueID 500
        dscl . -create /Users/$SENTINEL_USER PrimaryGroupID 20
        dscl . -create /Users/$SENTINEL_USER NFSHomeDirectory $SENTINEL_HOME
        
        info "Created user: $SENTINEL_USER"
    else
        info "User $SENTINEL_USER already exists"
    fi
}

create_directories() {
    log "Creating directory structure..."
    
    mkdir -p "$SENTINEL_HOME"/{bin,config,logs,data,decoys}
    mkdir -p /var/log/sentinel
    mkdir -p /Library/LaunchDaemons
    
    # Set permissions
    chown -R $SENTINEL_USER:staff "$SENTINEL_HOME"
    chown -R $SENTINEL_USER:staff /var/log/sentinel
    chmod 755 "$SENTINEL_HOME"
    chmod 750 "$SENTINEL_HOME"/config
    chmod 755 "$SENTINEL_HOME"/logs
}

install_honeypot() {
    log "Installing honeypot components..."
    
    # Create Python virtual environment
    python3 -m venv "$SENTINEL_HOME/venv"
    source "$SENTINEL_HOME/venv/bin/activate"
    
    # Install Python dependencies
    cat > "$SENTINEL_HOME/requirements.txt" << 'EOF'
flask==2.3.3
psycopg2-binary==2.9.7
redis==4.6.0
cryptography==41.0.4
paramiko==3.3.1
prometheus-client==0.17.1
psutil==5.9.5
geoip2==4.7.0
requests==2.31.0
python-dotenv==1.0.0
structlog==23.1.0
EOF
    
    pip install -r "$SENTINEL_HOME/requirements.txt"
    
    # Create main application script
    cat > "$SENTINEL_HOME/bin/sentinel.py" << 'EOF'
#!/usr/bin/env python3
"""
ShadowTrace Sentinel Honeypot - Main Application
"""
import os
import sys
import signal
import logging
from datetime import datetime

class SentinelHoneypot:
    def __init__(self):
        self.running = True
        self.setup_logging()
        
    def setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('/var/log/sentinel/sentinel.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger('SentinelHoneypot')
        
    def signal_handler(self, signum, frame):
        self.logger.info(f"Received signal {signum}, shutting down...")
        self.running = False
        
    def start(self):
        signal.signal(signal.SIGTERM, self.signal_handler)
        signal.signal(signal.SIGINT, self.signal_handler)
        
        self.logger.info("ShadowTrace Sentinel Honeypot starting...")
        
        while self.running:
            # Main honeypot logic would go here
            import time
            time.sleep(1)
            
        self.logger.info("ShadowTrace Sentinel Honeypot stopped")

if __name__ == "__main__":
    honeypot = SentinelHoneypot()
    honeypot.start()
EOF
    
    chmod +x "$SENTINEL_HOME/bin/sentinel.py"
    chown $SENTINEL_USER:staff "$SENTINEL_HOME/bin/sentinel.py"
}

create_launch_daemon() {
    log "Creating launch daemon..."
    
    cat > "/Library/LaunchDaemons/$SENTINEL_SERVICE.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SENTINEL_SERVICE</string>
    <key>ProgramArguments</key>
    <array>
        <string>$SENTINEL_HOME/venv/bin/python</string>
        <string>$SENTINEL_HOME/bin/sentinel.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>UserName</key>
    <string>$SENTINEL_USER</string>
    <key>WorkingDirectory</key>
    <string>$SENTINEL_HOME</string>
    <key>StandardOutPath</key>
    <string>/var/log/sentinel/stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/sentinel/stderr.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin</string>
    </dict>
</dict>
</plist>
EOF
    
    chmod 644 "/Library/LaunchDaemons/$SENTINEL_SERVICE.plist"
}

setup_firewall() {
    log "Configuring firewall rules..."
    
    # Enable firewall if not already enabled
    /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
    
    # Allow honeypot services through firewall
    /usr/libexec/ApplicationFirewall/socketfilterfw --add "$SENTINEL_HOME/bin/sentinel.py"
    /usr/libexec/ApplicationFirewall/socketfilterfw --unblockapp "$SENTINEL_HOME/bin/sentinel.py"
    
    info "Firewall configured for honeypot services"
}

create_decoy_data() {
    log "Creating decoy data..."
    
    # Create fake documents
    cat > "$SENTINEL_HOME/decoys/passwords.txt" << 'EOF'
# Important Passwords - DO NOT SHARE
admin:P@ssw0rd123
database:SecretDB2023
backup:BackupKey456
EOF
    
    cat > "$SENTINEL_HOME/decoys/config.ini" << 'EOF'
[Database]
host=localhost
user=admin
password=supersecret
database=production

[API]
key=abc123def456ghi789
secret=very_secret_key_2023
EOF
    
    # Create fake SSH keys
    mkdir -p "$SENTINEL_HOME/decoys/.ssh"
    ssh-keygen -t rsa -b 2048 -f "$SENTINEL_HOME/decoys/.ssh/id_rsa" -N "" -C "decoy@honeypot"
    
    # Set permissions to make files look valuable but accessible
    chmod 600 "$SENTINEL_HOME/decoys/passwords.txt"
    chmod 600 "$SENTINEL_HOME/decoys/.ssh/id_rsa"
    chown -R $SENTINEL_USER:staff "$SENTINEL_HOME/decoys"
}

start_services() {
    log "Starting services..."
    
    # Load and start the launch daemon
    launchctl load "/Library/LaunchDaemons/$SENTINEL_SERVICE.plist"
    launchctl start "$SENTINEL_SERVICE"
    
    # Verify service is running
    sleep 3
    if launchctl list | grep -q "$SENTINEL_SERVICE"; then
        log "ShadowTrace Sentinel service started successfully"
    else
        error "Failed to start ShadowTrace Sentinel service"
    fi
}

print_summary() {
    log "Installation completed successfully!"
    echo
    echo -e "${GREEN}=== ShadowTrace Sentinel Installation Summary ===${NC}"
    echo -e "Installation directory: ${BLUE}$SENTINEL_HOME${NC}"
    echo -e "Service user: ${BLUE}$SENTINEL_USER${NC}"
    echo -e "Log files: ${BLUE}/var/log/sentinel/${NC}"
    echo -e "Service name: ${BLUE}$SENTINEL_SERVICE${NC}"
    echo
    echo -e "${YELLOW}Management Commands:${NC}"
    echo -e "  Start service:   ${BLUE}sudo launchctl start $SENTINEL_SERVICE${NC}"
    echo -e "  Stop service:    ${BLUE}sudo launchctl stop $SENTINEL_SERVICE${NC}"
    echo -e "  Check status:    ${BLUE}sudo launchctl list | grep sentinel${NC}"
    echo -e "  View logs:       ${BLUE}tail -f /var/log/sentinel/sentinel.log${NC}"
    echo
    echo -e "${GREEN}Installation complete!${NC}"
}

main() {
    log "Starting ShadowTrace Sentinel installation for macOS..."
    
    check_root
    check_macos
    install_dependencies
    create_user
    create_directories
    install_honeypot
    create_launch_daemon
    setup_firewall
    create_decoy_data
    start_services
    print_summary
}

# Run main function
main "$@"