# Set Zola version globally
ARG ZOLA_VERSION=0.20.1

# --- builder stage ---
FROM node:20-bullseye AS builder

# bring the ARG into scope again inside this stage
ARG ZOLA_VERSION

RUN apt-get update \
  && apt-get install -y --no-install-recommends wget ca-certificates unzip \
  && rm -rf /var/lib/apt/lists/*

# install zola into builder
RUN wget -qO /tmp/zola.tar.gz "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
  && mkdir -p /tmp/zola \
  && tar -xzf /tmp/zola.tar.gz -C /tmp/zola \
  && mv /tmp/zola/zola /usr/local/bin/zola \
  && chmod +x /usr/local/bin/zola \
  && rm -rf /tmp/zola /tmp/zola.tar.gz

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build

RUN zola build 

# --- final stage ---
FROM debian:bullseye-slim

ARG ZOLA_VERSION

RUN apt-get update \
  && apt-get install -y --no-install-recommends wget ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN wget -qO /tmp/zola.tar.gz "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
  && mkdir -p /tmp/zola \
  && tar -xzf /tmp/zola.tar.gz -C /tmp/zola \
  && mv /tmp/zola/zola /usr/local/bin/zola \
  && chmod +x /usr/local/bin/zola \
  && rm -rf /tmp/zola /tmp/zola.tar.gz

WORKDIR /app

COPY --from=builder /app/public ./public
COPY --from=builder /app/config.toml ./config.toml

EXPOSE 8080

CMD ["sh", "-c", "zola serve --root /app --interface 0.0.0.0 --port ${PORT:-8080}"]
