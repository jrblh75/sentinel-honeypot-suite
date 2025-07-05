# ShadowTrace Sentinel API Reference

## 🔌 API Overview

ShadowTrace Sentinel provides a RESTful API for programmatic interaction with the honeypot system, enabling integration with security orchestration platforms, custom dashboards, and automated response systems.

## 🚀 Getting Started

### API Endpoint

```
Base URL: https://your-honeypot.company.com:8443/api/v1
```

### Authentication

```bash
# API Key Authentication
curl -H "X-API-Key: your-api-key" \
     -H "Content-Type: application/json" \
     https://your-honeypot.company.com:8443/api/v1/status
```

### Rate Limiting

- **Standard**: 100 requests per minute
- **Burst**: 200 requests per minute  
- **Daily**: 10,000 requests per day

## 🔑 Authentication

### API Key Management

```bash
# Generate new API key
POST /api/v1/auth/keys
{
  "name": "monitoring-system",
  "permissions": ["read", "write"],
  "expires_in": 86400
}

# Response
{
  "api_key": "sk_live_abc123...",
  "key_id": "key_123",
  "expires_at": "2025-07-05T14:30:00Z"
}
```

### JWT Authentication

```bash
# Login and get JWT token
POST /api/v1/auth/login
{
  "username": "admin",
  "password": "secure_password"
}

# Response
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 3600
}

# Use JWT token
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIs..." \
     https://your-honeypot.company.com:8443/api/v1/status
```

## 📊 System Status API

### Get System Status

```bash
GET /api/v1/status

# Response
{
  "status": "active",
  "uptime": 259200,
  "version": "1.0.0",
  "honeypots_active": 5,
  "alerts_last_hour": 3,
  "cpu_usage": 15.2,
  "memory_usage": 45.6,
  "disk_usage": 23.1,
  "network_connections": 12
}
```

### Get Detailed Health Check

```bash
GET /api/v1/health

# Response
{
  "overall_status": "healthy",
  "components": {
    "database": {
      "status": "healthy",
      "response_time": 12
    },
    "file_monitor": {
      "status": "healthy",
      "files_watched": 1247
    },
    "network_monitor": {
      "status": "healthy",
      "active_listeners": 3
    },
    "alert_system": {
      "status": "healthy",
      "last_alert": "2025-07-04T14:25:00Z"
    }
  }
}
```

## 🚨 Alerts API

### Get Recent Alerts

```bash
GET /api/v1/alerts?limit=10&severity=high

# Response
{
  "alerts": [
    {
      "id": "alert_123",
      "timestamp": "2025-07-04T14:30:15Z",
      "severity": "high",
      "type": "file_access",
      "source_ip": "192.168.1.100",
      "target_file": "/home/user/confidential.docx",
      "description": "Unauthorized file access detected",
      "geolocation": {
        "country": "Unknown",
        "city": "Unknown",
        "isp": "Local Network"
      },
      "status": "open"
    }
  ],
  "total": 247,
  "page": 1,
  "pages": 25
}
```

### Create Custom Alert

```bash
POST /api/v1/alerts
{
  "severity": "medium",
  "type": "custom",
  "source_ip": "10.0.0.1",
  "description": "Custom security event detected",
  "metadata": {
    "custom_field": "value",
    "detection_rule": "rule_001"
  }
}

# Response
{
  "id": "alert_124",
  "status": "created",
  "timestamp": "2025-07-04T14:35:00Z"
}
```

### Update Alert Status

```bash
PATCH /api/v1/alerts/alert_123
{
  "status": "resolved",
  "resolution_notes": "False positive - legitimate admin access"
}
```

### Get Alert Statistics

```bash
GET /api/v1/alerts/stats?timeframe=24h

# Response
{
  "total_alerts": 45,
  "by_severity": {
    "critical": 2,
    "high": 8,
    "medium": 20,
    "low": 15
  },
  "by_type": {
    "file_access": 15,
    "login_attempt": 12,
    "port_scan": 8,
    "privilege_escalation": 2,
    "other": 8
  },
  "top_source_ips": [
    {"ip": "192.168.1.100", "count": 12},
    {"ip": "10.0.0.50", "count": 8}
  ]
}
```

## 🕵️ Events API

### Stream Real-time Events

```bash
GET /api/v1/events/stream
# Server-Sent Events (SSE) endpoint

# Event stream format:
data: {"id": "evt_001", "type": "file_access", "timestamp": "2025-07-04T14:30:00Z", ...}

data: {"id": "evt_002", "type": "login_attempt", "timestamp": "2025-07-04T14:31:00Z", ...}
```

### Get Event History

```bash
GET /api/v1/events?start_time=2025-07-04T00:00:00Z&end_time=2025-07-04T23:59:59Z&type=file_access

# Response
{
  "events": [
    {
      "id": "evt_123",
      "timestamp": "2025-07-04T14:30:15Z",
      "type": "file_access",
      "source_ip": "192.168.1.100",
      "user_agent": "curl/7.68.0",
      "target_resource": "/api/v1/files/secret.txt",
      "method": "GET",
      "status_code": 200,
      "response_size": 1024,
      "duration": 150
    }
  ],
  "total": 1247,
  "pagination": {
    "page": 1,
    "per_page": 50,
    "total_pages": 25
  }
}
```

### Export Events

```bash
GET /api/v1/events/export?format=csv&start_time=2025-07-04T00:00:00Z&end_time=2025-07-04T23:59:59Z

# Response: CSV file download
# or JSON format
GET /api/v1/events/export?format=json&...
```

## ⚙️ Configuration API

### Get Configuration

```bash
GET /api/v1/config

# Response
{
  "general": {
    "honeypot_id": "sentinel-001",
    "stealth_mode": true,
    "debug_mode": false
  },
  "monitoring": {
    "monitor_file_access": true,
    "monitor_network_connections": true
  },
  "alerts": {
    "email_enabled": true,
    "webhook_enabled": true
  }
}
```

### Update Configuration

```bash
PATCH /api/v1/config
{
  "monitoring": {
    "sensitivity_level": "high"
  },
  "alerts": {
    "max_alerts_per_hour": 5
  }
}

# Response
{
  "status": "updated",
  "restart_required": true,
  "changes": [
    "monitoring.sensitivity_level: medium -> high",
    "alerts.max_alerts_per_hour: 10 -> 5"
  ]
}
```

### Validate Configuration

```bash
POST /api/v1/config/validate
{
  "general": {
    "honeypot_id": "test-honeypot",
    "stealth_mode": true
  }
}

# Response
{
  "valid": true,
  "warnings": [
    "High sensitivity may increase false positives"
  ],
  "errors": []
}
```

## 📈 Analytics API

### Get Attack Statistics

```bash
GET /api/v1/analytics/attacks?timeframe=7d&group_by=hour

# Response
{
  "timeframe": "7d",
  "total_attacks": 1247,
  "unique_sources": 89,
  "attack_types": {
    "brute_force": 456,
    "file_access": 234,
    "port_scan": 178,
    "malware": 23
  },
  "timeline": [
    {"timestamp": "2025-07-04T00:00:00Z", "count": 12},
    {"timestamp": "2025-07-04T01:00:00Z", "count": 8}
  ]
}
```

### Get Geolocation Data

```bash
GET /api/v1/analytics/geolocation?timeframe=24h

# Response
{
  "countries": [
    {"country": "CN", "count": 234, "percentage": 45.2},
    {"country": "RU", "count": 156, "percentage": 30.1},
    {"country": "US", "count": 89, "percentage": 17.2}
  ],
  "cities": [
    {"city": "Beijing", "country": "CN", "count": 123},
    {"city": "Moscow", "country": "RU", "count": 89}
  ]
}
```

### Generate Reports

```bash
POST /api/v1/analytics/reports
{
  "type": "security_summary",
  "timeframe": "weekly",
  "format": "pdf",
  "email_to": ["admin@company.com"],
  "include_charts": true
}

# Response
{
  "report_id": "rpt_123",
  "status": "generating",
  "estimated_completion": "2025-07-04T14:45:00Z",
  "download_url": "/api/v1/reports/rpt_123/download"
}
```

## 🔧 Management API

### Honeypot Control

```bash
# Start honeypot services
POST /api/v1/management/start
{
  "services": ["ssh", "http", "ftp"]
}

# Stop honeypot services  
POST /api/v1/management/stop
{
  "services": ["all"]
}

# Restart honeypot
POST /api/v1/management/restart
{
  "graceful": true,
  "delay": 30
}
```

### Update Management

```bash
# Check for updates
GET /api/v1/management/updates

# Response
{
  "current_version": "1.0.0",
  "latest_version": "1.0.1",
  "update_available": true,
  "changelog_url": "https://github.com/jrblh75/sentinel-honeypot-suite/releases/tag/v1.0.1"
}

# Install update
POST /api/v1/management/update
{
  "version": "1.0.1",
  "backup_config": true,
  "restart_after": true
}
```

### Backup and Restore

```bash
# Create backup
POST /api/v1/management/backup
{
  "include_logs": false,
  "include_config": true,
  "encrypt": true
}

# Response
{
  "backup_id": "backup_123",
  "file_size": 45678901,
  "download_url": "/api/v1/backups/backup_123/download"
}

# Restore from backup
POST /api/v1/management/restore
{
  "backup_id": "backup_123",
  "restore_config": true,
  "restart_services": true
}
```

## 🔍 Search API

### Search Events

```bash
POST /api/v1/search/events
{
  "query": "source_ip:192.168.1.* AND type:file_access",
  "timeframe": "24h",
  "limit": 100,
  "sort": "timestamp:desc"
}

# Response
{
  "results": [...],
  "total_hits": 234,
  "query_time": 156,
  "aggregations": {
    "by_hour": [...],
    "by_source": [...]
  }
}
```

### Search Logs

```bash
POST /api/v1/search/logs
{
  "query": "ERROR AND honeypot",
  "log_types": ["system", "security"],
  "start_time": "2025-07-04T00:00:00Z",
  "end_time": "2025-07-04T23:59:59Z"
}
```

## 🌐 Webhooks API

### Register Webhook

```bash
POST /api/v1/webhooks
{
  "url": "https://your-system.com/webhook",
  "events": ["alert.created", "attack.detected"],
  "secret": "webhook_secret_key",
  "active": true
}

# Response
{
  "webhook_id": "hook_123",
  "status": "created",
  "test_url": "/api/v1/webhooks/hook_123/test"
}
```

### Test Webhook

```bash
POST /api/v1/webhooks/hook_123/test

# Sends test payload to registered webhook
```

## 📡 Integration Examples

### Python SDK

```python
import requests
from shadowtrace_sdk import SentinelAPI

# Initialize client
client = SentinelAPI(
    base_url="https://your-honeypot.company.com:8443",
    api_key="your-api-key"
)

# Get recent alerts
alerts = client.alerts.list(limit=10, severity="high")

# Create custom alert
alert = client.alerts.create(
    severity="medium",
    type="custom",
    description="Custom security event"
)

# Stream real-time events
for event in client.events.stream():
    print(f"New event: {event.type} from {event.source_ip}")
```

### JavaScript/Node.js

```javascript
const SentinelAPI = require('shadowtrace-sentinel-api');

const client = new SentinelAPI({
  baseURL: 'https://your-honeypot.company.com:8443',
  apiKey: 'your-api-key'
});

// Get system status
client.getStatus()
  .then(status => console.log('System status:', status))
  .catch(error => console.error('Error:', error));

// Subscribe to alerts
client.alerts.subscribe((alert) => {
  console.log('New alert:', alert);
  
  // Auto-respond to critical alerts
  if (alert.severity === 'critical') {
    client.management.isolateSource(alert.source_ip);
  }
});
```

### PowerShell

```powershell
# PowerShell wrapper functions
function Get-SentinelStatus {
    $headers = @{"X-API-Key" = $env:SENTINEL_API_KEY}
    Invoke-RestMethod -Uri "$env:SENTINEL_URL/api/v1/status" -Headers $headers
}

function Get-SentinelAlerts {
    param([int]$Limit = 10, [string]$Severity = "all")
    
    $headers = @{"X-API-Key" = $env:SENTINEL_API_KEY}
    $params = @{limit = $Limit}
    if ($Severity -ne "all") { $params.severity = $Severity }
    
    Invoke-RestMethod -Uri "$env:SENTINEL_URL/api/v1/alerts" -Headers $headers -Body $params
}
```

## 🔒 Security Considerations

### API Security Best Practices

1. **Use HTTPS Only**: All API communication must use TLS 1.2+
2. **API Key Management**: Rotate keys regularly, use different keys per application
3. **Rate Limiting**: Implement client-side rate limiting to avoid 429 errors  
4. **Input Validation**: Validate all input parameters
5. **Error Handling**: Don't expose sensitive information in error messages

### API Access Logs

```bash
# API access logs are stored in:
~/.honeypot/logs/api_access.log

# Format:
[2025-07-04 14:30:15] GET /api/v1/status 200 key_123 192.168.1.50 156ms
[2025-07-04 14:30:20] POST /api/v1/alerts 401 invalid_key 192.168.1.51 45ms
```

---

**Document Version**: 1.0  
**Last Updated**: July 4, 2025  
**Review Date**: October 4, 2025
