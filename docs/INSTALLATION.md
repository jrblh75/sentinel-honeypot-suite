# ShadowTrace Sentinel Installation Guide

## System Requirements

### Minimum Requirements
- **Windows**: Windows 10/11 or Windows Server 2019+
- **Linux**: Ubuntu 18.04+, Debian 10+, or RHEL 8+
- **macOS**: macOS 10.15 (Catalina) or later
- **RAM**: 512MB available memory
- **Storage**: 100MB free disk space
- **Network**: Internet connectivity for IP detection and alerts

### Recommended Requirements
- **RAM**: 1GB+ available memory
- **Storage**: 1GB+ free disk space
- **Network**: Stable internet connection with HTTPS access
- **Permissions**: Administrator/root access

## Pre-Installation Checklist

### All Platforms
- [ ] Verify administrator/root privileges
- [ ] Ensure network connectivity
- [ ] Backup existing system configurations
- [ ] Review security policies and compliance requirements
- [ ] Prepare alert email configuration (optional)

### Windows Specific
- [ ] PowerShell 5.1 or later installed
- [ ] Windows Defender exclusions configured (if needed)
- [ ] DPAPI services enabled

### Linux Specific
- [ ] Package manager available (apt, yum, dnf)
- [ ] GPG installed and configured
- [ ] Systemd services available (for auto-start)

### macOS Specific
- [ ] Xcode Command Line Tools installed
- [ ] Keychain access enabled
- [ ] System Integrity Protection (SIP) considerations

## Installation Process

### Windows Installation

1. **Download and Prepare**
   ```powershell
   # Navigate to the Windows directory
   cd sentinel-honeypot-suite\windows
   
   # Check PowerShell execution policy
   Get-ExecutionPolicy
   
   # If needed, temporarily allow script execution
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **Run Installation**
   ```powershell
   # Execute as Administrator
   .\install.ps1
   ```

3. **Post-Installation Verification**
   ```powershell
   # Check if honeypot directory was created
   Test-Path "$env:USERPROFILE\.honeypot"
   
   # Verify encrypted data files
   Get-ChildItem "$env:USERPROFILE\.honeypot" -Force
   ```

### Linux Installation (Ubuntu/Debian)

1. **System Preparation**
   ```bash
   # Update package repositories
   sudo apt update
   
   # Install required dependencies
   sudo apt install -y gpg curl wget
   
   # Navigate to Linux directory
   cd sentinel-honeypot-suite/linux
   ```

2. **Script Execution**
   ```bash
   # Make script executable
   chmod +x "ShadowTrace Sentinel Server - Ubuntu.Debian.sh"
   
   # Run installation with sudo
   sudo ./"ShadowTrace Sentinel Server - Ubuntu.Debian.sh"
   ```

3. **Service Configuration**
   ```bash
   # Enable auto-start (if systemd service was created)
   sudo systemctl enable shadowtrace-sentinel
   
   # Start the service
   sudo systemctl start shadowtrace-sentinel
   
   # Check service status
   sudo systemctl status shadowtrace-sentinel
   ```

### macOS Installation

1. **Prerequisites Setup**
   ```bash
   # Install Xcode Command Line Tools (if not present)
   xcode-select --install
   
   # Navigate to macOS directory
   cd sentinel-honeypot-suite/macos
   ```

2. **Installation Execution**
   ```bash
   # Make script executable
   chmod +x "ShadowTrace Sentinel Server - macOS.sh"
   
   # Run with administrator privileges
   sudo ./"ShadowTrace Sentinel Server - macOS.sh"
   ```

3. **Keychain Configuration**
   ```bash
   # Verify keychain integration
   security list-keychains
   
   # Check for sentinel entries (will be hidden)
   # This should not show sensitive data, only verify structure
   ls -la ~/.honeypot/
   ```

## Configuration

### Initial Configuration

After installation, configure the honeypot system:

1. **Edit Configuration Files**
   ```bash
   # Navigate to configuration directory
   cd ~/.honeypot/config/
   
   # Edit main configuration
   nano sentinel.conf
   ```

2. **Set Alert Parameters**
   ```bash
   # Configure email alerts
   nano alerts.conf
   
   # Add your notification email
   ALERT_EMAIL="security@yourcompany.com"
   WEBHOOK_URL="https://your-webhook-endpoint.com"
   ```

3. **Customize Decoy Data**
   ```bash
   # Edit decoy content (this will be encrypted)
   nano decoy_templates/financial_data.txt
   nano decoy_templates/credentials.txt
   nano decoy_templates/intellectual_property.txt
   ```

### Advanced Configuration

#### Network Settings
```bash
# Configure network monitoring
MONITOR_INTERFACES="eth0,wlan0"
MONITOR_PORTS="22,80,443,3389"
ALERT_ON_SCAN="true"
```

#### Logging Configuration
```bash
# Set log levels and retention
LOG_LEVEL="INFO"
LOG_RETENTION_DAYS="30"
MAX_LOG_SIZE="100MB"
SYSLOG_ENABLED="true"
```

#### Stealth Settings
```bash
# Configure stealth parameters
PROCESS_NAME_MASK="svchost"
HIDE_NETWORK_CONNECTIONS="true"
RANDOMIZE_TIMING="true"
ANTI_FORENSICS="enabled"
```

## Verification

### Test Installation
```bash
# Run built-in diagnostics
~/.honeypot/bin/sentinel-test

# Check system integration
~/.honeypot/bin/sentinel-status

# Verify alert system
~/.honeypot/bin/test-alerts
```

### Security Validation
```bash
# Verify file permissions
ls -la ~/.honeypot/

# Check encryption status
~/.honeypot/bin/verify-encryption

# Test stealth features
~/.honeypot/bin/stealth-check
```

## Troubleshooting

### Common Issues

#### Permission Errors
```bash
# Fix file permissions
chmod -R 700 ~/.honeypot/
chown -R $USER:$USER ~/.honeypot/
```

#### Service Start Failures
```bash
# Check system logs
journalctl -u shadowtrace-sentinel -f

# Verify dependencies
~/.honeypot/bin/dependency-check
```

#### Network Connectivity Issues
```bash
# Test external connectivity
curl -s https://api.ipify.org

# Check firewall rules
sudo ufw status
```

### Log Analysis
```bash
# View installation logs
cat ~/.honeypot/logs/install.log

# Check runtime logs
tail -f ~/.honeypot/logs/sentinel.log

# Review alert history
cat ~/.honeypot/logs/alerts.log
```

## Uninstallation

### Safe Removal
```bash
# Stop services
sudo systemctl stop shadowtrace-sentinel
sudo systemctl disable shadowtrace-sentinel

# Run cleanup script
~/.honeypot/bin/uninstall.sh

# Verify complete removal
ls -la ~/.honeypot/  # Should not exist
```

### Manual Cleanup (if needed)
```bash
# Remove all honeypot files
rm -rf ~/.honeypot/

# Remove system service files
sudo rm -f /etc/systemd/system/shadowtrace-sentinel.service

# Remove cron jobs
crontab -e  # Remove any sentinel entries
```

---

**Note**: Always ensure proper authorization before deploying honeypot systems in any environment. Consult with legal and security teams regarding compliance with organizational policies and applicable laws.
