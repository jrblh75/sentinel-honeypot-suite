# ShadowTrace Sentinel Honeypot Suite

**A cross-platform honeypot security system for detecting and monitoring unauthorized access attempts.**

![Security](https://img.shields.io/badge/Security-Honeypot-red)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue)
![License](https://img.shields.io/badge/License-MIT-green)

## 🎯 Overview

ShadowTrace Sentinel is a sophisticated honeypot suite designed to detect, monitor, and log unauthorized access attempts across multiple platforms. The system creates decoy targets that appear valuable to attackers while capturing detailed intelligence about intrusion attempts.

## ✨ Key Features

- 🛡️ **Multi-Platform Support** - Windows, Linux (Ubuntu/Debian), and macOS
- 🔒 **Data Protection** - DPAPI encryption on Windows, secure storage across platforms
- 📊 **Real-time Monitoring** - Continuous surveillance and logging
- 🌐 **IP Tracking** - Automatic attacker IP identification and geolocation
- 📧 **Alert System** - Instant notifications on breach attempts
- 🕵️ **Stealth Operation** - Invisible to casual inspection
- 📈 **Analytics** - Detailed attack pattern analysis
- 🔄 **Auto-deployment** - One-click installation across environments

## 🏗️ Architecture

```text
ShadowTrace Sentinel Architecture
================================

┌─────────────────────────────────────────────────────────┐
│                 Management Console                      │
│            (Central Monitoring Hub)                     │
└─────────────────────────────────────────────────────────┘
                            │
            ┌───────────────┼───────────────┐
            │               │               │
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   Windows       │ │     Linux       │ │     macOS       │
│   PowerShell    │ │   Bash Script   │ │   Bash Script   │
│   Honeypot      │ │   Honeypot      │ │   Honeypot      │
└─────────────────┘ └─────────────────┘ └─────────────────┘
         │                   │                   │
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│ DPAPI Encrypted │ │ GPG Encrypted   │ │ Keychain        │
│ Decoy Data      │ │ Decoy Data      │ │ Decoy Data      │
└─────────────────┘ └─────────────────┘ └─────────────────┘
         │                   │                   │
         └───────────────────┼───────────────────┘
                             │
    ┌─────────────────────────────────────────────────────┐
    │              Alert & Logging System                 │
    │  • IP Geolocation  • Timestamp Logging             │
    │  • Email Alerts    • Forensic Evidence Collection  │
    └─────────────────────────────────────────────────────┘
```

## 📁 Project Structure

```text
sentinel-honeypot-suite/
├── README.md                                    # Start here - Project overview
├── SECURITY.md                                  # Security guidelines (read first)
├── LICENSE                                      # MIT License
├── .gitignore                                   # Git ignore rules
│
├── docs/                                        # 📖 Documentation (Installation Order)
│   ├── INSTALLATION.md                         # 1. Installation guide (read first)
│   ├── ENVIRONMENT.md                          # 2. Environment setup guide
│   ├── CONFIGURATION.md                        # 3. Advanced configuration
│   ├── MONITORING.md                           # 4. Monitoring and alerts
│   ├── API.md                                  # 5. API documentation
│   └── TROUBLESHOOTING.md                      # 6. Common issues and solutions
│
├── 🔧 Environment Configuration (Setup Order)
├── .env.template                                # 1. Copy to .env and configure
├── docker-compose.yml                           # 2. Docker services configuration
├── docker/                                      # 3. Docker-specific configurations
│   ├── postgres/                               # PostgreSQL setup
│   │   ├── init/                              # Database initialization
│   │   │   └── 01-init-database.sql           # Database schema
│   │   └── config/                            # PostgreSQL optimization
│   │       └── postgresql.conf                # Optimized settings
│   ├── Dockerfile                             # Application container
│   ├── prometheus/                            # Monitoring configuration
│   └── grafana/                               # Dashboard configuration
│
├── 🚀 Platform Installers (Choose Your Platform)
├── scripts/                                    # Management scripts (use first)
│   ├── docker-env.sh                          # 🔥 START HERE - Environment manager
│   ├── status.sh                               # Check system status
│   ├── validate.sh                             # Validate installation
│   ├── test.sh                                 # Run test suite
│   ├── test-alerts.sh                          # Test alert system
│   ├── benchmark.sh                            # Performance testing
│   ├── update.sh                               # Update system
│   └── cleanup.sh                              # System cleanup
│
├── windows/                                     # 🪟 Windows Installation
│   └── install.ps1                            # PowerShell installer
│
├── linux/                                      # 🐧 Linux Installation  
│   └── ShadowTrace Sentinel Server - Ubuntu.Debian.sh  # Linux installer
│
├── macos/                                       # 🍎 macOS Installation
│   └── ShadowTrace Sentinel Server - macOS.sh  # macOS installer
│
└── 📋 Reference Files (Auto-generated)
    ├── DEPLOYMENT.md                            # Deployment instructions
    ├── POSTGRES_SETUP_SUMMARY.md              # PostgreSQL setup summary
    └── CONTAINER_ENV_UPDATE.md                 # Environment configuration guide
```

## 🗂️ Installation Reference Order

### 🎯 **Quick Start Path (Recommended)**
```bash
1. docs/INSTALLATION.md          # Read installation overview
2. docs/ENVIRONMENT.md           # Environment setup guide  
3. scripts/docker-env.sh setup   # One-command environment setup
4. scripts/docker-env.sh start   # Start all services
5. docs/MONITORING.md            # Configure monitoring
```

### 🔧 **Manual Setup Path (Advanced)**
```bash
1. .env.template → .env          # Copy and configure environment
2. docker-compose.yml            # Review Docker services
3. docker/postgres/              # Database configuration
4. scripts/validate.sh           # Validate setup
5. Platform installer (windows/linux/macos)
```

### 📚 **Documentation Reading Order**
```bash
1. README.md                     # Project overview (you are here)
2. SECURITY.md                   # Security considerations
3. docs/INSTALLATION.md          # Installation steps
4. docs/ENVIRONMENT.md           # Environment configuration
5. docs/CONFIGURATION.md         # Advanced settings
6. docs/MONITORING.md            # Monitoring setup
7. docs/API.md                   # API reference
8. docs/TROUBLESHOOTING.md       # Problem solving
```

## 🚀 Quick Start

### Prerequisites

- Administrator/root privileges on target system
- Docker and Docker Compose installed (for containerized deployment)
- Network connectivity for IP detection and alerts
- Email configuration for notifications (optional)

### 🎯 Recommended Installation Order

#### Step 1: Read Documentation
```bash
# Start with these files in order:
1. README.md (this file)
2. SECURITY.md  
3. docs/INSTALLATION.md
4. docs/ENVIRONMENT.md
```

#### Step 2: Docker Environment Setup (Recommended)
```bash
# One-command setup for production deployments
./scripts/docker-env.sh setup    # Creates .env and generates secure passwords
./scripts/docker-env.sh start    # Starts PostgreSQL, Redis, monitoring stack  
./scripts/docker-env.sh status   # Verifies all services are running
```

#### Step 3: Platform-Specific Installation (Alternative)

Choose your platform for standalone installation:

#### Windows
```powershell
# Run as Administrator
cd sentinel-honeypot-suite/windows
.\install.ps1
```

#### Linux (Ubuntu/Debian)
```bash
# Run as root or with sudo
cd sentinel-honeypot-suite/linux
chmod +x "ShadowTrace Sentinel Server - Ubuntu.Debian.sh"
sudo ./"ShadowTrace Sentinel Server - Ubuntu.Debian.sh"
```

#### macOS
```bash
# Run with sudo
cd sentinel-honeypot-suite/macos
chmod +x "ShadowTrace Sentinel Server - macOS.sh"
sudo ./"ShadowTrace Sentinel Server - macOS.sh"
```

## 🔧 Configuration

### Docker Environment Setup

For production deployments with PostgreSQL database:

```bash
# Initial setup (creates .env file from template and generates secure passwords)
./scripts/docker-env.sh setup

# Start all services (PostgreSQL, Redis, Honeypot, Monitoring)
./scripts/docker-env.sh start

# Check service status
./scripts/docker-env.sh status
```

**Important Notes:**
- The `.env` file is automatically created from `.env.template` during setup
- All default passwords and secrets are auto-generated for security
- The `.env` file is excluded from git to protect sensitive information
- If you have existing environment configurations (e.g., in PostgresAI directory), you can reference them when customizing your `.env` file

### Environment Variables

#### Basic Configuration

```bash
# Set these environment variables before installation
export SENTINEL_EMAIL="your-alerts@email.com"
export SENTINEL_WEBHOOK="https://your-webhook-url.com"
export SENTINEL_LOG_LEVEL="INFO"  # DEBUG, INFO, WARN, ERROR
```

#### Database Configuration (Docker)

```bash
# PostgreSQL Database Settings
POSTGRES_DB=sentinel_honeypot
POSTGRES_USER=sentinel_admin
POSTGRES_PASSWORD=your-secure-password
POSTGRES_HOST=localhost
POSTGRES_PORT=5432

# Application Security Keys (auto-generated)
SENTINEL_SECRET_KEY=your-32-character-secret-key
SENTINEL_JWT_SECRET=your-jwt-secret-key
SENTINEL_ENCRYPTION_KEY=your-encryption-key
```

### Custom Configuration

#### Standalone Installation

Edit the configuration files in `~/.honeypot/config/` after installation:

- `sentinel.conf` - Main configuration
- `alerts.conf` - Alert settings  
- `encryption.conf` - Encryption parameters

#### Docker Installation

- `.env` - Environment variables and secrets
- `docker-compose.yml` - Service configuration
- `docker/postgres/init/` - Database initialization scripts

## 📊 Monitoring

### Real-time Status
```bash
# Check honeypot status
./scripts/status.sh

# View recent logs
tail -f ~/.honeypot/logs/sentinel.log

# Check trap triggers
cat ~/.honeypot/logs/triggers.log
```

### Alert Notifications

The system automatically sends alerts when:
- 🚨 Honeypot files are accessed
- 🚨 Decoy data is modified
- 🚨 Unusual system activity detected
- 🚨 Multiple access attempts from same IP

## 🛡️ Security Features

### Data Protection
- **Windows**: DPAPI (Data Protection API) encryption
- **Linux**: GPG encryption with system keyring
- **macOS**: Keychain integration with secure enclave

### Stealth Mechanisms
- Hidden file attributes
- Process name obfuscation
- Network traffic mimicry
- Anti-forensics techniques

### Detection Capabilities
- File access monitoring
- Process injection detection
- Network connection tracking
- System call anomaly detection

## 📈 Analytics & Reporting

### Automated Reports
- Daily activity summaries
- Weekly threat analysis
- Monthly security assessments
- Custom report generation

### Threat Intelligence
- IP reputation checking
- Geolocation mapping
- Attack pattern recognition
- IOC (Indicator of Compromise) extraction

## 🔒 Security Considerations

⚠️ **Important Security Notes:**

1. **Legal Compliance**: Ensure honeypot deployment complies with local laws
2. **Network Isolation**: Deploy in isolated network segments when possible
3. **Data Handling**: Properly secure and encrypt all captured data
4. **Access Control**: Limit access to honeypot systems and logs
5. **Regular Updates**: Keep honeypot signatures and detection rules current

## 🛠️ Development

### Contributing
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-detection`)
3. Commit changes (`git commit -am 'Add new detection method'`)
4. Push to branch (`git push origin feature/new-detection`)
5. Create Pull Request

### Testing
```bash
# Run test suite
./scripts/test.sh

# Validate installation
./scripts/validate.sh

# Performance testing
./scripts/benchmark.sh
```

## 📚 Documentation

### 📖 Reading Order (Recommended)

1. **[README.md](README.md)** - Project overview and quick start (you are here)
2. **[SECURITY.md](SECURITY.md)** - Security guidelines and considerations  
3. **[Installation Guide](docs/INSTALLATION.md)** - Detailed setup instructions
4. **[Environment Setup](docs/ENVIRONMENT.md)** - Environment configuration guide
5. **[Configuration Manual](docs/CONFIGURATION.md)** - Advanced configuration options
6. **[Monitoring Guide](docs/MONITORING.md)** - Comprehensive monitoring setup
7. **[API Reference](docs/API.md)** - Programming interface documentation  
8. **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

### 📋 Reference Documents

- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production deployment guide
- **[POSTGRES_SETUP_SUMMARY.md](POSTGRES_SETUP_SUMMARY.md)** - PostgreSQL configuration summary
- **[CONTAINER_ENV_UPDATE.md](CONTAINER_ENV_UPDATE.md)** - Environment update documentation

### 🗂️ NAS Directory Reference

If you have existing configurations in the PostgresAI directory:
```bash
/Volumes/NASté-DockerHD/|Projects (Holding)/GitHub/Active Repos/PostgresAI/.env
```

Refer to `docs/ENVIRONMENT.md` for migration guidance.

## 🆘 Support

### Getting Help
- 📖 Check the [documentation](docs/)
- 🐛 Report issues on [GitHub Issues](https://github.com/jrblh75/sentinel-honeypot-suite/issues)
- 💬 Join discussions in [Discussions](https://github.com/jrblh75/sentinel-honeypot-suite/discussions)

### Emergency Response
For critical security incidents related to honeypot breaches:
1. Immediately isolate affected systems
2. Preserve logs and evidence
3. Contact security team
4. Document incident timeline

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## ⚖️ Legal Disclaimer

This software is provided for educational and legitimate security testing purposes only. Users are responsible for ensuring compliance with all applicable laws and regulations in their jurisdiction. The authors are not responsible for any misuse of this software.

## 🙏 Acknowledgments

- Security research community for threat intelligence
- Open source security tools and frameworks
- Contributors and beta testers

---

**Created by**: Brannon-Lee Hollis Jr.  
**Project**: ShadowTrace Sentinel Honeypot Suite  
**Repository**: https://github.com/jrblh75/sentinel-honeypot-suite  
**Version**: 1.0  
**Last Updated**: July 4, 2025
