# --- Builder stage ---
FROM ubuntu:22.04 AS builder

# Environment variables for non-interactive install
ENV DEBIAN_FRONTEND=noninteractive

# Install Node.js 20, wget, unzip, curl
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    unzip \
    gnupg \
    ca-certificates \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && node -v \
    && npm -v

# Install Zola
ARG ZOLA_VERSION=0.20.0
RUN wget -qO /tmp/zola.tar.gz "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    && mkdir -p /tmp/zola \
    && tar -xzf /tmp/zola.tar.gz -C /tmp/zola \
    && mv /tmp/zola/zola /usr/local/bin/zola \
    && chmod +x /usr/local/bin/zola \
    && rm -rf /tmp/zola /tmp/zola.tar.gz

# Set working directory
WORKDIR /app

# Copy package files and install Node.js deps
COPY package*.json ./
RUN npm ci

# Copy project files
COPY . .

# Build frontend
RUN npm run build

# Build Zola static site
RUN zola build

# --- Production stage ---
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Zola runtime
ARG ZOLA_VERSION=0.19.2
RUN apt-get update && apt-get install -y wget unzip ca-certificates \
    && wget -qO /tmp/zola.tar.gz "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    && mkdir -p /tmp/zola \
    && tar -xzf /tmp/zola.tar.gz -C /tmp/zola \
    && mv /tmp/zola/zola /usr/local/bin/zola \
    && chmod +x /usr/local/bin/zola \
    && rm -rf /tmp/zola /tmp/zola.tar.gz

WORKDIR /app

# Copy built public folder
COPY --from=builder /app/public ./public
# Optional: copy config.toml if needed
COPY --from=builder /app/config.toml ./config.toml

EXPOSE 8080

# Serve site with Zola's built-in server (Render sets PORT)
CMD ["sh", "-c", "zola serve --interface 0.0.0.0 --port ${PORT:-8080}"]
