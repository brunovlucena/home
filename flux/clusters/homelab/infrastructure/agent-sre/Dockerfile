# 🚀 Ultra-Optimized Agent SRE Dockerfile
# Multi-stage build with Alpine Linux for minimal size

# Build stage - use Python 3.13 Alpine for smaller size
FROM python:3.13-alpine as builder

# Install build dependencies (minimal set)
RUN apk add --no-cache \
    gcc \
    musl-dev \
    libffi-dev \
    openssl-dev \
    curl \
    && rm -rf /var/cache/apk/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/uv

# Set working directory
WORKDIR /app

# Copy uv configuration files
COPY pyproject.toml uv.lock ./

# Create virtual environment and install dependencies with optimizations
RUN uv sync --frozen && \
    find /app/.venv -name "*.pyc" -delete && \
    find /app/.venv -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Production stage - ultra-minimal Alpine
FROM python:3.13-alpine as production

# Install only essential runtime dependencies
RUN apk add --no-cache \
    curl \
    ca-certificates \
    && rm -rf /var/cache/apk/*

# Set working directory
WORKDIR /app

# Copy virtual environment from builder stage
COPY --from=builder /app/.venv /app/.venv

# Copy only the essential application code
COPY main.py .

# Create non-root user with minimal permissions
RUN adduser -D -s /bin/sh appuser && \
    chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port
EXPOSE 8080

# Health check with timeout optimization
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Run the SRE agent script
CMD ["/app/.venv/bin/python", "main.py"]
