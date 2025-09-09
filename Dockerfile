# Start with Node.js base (we’ll install Zola manually)
FROM node:20-bullseye AS builder

# Install dependencies needed for Zola
RUN apt-get update && apt-get install -y wget unzip \
    && wget https://github.com/getzola/zola/releases/download/v0.19.2/zola-v0.19.2-x86_64-unknown-linux-gnu.tar.gz \
    && tar -xvzf zola-v0.19.2-x86_64-unknown-linux-gnu.tar.gz -C /usr/local/bin \
    && rm zola-v0.19.2-x86_64-unknown-linux-gnu.tar.gz

# Set working dir
WORKDIR /app

# Copy package files and install deps
COPY package*.json ./
RUN npm install

# Copy rest of project
COPY . .

# Build frontend
RUN npm run build

# Build Zola static site
RUN zola build

# ---- Production image ----
FROM debian:bullseye-slim

# Install Zola only (lighter final image)
RUN apt-get update && apt-get install -y wget unzip \
    && wget https://github.com/getzola/zola/releases/download/v0.19.2/zola-v0.19.2-x86_64-unknown-linux-gnu.tar.gz \
    && tar -xvzf zola-v0.19.2-x86_64-unknown-linux-gnu.tar.gz -C /usr/local/bin \
    && rm zola-v0.19.2-x86_64-unknown-linux-gnu.tar.gz

WORKDIR /app

# Copy built site
COPY --from=builder /app/public ./public

# Expose port
EXPOSE 1111

# Run Zola's built-in server
CMD ["zola", "serve", "--interface", "0.0.0.0", "--port", "1111"]
