# Environment Setup Guide

## Overview

This guide explains how to set up your environment configuration for the ShadowTrace Sentinel Honeypot Suite, with special considerations for users who may have existing configurations in the PostgresAI directory.

## Quick Setup

### 1. Automatic Setup (Recommended)

```bash
# Run the automated setup script
./scripts/docker-env.sh setup
```

This will:
- Create a `.env` file from the `.env.template`
- Generate secure random passwords for all services
- Validate the configuration

### 2. Manual Setup

If you prefer manual configuration:

```bash
# Copy the template
cp .env.template .env

# Edit the file with your preferred editor
nano .env
# or
vim .env
```

## Important Security Notes

### 🔒 Environment File Security

- **Never commit your `.env` file to git** - it contains sensitive credentials
- The `.env` file is automatically ignored by git for security
- Always use strong, unique passwords in production
- The template contains placeholder values that MUST be changed

### 🔄 Migrating from PostgresAI Directory

If you have an existing `.env` file in the PostgresAI directory (`/Volumes/NASté-DockerHD/|Projects (Holding)/GitHub/Active Repos/PostgresAI/.env`), you can reference it when setting up your configuration:

```bash
# View your existing PostgresAI configuration (read-only)
cat "/Volumes/NASté-DockerHD/|Projects (Holding)/GitHub/Active Repos/PostgresAI/.env"

# Create your new .env file from template
cp .env.template .env

# Edit the new .env file and copy relevant settings from your PostgresAI configuration
nano .env
```

**Important:** Don't directly copy the PostgresAI .env file, as the ShadowTrace Sentinel project may have different configuration requirements.

## Configuration Variables

### Required Variables (Must Change)

These variables have placeholder values and MUST be updated:

```bash
POSTGRES_PASSWORD=CHANGE_THIS_PASSWORD_NOW
SENTINEL_SECRET_KEY=GENERATE_32_CHARACTER_SECRET_KEY
SENTINEL_JWT_SECRET=GENERATE_JWT_SECRET_KEY
SENTINEL_ENCRYPTION_KEY=GENERATE_32_CHAR_ENCRYPTION_KEY
```

### Optional Variables

These can be customized based on your environment:

```bash
SENTINEL_EMAIL=alerts@yourdomain.com
SENTINEL_WEBHOOK_URL=https://your-webhook-endpoint.com
POSTGRES_DB=sentinel_honeypot
POSTGRES_USER=sentinel_admin
```

## Password Generation

The setup script automatically generates secure passwords, but you can also generate them manually:

```bash
# Generate a secure password (32 characters)
openssl rand -base64 32 | tr -d "=+/" | cut -c1-25

# Generate a hex key (32 characters)
openssl rand -hex 16

# Generate a secret key (64 characters)
openssl rand -base64 64 | tr -d "=+/" | cut -c1-64
```

## Validation

After setup, validate your configuration:

```bash
# Validate environment configuration
./scripts/docker-env.sh validate

# Test the setup
./scripts/docker-env.sh start
./scripts/docker-env.sh status
```

## Troubleshooting

### Common Issues

1. **Permission denied when running setup:**
   ```bash
   chmod +x scripts/docker-env.sh
   ```

2. **Docker not running:**
   - Start Docker Desktop (macOS/Windows)
   - Start Docker service (Linux): `sudo systemctl start docker`

3. **Environment validation fails:**
   - Check that all placeholder values have been replaced
   - Ensure passwords meet minimum requirements

### Getting Help

If you encounter issues:
1. Check the [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
2. Review Docker logs: `./scripts/docker-env.sh logs`
3. Open an issue on GitHub

## File Structure

After setup, your environment files will be:

```
.env.template          # Template file (committed to git)
.env                   # Your actual configuration (ignored by git)
.gitignore             # Ensures .env is never committed
docker-compose.yml     # Docker services configuration
scripts/docker-env.sh  # Environment management script
```

## Security Best Practices

1. **Regular password rotation** - Change passwords periodically
2. **Backup encryption keys** - Store encryption keys securely
3. **Monitor access logs** - Review who accesses the environment
4. **Use environment isolation** - Separate dev/staging/production environments
5. **Audit configuration** - Regular security reviews of settings
