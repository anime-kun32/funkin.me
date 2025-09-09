# --- Builder stage ---
FROM ubuntu:22.04 AS builder
ENV DEBIAN_FRONTEND=noninteractive

# Install Node + dependencies
RUN apt-get update && apt-get install -y curl wget unzip ca-certificates gnupg build-essential \
    && rm -rf /var/lib/apt/lists/*

# Node.js 20
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Install Zola
ARG ZOLA_VERSION=0.19.2
RUN wget -qO /tmp/zola.tar.gz "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    && mkdir -p /tmp/zola \
    && tar -xzf /tmp/zola.tar.gz -C /tmp/zola \
    && mv /tmp/zola/zola /usr/local/bin/zola \
    && chmod +x /usr/local/bin/zola \
    && rm -rf /tmp/zola /tmp/zola.tar.gz

# Set working directory to repo root
WORKDIR /app

# Copy everything from repo root
COPY . .

# Install Node deps and build frontend
RUN npm ci
RUN npm run build

# Build Zola site (repo root contains config.toml, content, templates)
RUN zola build

# --- Production stage ---
FROM nginx:stable-alpine

# Copy static site only
COPY --from=builder /app/public /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
