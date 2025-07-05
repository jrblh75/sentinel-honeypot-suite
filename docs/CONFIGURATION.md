# ShadowTrace Sentinel Configuration Guide

## 🔧 Configuration Overview

This guide covers all configuration options for ShadowTrace Sentinel, from basic setup to advanced enterprise configurations.

## 📁 Configuration File Locations

### Default Locations

- **Windows**: `%USERPROFILE%\.honeypot\config\`
- **Linux**: `~/.honeypot/config/`
- **macOS**: `~/.honeypot/config/`

### Configuration Files

```text
~/.honeypot/config/
├── sentinel.conf           # Main configuration
├── alerts.conf            # Alert settings
├── encryption.conf         # Encryption parameters
├── logging.conf           # Log configuration
├── network.conf           # Network settings
└── platforms/             # Platform-specific configs
    ├── windows.conf
    ├── linux.conf
    └── macos.conf
```

## ⚙️ Main Configuration (sentinel.conf)

### Basic Configuration

```ini
[general]
# Honeypot identification
honeypot_id = sentinel-001
deployment_environment = production
version = 1.0

# Operation mode
stealth_mode = true
debug_mode = false
verbose_logging = false

# Performance settings
max_concurrent_connections = 100
connection_timeout = 30
cleanup_interval = 3600

[decoy_data]
# Decoy file settings
create_fake_files = true
fake_file_count = 25
fake_file_size_min = 1024
fake_file_size_max = 10485760

# Decoy content types
include_documents = true
include_databases = true
include_credentials = true
include_source_code = true

[monitoring]
# File system monitoring
monitor_file_access = true
monitor_file_creation = true
monitor_file_deletion = true
monitor_file_modification = true

# Process monitoring
monitor_process_creation = true
monitor_network_connections = true
monitor_registry_access = true  # Windows only

# System monitoring
monitor_login_attempts = true
monitor_privilege_escalation = true
monitor_service_changes = true
```

### Advanced Configuration

```ini
[detection]
# Detection sensitivity
sensitivity_level = medium  # low, medium, high, paranoid
false_positive_threshold = 0.1
detection_window = 300

# Signature-based detection
enable_signature_detection = true
signature_update_interval = 86400
custom_signatures_path = ~/.honeypot/signatures/

# Behavioral detection
enable_behavioral_detection = true
baseline_learning_period = 604800  # 7 days
anomaly_threshold = 2.5

[network]
# Network interface configuration
bind_interface = all
listen_ports = 22,80,443,3389,5432
enable_port_knocking = false
port_knock_sequence = 1234,5678,9012

# Traffic analysis
enable_traffic_analysis = true
capture_full_packets = false
packet_capture_size = 1024
max_capture_files = 100

[stealth]
# Anti-detection measures
hide_processes = true
obfuscate_process_names = true
mimic_legitimate_services = true
randomize_response_timing = true

# File hiding
hide_honeypot_files = true
use_alternate_data_streams = true  # Windows only
mimic_system_files = true
```

## 🚨 Alert Configuration (alerts.conf)

### Email Alerts

```ini
[email]
enabled = true
smtp_server = smtp.company.com
smtp_port = 587
smtp_username = alerts@company.com
smtp_password = ${SMTP_PASSWORD}
smtp_use_tls = true

# Recipients
admin_email = admin@company.com
security_team = security@company.com
emergency_contact = emergency@company.com

# Alert formatting
subject_prefix = [HONEYPOT ALERT]
include_system_info = true
include_attack_details = true
attach_evidence = true

[alert_rules]
# Alert thresholds
immediate_alert_events = file_access,credential_theft,privilege_escalation
hourly_summary_events = port_scan,login_attempt
daily_summary_events = reconnaissance

# Rate limiting
max_alerts_per_hour = 10
max_alerts_per_day = 100
alert_cooldown_period = 300
```

### Webhook Integration

```ini
[webhooks]
enabled = true
primary_webhook = https://hooks.slack.com/services/YOUR/WEBHOOK/URL
backup_webhook = https://api.pagerduty.com/integration/YOUR/KEY

# Webhook formatting
format = json
include_metadata = true
include_geolocation = true
include_threat_intelligence = true

# Retry configuration
max_retries = 3
retry_delay = 5
timeout = 30

[integrations]
# SIEM integration
splunk_enabled = false
splunk_hec_url = https://splunk.company.com:8088
splunk_token = ${SPLUNK_TOKEN}

# Security tools
crowdstrike_enabled = false
sentinelone_enabled = false
carbon_black_enabled = false
```

## 🔐 Encryption Configuration (encryption.conf)

### Encryption Settings

```ini
[encryption]
# Default encryption method per platform
windows_method = dpapi
linux_method = gpg
macos_method = keychain

# Key management
auto_rotate_keys = true
key_rotation_interval = 2592000  # 30 days
backup_old_keys = true
key_backup_location = ~/.honeypot/keys/backup/

[gpg]
# GPG settings for Linux
gpg_key_id = YOUR_GPG_KEY_ID
gpg_passphrase = ${GPG_PASSPHRASE}
gpg_armor = true
gpg_cipher_algo = AES256

[dpapi]
# Windows DPAPI settings
use_machine_store = false
entropy_source = random
additional_entropy = ${DPAPI_ENTROPY}

[keychain]
# macOS Keychain settings
keychain_name = shadowtrace-sentinel
use_secure_enclave = true
access_group = com.shadowtrace.sentinel
```

## 📊 Logging Configuration (logging.conf)

### Log Settings

```ini
[logging]
# Log levels: DEBUG, INFO, WARN, ERROR, CRITICAL
default_log_level = INFO
console_log_level = WARN
file_log_level = DEBUG

# Log file settings
log_directory = ~/.honeypot/logs/
max_log_file_size = 100MB
max_log_files = 10
log_rotation = daily

# Log formats
timestamp_format = %Y-%m-%d %H:%M:%S
include_thread_id = true
include_process_id = true
include_hostname = true

[audit_logging]
# Audit trail configuration
enable_audit_logging = true
audit_log_file = audit.log
audit_all_events = false
audit_sensitive_events = true

# Tamper protection
enable_log_signing = true
signing_key = ~/.honeypot/keys/log-signing.key
verify_on_startup = true

[syslog]
# Syslog integration
enable_syslog = true
syslog_server = syslog.company.com
syslog_port = 514
syslog_protocol = UDP
syslog_facility = LOG_LOCAL0
```

## 🌐 Network Configuration (network.conf)

### Network Settings

```ini
[interfaces]
# Network interface configuration
primary_interface = eth0
backup_interface = eth1
virtual_interfaces = honeypot0,honeypot1

# IP configuration
bind_all_interfaces = false
ipv4_enabled = true
ipv6_enabled = false
dynamic_ip_assignment = false

[services]
# Service emulation
ssh_enabled = true
ssh_port = 22
ssh_banner = "OpenSSH_8.0"

http_enabled = true
http_port = 80
http_server_header = "Apache/2.4.41"

https_enabled = true
https_port = 443
ssl_certificate = ~/.honeypot/certs/server.crt
ssl_private_key = ~/.honeypot/certs/server.key

ftp_enabled = false
rdp_enabled = false
telnet_enabled = false

[firewall]
# Firewall integration
manage_firewall_rules = true
allow_legitimate_traffic = true
block_known_bad_ips = true
geo_blocking_enabled = false
blocked_countries = CN,RU,KP
```

## 🖥️ Platform-Specific Configuration

### Windows Configuration (platforms/windows.conf)

```ini
[windows]
# Windows-specific settings
service_name = "Windows Security Health Service"
service_display_name = "Maintains system security health"
run_as_service = true
service_startup = automatic

# Registry integration
create_registry_decoys = true
registry_key_base = HKLM\SOFTWARE\Microsoft\
hide_in_registry = true

# Windows Defender integration
exclude_from_defender = true
defender_exclusion_path = C:\ProgramData\Microsoft\Windows Defender\

# Event log integration
write_to_event_log = true
event_log_source = "ShadowTrace Sentinel"
event_log_name = "Security"

[wmi]
# WMI monitoring
enable_wmi_monitoring = true
wmi_query_interval = 60
monitor_process_creation = true
monitor_file_operations = true
```

### Linux Configuration (platforms/linux.conf)

```ini
[linux]
# Linux-specific settings
daemon_name = shadowtrace-sentinel
pid_file = /var/run/shadowtrace-sentinel.pid
run_as_user = sentinel
run_as_group = sentinel

# Systemd integration
create_systemd_service = true
systemd_unit_file = /etc/systemd/system/shadowtrace-sentinel.service
enable_on_boot = true

# File system monitoring
use_inotify = true
inotify_watch_paths = /home,/var,/tmp,/opt
max_inotify_watches = 8192

# Capabilities
required_capabilities = CAP_NET_BIND_SERVICE,CAP_SYS_ADMIN
drop_privileges = true

[selinux]
# SELinux integration
selinux_enabled = auto
selinux_context = unconfined_u:system_r:unconfined_t:s0
create_selinux_policy = true
```

### macOS Configuration (platforms/macos.conf)

```ini
[macos]
# macOS-specific settings
launch_daemon_name = com.shadowtrace.sentinel
launch_daemon_path = /Library/LaunchDaemons/
run_at_load = true
keep_alive = true

# Sandbox configuration
enable_sandboxing = true
sandbox_profile = shadowtrace-sentinel.sb
allow_network_access = true
allow_file_system_access = limited

# Code signing
require_code_signing = true
signing_identity = "Developer ID Application: Your Company"
notarization_required = true

# Gatekeeper integration
bypass_gatekeeper = false
quarantine_attributes = false

[endpoint_security]
# Endpoint Security framework
use_endpoint_security = true
monitor_process_events = true
monitor_file_events = true
monitor_network_events = true
```

## 🔄 Configuration Management

### Environment Variables

```bash
# Required environment variables
export SENTINEL_EMAIL="alerts@company.com"
export SENTINEL_WEBHOOK="https://your-webhook-url.com"
export SENTINEL_LOG_LEVEL="INFO"

# Optional security variables
export SMTP_PASSWORD="your-smtp-password"
export GPG_PASSPHRASE="your-gpg-passphrase"
export DPAPI_ENTROPY="random-entropy-string"
export SPLUNK_TOKEN="your-splunk-token"
```

### Configuration Validation

```bash
# Validate configuration
./scripts/validate-config.sh

# Test configuration changes
./scripts/test-config.sh --dry-run

# Apply configuration
./scripts/apply-config.sh --restart-services
```

### Configuration Backup

```bash
# Backup current configuration
./scripts/backup-config.sh --output-dir ~/config-backups/

# Restore configuration
./scripts/restore-config.sh --backup-file config-backup-20250704.tar.gz
```

## 🚀 Quick Configuration Templates

### Development Environment

```bash
# Development template
cp templates/development.conf ~/.honeypot/config/sentinel.conf
sed -i 's/stealth_mode = true/stealth_mode = false/' ~/.honeypot/config/sentinel.conf
sed -i 's/debug_mode = false/debug_mode = true/' ~/.honeypot/config/sentinel.conf
```

### Production Environment

```bash
# Production template
cp templates/production.conf ~/.honeypot/config/sentinel.conf
./scripts/generate-certificates.sh
./scripts/setup-encryption.sh --strong
```

### High-Security Environment

```bash
# High-security template
cp templates/high-security.conf ~/.honeypot/config/sentinel.conf
sed -i 's/sensitivity_level = medium/sensitivity_level = paranoid/' ~/.honeypot/config/sentinel.conf
./scripts/enable-all-monitoring.sh
```

---

**Document Version**: 1.0  
**Last Updated**: July 4, 2025  
**Review Date**: October 4, 2025
