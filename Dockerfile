# --- Builder stage ---
FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install Node.js 20 + dependencies
RUN apt-get update && apt-get install -y \
    curl wget unzip ca-certificates gnupg build-essential \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs \
    && node -v \
    && npm -v

# Install Zola
ARG ZOLA_VERSION=0.19.2
RUN wget -qO /tmp/zola.tar.gz "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    && mkdir -p /tmp/zola \
    && tar -xzf /tmp/zola.tar.gz -C /tmp/zola \
    && mv /tmp/zola/zola /usr/local/bin/zola \
    && chmod +x /usr/local/bin/zola \
    && rm -rf /tmp/zola /tmp/zola.tar.gz

WORKDIR /app

# Install Node.js deps
COPY package*.json ./
RUN npm ci

# Copy project
COPY . .

# Build frontend
RUN npm run build

# Build Zola static site
RUN zola build

# --- Production stage ---
FROM nginx:stable-alpine

# Copy built static site
COPY --from=builder /app/public /usr/share/nginx/html

# Expose port 80 (Render uses this for static hosting)
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
