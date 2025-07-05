# ShadowTrace Sentinel Monitoring Guide

## 📊 Monitoring Overview

This guide covers comprehensive monitoring, alerting, and analytics for ShadowTrace Sentinel honeypot deployments.

## 🎯 Monitoring Objectives

### Primary Goals

- **Real-time Threat Detection**: Immediate identification of intrusion attempts
- **Performance Monitoring**: Ensure honeypot systems operate optimally
- **Compliance Reporting**: Meet security and regulatory requirements
- **Trend Analysis**: Identify attack patterns and emerging threats

### Key Metrics

- **Security Metrics**: Attack frequency, source analysis, success rates
- **Performance Metrics**: Response times, resource utilization, availability
- **Operational Metrics**: Log volumes, alert rates, false positives

## 🔍 Real-time Monitoring

### System Status Dashboard

```bash
# Real-time status monitoring
./scripts/status.sh --real-time --refresh 5

# Output example:
┌─────────────────────────────────────────────────────────┐
│               ShadowTrace Sentinel Status               │
├─────────────────────────────────────────────────────────┤
│ Status: ACTIVE          Uptime: 72h 45m 12s            │
│ Alerts: 3 (Last: 2m ago) False Positives: 0.8%         │
│ Active Connections: 12   Total Attempts: 1,247         │
│ CPU: 2.1%   Memory: 45MB   Disk: 12GB                  │
└─────────────────────────────────────────────────────────┘
```

### Live Event Stream

```bash
# Monitor events in real-time
tail -f ~/.honeypot/logs/events.log | ./scripts/format-events.sh

# Example output:
[2025-07-04 14:30:15] ALERT: File access detected
  Source IP: 192.168.1.100
  File: /home/user/documents/confidential.docx
  Action: READ
  Threat Level: HIGH

[2025-07-04 14:30:18] INFO: Login attempt
  Source IP: 192.168.1.100
  Username: admin
  Password: password123
  Result: FAILED
```

### Process Monitoring

```bash
# Monitor honeypot processes
ps aux | grep shadowtrace
systemctl status shadowtrace-sentinel
journalctl -u shadowtrace-sentinel -f
```

## 📈 Performance Monitoring

### Resource Utilization

```bash
# CPU and Memory monitoring
./scripts/monitor-resources.sh --interval 60 --output metrics.log

# Disk space monitoring
df -h ~/.honeypot/
du -sh ~/.honeypot/logs/

# Network utilization
./scripts/monitor-network.sh --interface eth0 --duration 3600
```

### Performance Metrics Collection

```bash
# Collect performance metrics
cat > /etc/cron.d/sentinel-metrics << 'EOF'
# Collect metrics every 5 minutes
*/5 * * * * sentinel /opt/shadowtrace/scripts/collect-metrics.sh
# Generate hourly performance report
0 * * * * sentinel /opt/shadowtrace/scripts/perf-report.sh --hourly
EOF
```

### Performance Thresholds

```ini
# performance-thresholds.conf
[cpu]
warning_threshold = 70
critical_threshold = 90
sustained_duration = 300

[memory]
warning_threshold = 80
critical_threshold = 95
swap_warning = 50

[disk]
warning_threshold = 85
critical_threshold = 95
log_rotation_trigger = 90

[network]
bandwidth_warning = 100MB
connection_limit = 1000
timeout_threshold = 30
```

## 🚨 Alert Management

### Alert Categories

#### Critical Alerts (Immediate Response)

- Honeypot file access
- Credential theft attempts
- Privilege escalation
- System compromise indicators
- Service failures

#### Warning Alerts (Monitor Closely)

- Unusual network activity
- Multiple failed logins
- Resource threshold exceeded
- Configuration changes

#### Informational Alerts (Log and Review)

- Routine scans
- Known reconnaissance
- Performance metrics
- System maintenance events

### Alert Configuration

```yaml
# alert-rules.yml
alerting:
  critical:
    - event: file_access
      files: ["*.docx", "*.pdf", "credentials*"]
      action: immediate_notification
      escalation: security_team
    
    - event: privilege_escalation
      indicators: ["sudo", "su", "runas"]
      action: immediate_notification
      escalation: incident_response
  
  warning:
    - event: multiple_failures
      threshold: 10
      timeframe: 300
      action: delayed_notification
    
    - event: resource_threshold
      metric: cpu_usage
      threshold: 80
      duration: 600
      action: operations_alert

  informational:
    - event: port_scan
      action: log_only
      summary: hourly
```

### Alert Escalation

```bash
# Escalation matrix
Level_1: Operations Team (immediate)
  └── Response Time: < 15 minutes
  └── Contact: ops@company.com, +1-XXX-XXX-XXXX

Level_2: Security Team (< 30 minutes)
  └── Response Time: < 30 minutes  
  └── Contact: security@company.com, +1-XXX-XXX-XXXX

Level_3: Incident Response (< 60 minutes)
  └── Response Time: < 60 minutes
  └── Contact: ir@company.com, +1-XXX-XXX-XXXX

Level_4: Executive (> 60 minutes)
  └── Response Time: < 2 hours
  └── Contact: exec@company.com
```

## 📊 Analytics and Reporting

### Automated Reports

#### Daily Security Report

```bash
#!/bin/bash
# daily-security-report.sh

DATE=$(date +%Y-%m-%d)
REPORT_FILE="security-report-$DATE.html"

cat > $REPORT_FILE << EOF
<html>
<head><title>Daily Security Report - $DATE</title></head>
<body>
<h1>ShadowTrace Sentinel Daily Report</h1>
<h2>Summary for $DATE</h2>

<h3>Attack Statistics</h3>
<ul>
<li>Total Attempts: $(grep -c "ATTEMPT" ~/.honeypot/logs/events.log)</li>
<li>Unique Source IPs: $(grep "ATTEMPT" ~/.honeypot/logs/events.log | awk '{print $4}' | sort -u | wc -l)</li>
<li>Successful Logins: $(grep -c "LOGIN_SUCCESS" ~/.honeypot/logs/events.log)</li>
<li>File Access Events: $(grep -c "FILE_ACCESS" ~/.honeypot/logs/events.log)</li>
</ul>

<h3>Top Source IPs</h3>
<pre>
$(grep "ATTEMPT" ~/.honeypot/logs/events.log | awk '{print $4}' | sort | uniq -c | sort -nr | head -10)
</pre>

<h3>Attack Timeline</h3>
<pre>
$(grep "ATTEMPT" ~/.honeypot/logs/events.log | awk '{print $1, $2}' | cut -c1-13 | sort | uniq -c)
</pre>
</body>
</html>
EOF

# Email report
mail -s "Daily Security Report - $DATE" -a "Content-Type: text/html" security@company.com < $REPORT_FILE
```

#### Weekly Threat Analysis

```bash
#!/bin/bash
# weekly-threat-analysis.sh

# Generate weekly threat intelligence report
python3 << 'EOF'
import pandas as pd
import matplotlib.pyplot as plt
from datetime import datetime, timedelta

# Load attack data
attacks = pd.read_csv('~/.honeypot/logs/attacks.csv')
attacks['timestamp'] = pd.to_datetime(attacks['timestamp'])

# Weekly analysis
week_start = datetime.now() - timedelta(days=7)
weekly_attacks = attacks[attacks['timestamp'] > week_start]

# Generate charts
fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))

# Attack frequency by hour
hourly = weekly_attacks.groupby(weekly_attacks['timestamp'].dt.hour).size()
ax1.bar(hourly.index, hourly.values)
ax1.set_title('Attacks by Hour of Day')
ax1.set_xlabel('Hour')
ax1.set_ylabel('Attack Count')

# Top source countries
countries = weekly_attacks['source_country'].value_counts().head(10)
ax2.pie(countries.values, labels=countries.index, autopct='%1.1f%%')
ax2.set_title('Attacks by Source Country')

# Attack types
attack_types = weekly_attacks['attack_type'].value_counts()
ax3.bar(attack_types.index, attack_types.values)
ax3.set_title('Attack Types')
ax3.tick_params(axis='x', rotation=45)

# Daily trend
daily = weekly_attacks.groupby(weekly_attacks['timestamp'].dt.date).size()
ax4.plot(daily.index, daily.values, marker='o')
ax4.set_title('Daily Attack Trend')
ax4.tick_params(axis='x', rotation=45)

plt.tight_layout()
plt.savefig('weekly-threat-analysis.png', dpi=300, bbox_inches='tight')
print("Weekly threat analysis generated: weekly-threat-analysis.png")
EOF
```

### Business Intelligence Dashboard

```bash
# Setup Grafana dashboard
./scripts/setup-grafana.sh --config monitoring/grafana-config.json

# Dashboard panels:
# - Real-time attack map
# - Attack frequency trends  
# - Source IP geolocation
# - System performance metrics
# - Alert volume and types
# - Response time metrics
```

## 🔧 Integration with SIEM/SOAR

### Splunk Integration

```bash
# Splunk Universal Forwarder configuration
cat > /opt/splunkforwarder/etc/apps/shadowtrace/inputs.conf << 'EOF'
[monitor://~/.honeypot/logs/events.log]
index = security
sourcetype = shadowtrace:events
host = honeypot-01

[monitor://~/.honeypot/logs/alerts.log]
index = security  
sourcetype = shadowtrace:alerts
host = honeypot-01
EOF

# Restart Splunk forwarder
/opt/splunkforwarder/bin/splunk restart
```

### ElasticSearch Integration

```bash
# Filebeat configuration for ELK stack
cat > /etc/filebeat/filebeat.yml << 'EOF'
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - ~/.honeypot/logs/*.log
  fields:
    service: shadowtrace-sentinel
    environment: production

output.elasticsearch:
  hosts: ["elasticsearch:9200"]
  index: "shadowtrace-%{+yyyy.MM.dd}"

setup.template.name: "shadowtrace"
setup.template.pattern: "shadowtrace-*"
EOF

systemctl restart filebeat
```

### QRadar Integration

```bash
# QRadar log source configuration
cat > /opt/qradar/conf/shadowtrace-dsm.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<device-extension xmlns="event_parsing/device_extension">
  <pattern id="ShadowTraceEvent">
    <![CDATA[\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\] (\w+): (.+)]]>
  </pattern>
  
  <event-match-single pattern-id="ShadowTraceEvent">
    <event>
      <message-id>ShadowTrace</message-id>
      <severity>5</severity>
      <description>$3</description>
    </event>
  </event-match-single>
</device-extension>
EOF
```

## 📱 Mobile and Remote Monitoring

### Mobile App Integration

```bash
# Push notification setup
curl -X POST "https://api.pushover.net/1/messages.json" \
  --form-string "token=YOUR_APP_TOKEN" \
  --form-string "user=YOUR_USER_KEY" \
  --form-string "message=Honeypot alert: $ALERT_MESSAGE" \
  --form-string "title=ShadowTrace Alert" \
  --form-string "priority=1"
```

### SMS Alerts

```bash
# Twilio SMS integration
curl -X POST "https://api.twilio.com/2010-04-01/Accounts/$ACCOUNT_SID/Messages.json" \
  --data-urlencode "From=+1234567890" \
  --data-urlencode "To=+0987654321" \
  --data-urlencode "Body=CRITICAL: Honeypot breach detected at $(date)" \
  -u $ACCOUNT_SID:$AUTH_TOKEN
```

### Remote Access Dashboard

```bash
# Secure remote dashboard setup
./scripts/setup-remote-dashboard.sh --port 8443 --ssl-cert /path/to/cert.pem

# Access via: https://honeypot.company.com:8443/dashboard
# Features:
# - Real-time status
# - Live event feed  
# - Performance metrics
# - Alert management
# - Report generation
```

## 🔍 Forensics and Investigation

### Evidence Collection

```bash
# Automated evidence collection
./scripts/collect-evidence.sh --incident-id INC-20250704-001 --preserve-logs

# Evidence package contents:
# - System snapshots
# - Network captures
# - Log files
# - Memory dumps
# - File system artifacts
```

### Threat Hunting

```bash
# Hunt for indicators of compromise
./scripts/threat-hunt.sh --ioc-file threat-intel.json --timeframe 7d

# Search for specific patterns
grep -r "specific_pattern" ~/.honeypot/logs/ | ./scripts/correlate-events.sh
```

### Incident Timeline

```bash
# Generate incident timeline
./scripts/generate-timeline.sh --start "2025-07-04 14:00:00" --end "2025-07-04 15:00:00" --format html
```

## 📋 Monitoring Checklist

### Daily Tasks

- [ ] Review overnight alerts
- [ ] Check system health status
- [ ] Verify log rotation
- [ ] Monitor disk space usage
- [ ] Review false positive rates

### Weekly Tasks

- [ ] Generate security reports
- [ ] Analyze attack trends
- [ ] Update threat intelligence
- [ ] Review alert thresholds
- [ ] Test backup procedures

### Monthly Tasks

- [ ] Comprehensive security review
- [ ] Performance optimization
- [ ] Configuration updates
- [ ] Staff training updates
- [ ] Compliance reporting

---

**Document Version**: 1.0  
**Last Updated**: July 4, 2025  
**Review Date**: October 4, 2025
