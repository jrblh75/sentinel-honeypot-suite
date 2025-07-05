#!/bin/bash

# ShadowTrace Sentinel - Project Setup Verification Script
# Verifies that all components are properly installed and configured

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}🔍 ShadowTrace Sentinel - Project Setup Verification${NC}"
echo "=================================================="
echo

# Function to check if file exists
check_file() {
    local file="$1"
    local description="$2"
    
    if [[ -f "$PROJECT_DIR/$file" ]]; then
        echo -e "${GREEN}✅ $description${NC}"
        return 0
    else
        echo -e "${RED}❌ Missing: $file - $description${NC}"
        return 1
    fi
}

# Function to check if directory exists
check_directory() {
    local dir="$1"
    local description="$2"
    
    if [[ -d "$PROJECT_DIR/$dir" ]]; then
        echo -e "${GREEN}✅ $description${NC}"
        return 0
    else
        echo -e "${RED}❌ Missing: $dir - $description${NC}"
        return 1
    fi
}

# Function to check if script is executable
check_executable() {
    local script="$1"
    local description="$2"
    
    if [[ -x "$PROJECT_DIR/$script" ]]; then
        echo -e "${GREEN}✅ $description (executable)${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  $description (not executable - fixing...)${NC}"
        chmod +x "$PROJECT_DIR/$script"
        if [[ -x "$PROJECT_DIR/$script" ]]; then
            echo -e "${GREEN}✅ $description (fixed)${NC}"
            return 0
        else
            echo -e "${RED}❌ Failed to make executable: $script${NC}"
            return 1
        fi
    fi
}

echo -e "${BLUE}📋 Core Documentation Files${NC}"
echo "----------------------------"
check_file "README.md" "Project overview and documentation"
check_file "SECURITY.md" "Security guidelines"
check_file "LICENSE" "MIT License file"
check_file ".gitignore" "Git ignore rules"
check_file "DEPLOYMENT.md" "Deployment instructions"
check_file "POSTGRES_SETUP_SUMMARY.md" "PostgreSQL setup summary"
check_file "CONTAINER_ENV_UPDATE.md" "Environment configuration guide"
echo

echo -e "${BLUE}📖 Documentation Directory${NC}"
echo "----------------------------"
check_directory "docs" "Documentation directory"
check_file "docs/INSTALLATION.md" "Installation guide"
check_file "docs/ENVIRONMENT.md" "Environment setup guide"
check_file "docs/CONFIGURATION.md" "Configuration manual"
check_file "docs/MONITORING.md" "Monitoring and alerts guide"
check_file "docs/API.md" "API documentation"
check_file "docs/TROUBLESHOOTING.md" "Troubleshooting guide"
echo

echo -e "${BLUE}🔧 Environment Configuration${NC}"
echo "------------------------------"
check_file ".env.template" "Environment template file"
if [[ -f "$PROJECT_DIR/.env" ]]; then
    echo -e "${GREEN}✅ Environment file exists (.env)${NC}"
else
    echo -e "${YELLOW}⚠️  .env file not found - you may need to copy from .env.template${NC}"
fi
check_file "docker-compose.yml" "Docker Compose configuration"
check_file "requirements.txt" "Python dependencies"
echo

echo -e "${BLUE}🐳 Docker Configuration${NC}"
echo "-------------------------"
check_directory "docker" "Docker directory"
check_file "docker/Dockerfile" "Application container definition"
check_executable "docker/entrypoint.sh" "Container entrypoint script"
check_file ".dockerignore" "Docker ignore file"
echo

echo -e "${BLUE}🗄️ Database Configuration${NC}"
echo "---------------------------"
check_directory "docker/postgres" "PostgreSQL configuration directory"
check_directory "docker/postgres/init" "Database initialization directory"
check_file "docker/postgres/init/01-init-database.sql" "Database schema initialization"
check_directory "docker/postgres/config" "PostgreSQL config directory"
check_file "docker/postgres/config/postgresql.conf" "PostgreSQL configuration"
echo

echo -e "${BLUE}📊 Monitoring Configuration${NC}"
echo "-----------------------------"
check_directory "docker/prometheus" "Prometheus configuration directory"
check_file "docker/prometheus/prometheus.yml" "Prometheus configuration"
check_file "docker/prometheus/alert_rules.yml" "Prometheus alert rules"
check_file "docker/prometheus/recording_rules.yml" "Prometheus recording rules"
check_directory "docker/grafana" "Grafana configuration directory"
check_file "docker/grafana/grafana.ini" "Grafana configuration"
check_directory "docker/grafana/dashboards" "Grafana dashboards directory"
check_file "docker/grafana/dashboards/sentinel-overview.json" "Sentinel overview dashboard"
echo

echo -e "${BLUE}🔧 Management Scripts${NC}"
echo "----------------------"
check_directory "scripts" "Scripts directory"
check_executable "scripts/docker-env.sh" "Docker environment manager"
check_executable "scripts/status.sh" "System status checker"
check_executable "scripts/validate.sh" "Installation validator"
check_executable "scripts/test.sh" "Test suite runner"
check_executable "scripts/test-alerts.sh" "Alert system tester"
check_executable "scripts/benchmark.sh" "Performance testing"
check_executable "scripts/update.sh" "System updater"
check_executable "scripts/cleanup.sh" "System cleanup"
echo

echo -e "${BLUE}🖥️ Platform Installers${NC}"
echo "------------------------"
check_directory "windows" "Windows installation directory"
check_file "windows/install.ps1" "Windows PowerShell installer"
check_directory "linux" "Linux installation directory"
check_executable "linux/ShadowTrace Sentinel Server - Ubuntu.Debian.sh" "Linux installer script"
check_directory "macos" "macOS installation directory"
check_executable "macos/ShadowTrace Sentinel Server - macOS.sh" "macOS installer script"
echo

echo -e "${BLUE}🔍 Git Repository Status${NC}"
echo "-------------------------"
cd "$PROJECT_DIR"
if git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Git repository initialized${NC}"
    
    # Check if there are uncommitted changes
    if git diff-index --quiet HEAD --; then
        echo -e "${GREEN}✅ Working directory clean${NC}"
    else
        echo -e "${YELLOW}⚠️  There are uncommitted changes${NC}"
        git status --porcelain
    fi
    
    # Check remote origin
    if git remote get-url origin > /dev/null 2>&1; then
        ORIGIN_URL=$(git remote get-url origin)
        echo -e "${GREEN}✅ Remote origin configured: $ORIGIN_URL${NC}"
    else
        echo -e "${YELLOW}⚠️  No remote origin configured${NC}"
    fi
else
    echo -e "${RED}❌ Not a git repository${NC}"
fi
echo

echo -e "${BLUE}🚀 Quick Start Commands${NC}"
echo "------------------------"
echo "To set up the environment:"
echo -e "${YELLOW}  ./scripts/docker-env.sh setup${NC}"
echo
echo "To start all services:"
echo -e "${YELLOW}  ./scripts/docker-env.sh start${NC}"
echo
echo "To check service status:"
echo -e "${YELLOW}  ./scripts/docker-env.sh status${NC}"
echo
echo "To validate installation:"
echo -e "${YELLOW}  ./scripts/validate.sh${NC}"
echo

echo -e "${GREEN}🎉 Project verification complete!${NC}"
echo "============================================"
echo -e "${BLUE}Your ShadowTrace Sentinel Honeypot Suite is ready for deployment.${NC}"
