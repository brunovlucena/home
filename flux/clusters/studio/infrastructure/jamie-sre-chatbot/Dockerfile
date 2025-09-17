# Multi-stage build for Jamie SRE Chatbot
FROM python:3.11-slim as builder

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements and install Python dependencies
COPY src/requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Production stage
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Create non-root user
RUN groupadd -r jamie && useradd -r -g jamie jamie

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy Python packages from builder
COPY --from=builder /root/.local /home/jamie/.local

# Copy application files
COPY src/app.py .

# Set environment variables
ENV PATH=/home/jamie/.local/bin:$PATH
ENV PYTHONPATH=/app
ENV PYTHONUNBUFFERED=1

# Logfire configuration
ENV LOGFIRE_TOKEN=""
ENV ENVIRONMENT="production"
ENV LOGFIRE_CONSOLE=false
ENV LOGFIRE_SEND_TO_LOGFIRE=true

# Create necessary directories
RUN mkdir -p /app/logs && chown -R jamie:jamie /app

# Switch to non-root user
USER jamie

# Run the application
CMD ["python", "app.py"]
