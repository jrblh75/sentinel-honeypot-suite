#!/bin/bash

# ShadowTrace Sentinel - Docker Environment Manager
# This script manages the PostgreSQL Docker environment for the honeypot suite

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Environment file path
ENV_FILE="${PROJECT_ROOT}/.env"
ENV_TEMPLATE="${PROJECT_ROOT}/.env.template"

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
    print_success "Docker is running"
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
        print_error "Docker Compose is not available. Please install Docker Compose."
        exit 1
    fi
    print_success "Docker Compose is available"
}

# Function to create .env file from template
create_env_file() {
    if [[ ! -f "$ENV_FILE" ]]; then
        if [[ -f "$ENV_TEMPLATE" ]]; then
            print_warning ".env file not found. Creating from template..."
            cp "$ENV_TEMPLATE" "$ENV_FILE"
            print_success ".env file created from template"
            print_warning ""
            print_warning "IMPORTANT: Please edit the .env file and update ALL default passwords and secrets!"
            print_warning "Never use default values in production!"
            print_warning ""
            print_warning "Note: If you have an existing .env file in the PostgresAI directory,"
            print_warning "you can copy relevant settings from there to your new .env file."
        else
            print_error ".env template file not found at $ENV_TEMPLATE"
            exit 1
        fi
    else
        print_success ".env file exists"
    fi
}

# Function to validate environment variables
validate_env() {
    print_status "Validating environment configuration..."
    
    # Source the .env file
    if [[ -f "$ENV_FILE" ]]; then
        set -a
        source "$ENV_FILE"
        set +a
    else
        print_error ".env file not found"
        exit 1
    fi
    
    # Check critical variables
    local errors=0
    
    # Database configuration
    if [[ -z "${POSTGRES_PASSWORD:-}" ]] || [[ "$POSTGRES_PASSWORD" == "CHANGE_THIS_PASSWORD_NOW" ]]; then
        print_error "POSTGRES_PASSWORD must be set to a secure value"
        ((errors++))
    fi
    
    if [[ -z "${SENTINEL_SECRET_KEY:-}" ]] || [[ "$SENTINEL_SECRET_KEY" == "GENERATE_32_CHARACTER_SECRET_KEY" ]]; then
        print_error "SENTINEL_SECRET_KEY must be set to a secure 32-character value"
        ((errors++))
    fi
    
    if [[ -z "${SENTINEL_JWT_SECRET:-}" ]] || [[ "$SENTINEL_JWT_SECRET" == "GENERATE_JWT_SECRET_KEY" ]]; then
        print_error "SENTINEL_JWT_SECRET must be set to a secure value"
        ((errors++))
    fi
    
    if [[ -z "${SENTINEL_ENCRYPTION_KEY:-}" ]] || [[ "$SENTINEL_ENCRYPTION_KEY" == "GENERATE_32_CHAR_ENCRYPTION_KEY" ]]; then
        print_error "SENTINEL_ENCRYPTION_KEY must be set to a secure value"
        ((errors++))
    fi
    
    # Additional service passwords
    if [[ -z "${REDIS_PASSWORD:-}" ]] || [[ "$REDIS_PASSWORD" == "CHANGE_REDIS_PASSWORD" ]]; then
        print_error "REDIS_PASSWORD must be set to a secure value"
        ((errors++))
    fi
    
    if [[ -z "${GRAFANA_PASSWORD:-}" ]] || [[ "$GRAFANA_PASSWORD" == "CHANGE_GRAFANA_PASSWORD" ]]; then
        print_error "GRAFANA_PASSWORD must be set to a secure value"
        ((errors++))
    fi
    
    # Check required PostgreSQL performance variables
    if [[ -z "${POSTGRES_SHARED_BUFFERS:-}" ]]; then
        print_error "POSTGRES_SHARED_BUFFERS must be set"
        ((errors++))
    fi
    
    # Check Docker configuration
    if [[ -z "${DOCKER_SUBNET:-}" ]]; then
        print_error "DOCKER_SUBNET must be set"
        ((errors++))
    fi
    
    # Check backup configuration if enabled
    if [[ "${BACKUP_ENABLED:-false}" == "true" ]]; then
        if [[ -z "${BACKUP_SCHEDULE:-}" ]]; then
            print_error "BACKUP_SCHEDULE must be set when backups are enabled"
            ((errors++))
        fi
        
        if [[ -z "${BACKUP_RETENTION_DAYS:-}" ]]; then
            print_error "BACKUP_RETENTION_DAYS must be set when backups are enabled"
            ((errors++))
        fi
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_success "Environment validation passed"
        return 0
    else
        print_error "Environment validation failed with $errors errors"
        print_warning "Please update your .env file with secure values"
        return 1
    fi
}

# Function to generate secure passwords
generate_passwords() {
    print_status "Generating secure passwords and secrets..."
    
    # Generate random passwords and keys
    local postgres_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    local sentinel_secret=$(openssl rand -hex 32)
    local jwt_secret=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-64)
    local encryption_key=$(openssl rand -hex 16)
    local webhook_secret=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)
    local redis_password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    local grafana_password=$(openssl rand -base64 16 | tr -d "=+/" | cut -c1-16)
    local backup_encryption_key=$(openssl rand -hex 16)
    
    # Update .env file with all generated values
    sed -i.bak \
        -e "s/POSTGRES_PASSWORD=.*/POSTGRES_PASSWORD=$postgres_password/" \
        -e "s/SENTINEL_SECRET_KEY=.*/SENTINEL_SECRET_KEY=$sentinel_secret/" \
        -e "s/SENTINEL_JWT_SECRET=.*/SENTINEL_JWT_SECRET=$jwt_secret/" \
        -e "s/SENTINEL_ENCRYPTION_KEY=.*/SENTINEL_ENCRYPTION_KEY=$encryption_key/" \
        -e "s/SENTINEL_WEBHOOK_SECRET=.*/SENTINEL_WEBHOOK_SECRET=$webhook_secret/" \
        -e "s/REDIS_PASSWORD=.*/REDIS_PASSWORD=$redis_password/" \
        -e "s/GRAFANA_PASSWORD=.*/GRAFANA_PASSWORD=$grafana_password/" \
        -e "s/BACKUP_ENCRYPTION_KEY=.*/BACKUP_ENCRYPTION_KEY=$backup_encryption_key/" \
        "$ENV_FILE"
    
    # Update DATABASE_URL to use the new password
    local database_url="postgresql://\${POSTGRES_USER}:\${POSTGRES_PASSWORD}@\${POSTGRES_HOST}:\${POSTGRES_PORT}/\${POSTGRES_DB}"
    sed -i.bak2 "s|DATABASE_URL=.*|DATABASE_URL=$database_url|" "$ENV_FILE"
    
    # Clean up backup files
    rm -f "${ENV_FILE}.bak" "${ENV_FILE}.bak2"
    
    print_success "Secure passwords generated and saved to .env file"
    print_warning "Backup files cleaned up automatically"
    
    # Display a summary of what was generated
    print_status "Generated the following secure credentials:"
    echo "  - PostgreSQL password (25 characters)"
    echo "  - Sentinel secret key (64 characters)"
    echo "  - JWT secret (64 characters)"
    echo "  - Encryption key (32 characters)"
    echo "  - Webhook secret (32 characters)"
    echo "  - Redis password (25 characters)"
    echo "  - Grafana password (16 characters)"
    echo "  - Backup encryption key (32 characters)"
}

# Function to start the Docker environment
start_services() {
    print_status "Starting ShadowTrace Sentinel services..."
    
    cd "$PROJECT_ROOT"
    
    # Start core services
    docker-compose up -d postgres redis
    
    print_status "Waiting for PostgreSQL to be ready..."
    sleep 10
    
    # Check if PostgreSQL is ready
    local retries=30
    while ! docker-compose exec -T postgres pg_isready -U "${POSTGRES_USER:-sentinel_admin}" >/dev/null 2>&1; do
        if [[ $retries -eq 0 ]]; then
            print_error "PostgreSQL failed to start within expected time"
            exit 1
        fi
        print_status "Waiting for PostgreSQL... ($retries retries left)"
        sleep 2
        ((retries--))
    done
    
    print_success "PostgreSQL is ready"
    
    # Start remaining services
    docker-compose up -d
    
    print_success "All services started successfully"
}

# Function to stop the Docker environment
stop_services() {
    print_status "Stopping ShadowTrace Sentinel services..."
    
    cd "$PROJECT_ROOT"
    docker-compose down
    
    print_success "All services stopped"
}

# Function to show service status
show_status() {
    print_status "Service Status:"
    
    cd "$PROJECT_ROOT"
    docker-compose ps
}

# Function to show logs
show_logs() {
    local service="${1:-}"
    
    cd "$PROJECT_ROOT"
    
    if [[ -n "$service" ]]; then
        print_status "Showing logs for service: $service"
        docker-compose logs -f "$service"
    else
        print_status "Showing logs for all services:"
        docker-compose logs -f
    fi
}

# Function to connect to PostgreSQL
connect_db() {
    print_status "Connecting to PostgreSQL database..."
    
    cd "$PROJECT_ROOT"
    
    # Source environment variables
    set -a
    source "$ENV_FILE"
    set +a
    
    docker-compose exec postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
}

# Function to backup database
backup_db() {
    local backup_file="${1:-backup_$(date +%Y%m%d_%H%M%S).sql}"
    
    print_status "Creating database backup: $backup_file"
    
    cd "$PROJECT_ROOT"
    
    # Create backups directory if it doesn't exist
    mkdir -p backups
    
    # Source environment variables
    set -a
    source "$ENV_FILE"
    set +a
    
    docker-compose exec -T postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "backups/$backup_file"
    
    print_success "Database backup created: backups/$backup_file"
}

# Function to restore database
restore_db() {
    local backup_file="${1:-}"
    
    if [[ -z "$backup_file" ]]; then
        print_error "Please specify a backup file to restore"
        exit 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        print_error "Backup file not found: $backup_file"
        exit 1
    fi
    
    print_warning "This will overwrite the current database. Are you sure? (y/N)"
    read -r confirmation
    
    if [[ "$confirmation" != "y" && "$confirmation" != "Y" ]]; then
        print_status "Database restore cancelled"
        exit 0
    fi
    
    print_status "Restoring database from: $backup_file"
    
    cd "$PROJECT_ROOT"
    
    # Source environment variables
    set -a
    source "$ENV_FILE"
    set +a
    
    docker-compose exec -T postgres psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$backup_file"
    
    print_success "Database restored successfully"
}

# Function to show help
show_help() {
    echo "ShadowTrace Sentinel - Docker Environment Manager"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  setup              Initial setup (create .env, generate passwords)"
    echo "  start              Start all services"
    echo "  stop               Stop all services"
    echo "  restart            Restart all services"
    echo "  status             Show service status"
    echo "  logs [service]     Show logs (optionally for specific service)"
    echo "  db-connect         Connect to PostgreSQL database"
    echo "  db-backup [file]   Create database backup"
    echo "  db-restore <file>  Restore database from backup"
    echo "  validate           Validate environment configuration"
    echo "  generate-passwords Generate secure passwords for .env file"
    echo "  help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup           # Initial setup"
    echo "  $0 start           # Start all services"
    echo "  $0 logs postgres   # Show PostgreSQL logs"
    echo "  $0 db-backup       # Create timestamped backup"
    echo ""
}

# Main script logic
main() {
    local command="${1:-help}"
    
    case "$command" in
        "setup")
            check_docker
            check_docker_compose
            create_env_file
            generate_passwords
            validate_env
            print_success "Setup completed! You can now run '$0 start' to start the services."
            ;;
        "start")
            check_docker
            check_docker_compose
            validate_env || exit 1
            start_services
            ;;
        "stop")
            check_docker
            stop_services
            ;;
        "restart")
            check_docker
            stop_services
            start_services
            ;;
        "status")
            check_docker
            show_status
            ;;
        "logs")
            check_docker
            show_logs "${2:-}"
            ;;
        "db-connect")
            check_docker
            connect_db
            ;;
        "db-backup")
            check_docker
            backup_db "${2:-}"
            ;;
        "db-restore")
            check_docker
            restore_db "${2:-}"
            ;;
        "validate")
            validate_env
            ;;
        "generate-passwords")
            generate_passwords
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Run main function with all arguments
main "$@"
