# ShadowTrace Sentinel Honeypot Suite - Application Container
# Multi-stage build for production-ready container

# Build stage
FROM python:3.11-slim-bullseye as builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    make \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Create application user
RUN useradd --create-home --shell /bin/bash sentinel

# Set working directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.11-slim-bullseye

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    netcat \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Create application user
RUN useradd --create-home --shell /bin/bash sentinel

# Create necessary directories
RUN mkdir -p /app /var/log/sentinel /var/lib/sentinel /etc/sentinel && \
    chown -R sentinel:sentinel /app /var/log/sentinel /var/lib/sentinel /etc/sentinel

# Copy Python packages from builder
COPY --from=builder /root/.local /home/sentinel/.local

# Copy application files
COPY --chown=sentinel:sentinel . /app/

# Set working directory
WORKDIR /app

# Switch to non-root user
USER sentinel

# Add local bin to PATH
ENV PATH=/home/sentinel/.local/bin:$PATH

# Environment variables
ENV PYTHONPATH=/app
ENV SENTINEL_HOME=/var/lib/sentinel
ENV SENTINEL_LOGS=/var/log/sentinel
ENV SENTINEL_CONFIG=/etc/sentinel

# Expose ports (honeypot services)
EXPOSE 22 23 80 443 3389 8080 8443

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Entry point
ENTRYPOINT ["/app/docker/entrypoint.sh"]
CMD ["sentinel", "start"]
