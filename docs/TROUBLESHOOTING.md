# ShadowTrace Sentinel Troubleshooting Guide

## 🔧 Common Issues and Solutions

This guide covers common problems, diagnostic procedures, and solutions for ShadowTrace Sentinel.

## 🚨 Quick Diagnostics

### System Health Check

```bash
# Run comprehensive health check
./scripts/health-check.sh --verbose

# Expected output:
✅ Configuration files valid
✅ Required permissions present  
✅ Network connectivity working
✅ Log files accessible
✅ Alert system functional
⚠️  Disk space: 85% (warning threshold)
❌ Service not responding on port 22
```

### Service Status

```bash
# Check service status across platforms
# Linux/macOS
systemctl status shadowtrace-sentinel
ps aux | grep shadowtrace

# Windows
Get-Service "ShadowTrace Sentinel"
Get-Process | Where-Object {$_.Name -like "*shadowtrace*"}
```

## 📋 Installation Issues

### Problem: Installation Fails with Permission Errors

**Symptoms:**
```
Error: Permission denied
Unable to create directory: ~/.honeypot/
Failed to register service
```

**Solution:**
```bash
# Ensure proper permissions
sudo chown -R $USER:$USER ~/.honeypot/
chmod -R 755 ~/.honeypot/

# For service installation (Linux)
sudo ./install.sh

# For Windows (Run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
.\install.ps1
```

### Problem: Dependencies Missing

**Symptoms:**
```
Command not found: gpg
Python module not found: cryptography
Package 'build-essential' not installed
```

**Solution:**
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install build-essential python3-pip gpg curl

# CentOS/RHEL
sudo yum groupinstall "Development Tools"
sudo yum install python3-pip gnupg2 curl

# macOS
brew install python3 gnupg curl
xcode-select --install

# Windows (PowerShell as Administrator)
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
choco install python3 git
```

### Problem: Firewall Blocking Installation

**Symptoms:**
```
Connection timeout during download
Unable to reach update servers
Package download failed
```

**Solution:**
```bash
# Check firewall status
# Linux
sudo ufw status
sudo iptables -L

# Windows
netsh advfirewall show allprofiles

# Temporarily disable for installation
sudo ufw disable  # Re-enable after installation
# Windows: Disable Windows Defender Firewall temporarily

# Configure proxy if needed
export http_proxy=http://proxy.company.com:8080
export https_proxy=http://proxy.company.com:8080
```

## ⚙️ Configuration Issues

### Problem: Configuration File Not Found

**Symptoms:**
```
Error: Configuration file not found at ~/.honeypot/config/sentinel.conf
Using default configuration
Failed to load custom settings
```

**Solution:**
```bash
# Check configuration directory
ls -la ~/.honeypot/config/

# Create missing configuration
mkdir -p ~/.honeypot/config/
cp /opt/shadowtrace/templates/default.conf ~/.honeypot/config/sentinel.conf

# Verify configuration syntax
./scripts/validate-config.sh
```

### Problem: Invalid Configuration Values

**Symptoms:**
```
Warning: Invalid log level 'VERBOSE'
Error: Port 22 already in use
Configuration validation failed
```

**Solution:**
```bash
# Check configuration syntax
./scripts/validate-config.sh --strict

# Fix common issues
sed -i 's/log_level = VERBOSE/log_level = DEBUG/' ~/.honeypot/config/sentinel.conf

# Check port availability
netstat -tulpn | grep :22
lsof -i :22

# Use alternative ports if needed
sed -i 's/ssh_port = 22/ssh_port = 2222/' ~/.honeypot/config/sentinel.conf
```

### Problem: Encryption Setup Fails

**Symptoms:**
```
GPG key generation failed
DPAPI encryption not available
Keychain access denied
```

**Solution:**
```bash
# Linux: GPG issues
gpg --gen-key
gpg --list-keys
export GPG_TTY=$(tty)

# Windows: DPAPI issues
# Run as the service account user
runas /user:DOMAIN\ServiceAccount cmd

# macOS: Keychain issues
security unlock-keychain ~/Library/Keychains/login.keychain
security set-keychain-settings -t 3600 ~/Library/Keychains/login.keychain
```

## 🔐 Service Issues

### Problem: Service Won't Start

**Symptoms:**
```
Failed to start shadowtrace-sentinel.service
Service start timeout
Process terminated unexpectedly
```

**Diagnostic Steps:**
```bash
# Check service logs
journalctl -u shadowtrace-sentinel -f
tail -f ~/.honeypot/logs/service.log

# Check for port conflicts
netstat -tulpn | grep -E ':(22|80|443)'

# Verify configuration
./scripts/validate-config.sh

# Check file permissions
ls -la ~/.honeypot/
ls -la /opt/shadowtrace/
```

**Solutions:**
```bash
# Fix common service issues
# 1. Port conflicts
sudo systemctl stop ssh  # If using port 22
sudo fuser -k 22/tcp     # Kill processes using port 22

# 2. Permission issues
sudo chown -R sentinel:sentinel ~/.honeypot/
sudo chmod +x /opt/shadowtrace/bin/shadowtrace-sentinel

# 3. Missing dependencies
sudo apt install python3-systemd  # Linux
pip3 install -r requirements.txt

# 4. Service file corruption
sudo systemctl daemon-reload
sudo systemctl reset-failed shadowtrace-sentinel
```

### Problem: Service Runs But Not Responding

**Symptoms:**
```
Service shows as active but no responses
Connections timeout
No log entries generated
```

**Diagnostic Steps:**
```bash
# Test network connectivity
telnet localhost 22
nc -zv localhost 22

# Check process details
ps aux | grep shadowtrace
lsof -p $(pgrep shadowtrace)

# Monitor system calls
strace -p $(pgrep shadowtrace)
```

**Solutions:**
```bash
# Restart with debug mode
sudo systemctl stop shadowtrace-sentinel
sudo /opt/shadowtrace/bin/shadowtrace-sentinel --debug --foreground

# Check bind addresses
netstat -tulpn | grep shadowtrace
ss -tulpn | grep shadowtrace

# Update configuration
sed -i 's/bind_interface = eth0/bind_interface = all/' ~/.honeypot/config/sentinel.conf
```

## 📊 Monitoring and Alerting Issues

### Problem: No Alerts Received

**Symptoms:**
```
File access detected but no alerts sent
Email notifications not working
Webhook calls failing
```

**Diagnostic Steps:**
```bash
# Test alert system
./scripts/test-alerts.sh --email --webhook

# Check email configuration
./scripts/test-email.sh --to admin@company.com --subject "Test Alert"

# Check webhook connectivity
curl -X POST $WEBHOOK_URL -d '{"test": "alert"}'

# Review alert logs
tail -f ~/.honeypot/logs/alerts.log
```

**Solutions:**
```bash
# Fix email issues
# 1. SMTP authentication
echo "Test email" | mail -s "Test" -S smtp-auth=login -S smtp-auth-user=user@domain.com admin@company.com

# 2. Firewall/proxy issues
telnet smtp.company.com 587
curl -v --proxy proxy.company.com:8080 $WEBHOOK_URL

# 3. Configuration issues
./scripts/validate-alert-config.sh
```

### Problem: Too Many False Positives

**Symptoms:**
```
Alert storm: 500+ alerts in 1 hour
Legitimate traffic triggering alerts
System performance degraded
```

**Solutions:**
```bash
# Adjust sensitivity settings
sed -i 's/sensitivity_level = high/sensitivity_level = medium/' ~/.honeypot/config/sentinel.conf

# Add whitelist entries
cat >> ~/.honeypot/config/whitelist.conf << 'EOF'
# Legitimate scanning tools
192.168.1.0/24
scanner.company.com
monitoring.domain.com
EOF

# Implement rate limiting
sed -i 's/max_alerts_per_hour = 100/max_alerts_per_hour = 10/' ~/.honeypot/config/alerts.conf

# Review and tune rules
./scripts/tune-detection-rules.sh --reduce-false-positives
```

## 💾 Log and Storage Issues

### Problem: Log Files Growing Too Large

**Symptoms:**
```
Disk space: 95% full
Log files > 10GB
System performance slow
Log rotation not working
```

**Solutions:**
```bash
# Immediate space recovery
./scripts/compress-old-logs.sh --older-than 7d
./scripts/cleanup-logs.sh --keep-recent 1000

# Fix log rotation
# Linux: logrotate
cat > /etc/logrotate.d/shadowtrace << 'EOF'
~/.honeypot/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    postrotate
        systemctl reload shadowtrace-sentinel
    endscript
}
EOF

# Manual log rotation
./scripts/rotate-logs.sh --force
```

### Problem: Logs Not Being Written

**Symptoms:**
```
Log files empty or not updating
No recent entries in log files
Debug information missing
```

**Diagnostic Steps:**
```bash
# Check log directory permissions
ls -la ~/.honeypot/logs/
stat ~/.honeypot/logs/sentinel.log

# Check disk space
df -h ~/.honeypot/
lsof +L1  # Check for deleted files still open

# Monitor log writes
tail -f ~/.honeypot/logs/sentinel.log &
./scripts/generate-test-event.sh
```

**Solutions:**
```bash
# Fix permissions
sudo chown -R $USER:$USER ~/.honeypot/logs/
chmod 644 ~/.honeypot/logs/*.log

# Recreate log files
./scripts/recreate-log-files.sh

# Restart logging service
sudo systemctl restart rsyslog
systemctl restart shadowtrace-sentinel
```

## 🌐 Network and Connectivity Issues

### Problem: Cannot Bind to Ports

**Symptoms:**
```
Error: Address already in use
Failed to bind to 0.0.0.0:22
Permission denied on port 80
```

**Solutions:**
```bash
# Check port usage
sudo netstat -tulpn | grep :22
sudo lsof -i :22

# Kill conflicting processes
sudo fuser -k 22/tcp

# Use alternative ports
# Edit configuration to use ports > 1024
sed -i 's/ssh_port = 22/ssh_port = 2222/' ~/.honeypot/config/sentinel.conf

# Add capability for low ports (Linux)
sudo setcap 'cap_net_bind_service=+ep' /opt/shadowtrace/bin/shadowtrace-sentinel
```

### Problem: Network Traffic Not Captured

**Symptoms:**
```
No incoming connections logged
Packet capture files empty
Network monitoring not working
```

**Solutions:**
```bash
# Check network interface
ip addr show
ifconfig -a

# Test port accessibility
nmap -p 22,80,443 localhost
nc -l 2222  # Test listener

# Fix firewall rules
# Linux
sudo ufw allow 22/tcp
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# Windows
netsh advfirewall firewall add rule name="ShadowTrace SSH" dir=in action=allow protocol=TCP localport=22
```

## 🔍 Performance Issues

### Problem: High CPU/Memory Usage

**Symptoms:**
```
CPU usage consistently > 80%
Memory usage > 4GB
System becomes unresponsive
```

**Diagnostic Steps:**
```bash
# Monitor resource usage
top -p $(pgrep shadowtrace)
htop
vmstat 1 10

# Check for memory leaks
valgrind --leak-check=full /opt/shadowtrace/bin/shadowtrace-sentinel

# Profile CPU usage
perf record -p $(pgrep shadowtrace)
perf report
```

**Solutions:**
```bash
# Optimize configuration
sed -i 's/max_concurrent_connections = 1000/max_concurrent_connections = 100/' ~/.honeypot/config/sentinel.conf

# Enable connection limits
echo "net.core.somaxconn = 128" >> /etc/sysctl.conf
sysctl -p

# Reduce monitoring frequency
sed -i 's/monitor_interval = 1/monitor_interval = 5/' ~/.honeypot/config/sentinel.conf

# Add memory limits (systemd)
sudo systemctl edit shadowtrace-sentinel
# Add:
# [Service]
# MemoryLimit=512M
```

## 🔄 Update and Maintenance Issues

### Problem: Update Fails

**Symptoms:**
```
Update download failed
Signature verification failed
Configuration backup failed
Service restart failed after update
```

**Solutions:**
```bash
# Manual update process
./scripts/backup-config.sh
./scripts/stop-service.sh
./scripts/download-update.sh --verify-signature
./scripts/install-update.sh --preserve-config
./scripts/start-service.sh

# Rollback if needed
./scripts/rollback-update.sh --to-version 1.0.0
./scripts/restore-config.sh --backup latest
```

## 📞 Support and Escalation

### When to Escalate

**Level 1 - Operations Team**
- Service restart issues
- Basic configuration problems
- Log file issues
- Performance alerts

**Level 2 - Security Team**
- Alert system failures
- Potential security incidents
- False positive analysis
- Configuration security review

**Level 3 - Development Team**
- Software bugs
- Feature requests
- Integration issues
- Custom modifications

### Support Information to Collect

```bash
# Generate support bundle
./scripts/generate-support-bundle.sh --include-logs --include-config --sanitize

# Support bundle includes:
# - System information
# - Configuration files (sanitized)
# - Recent log files
# - Performance metrics
# - Network configuration
# - Error messages and stack traces
```

### Emergency Procedures

**Security Incident Response**
1. Immediately isolate affected systems
2. Preserve all log files and evidence
3. Contact security team: security@company.com
4. Document timeline and affected systems
5. Follow incident response procedures

**System Failure Response**
1. Attempt service restart
2. Check system resources and logs
3. Contact operations team if restart fails
4. Escalate to development team for software issues

---

**Document Version**: 1.0  
**Last Updated**: July 4, 2025  
**Review Date**: October 4, 2025
