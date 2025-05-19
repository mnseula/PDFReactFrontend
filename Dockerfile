# syntax=docker/dockerfile:1.4
FROM node:18-alpine AS builder
WORKDIR /app

# 1. Install system dependencies
RUN apk add --no-cache \
    bash python3 make g++ \
    jpeg-dev cairo-dev pango-dev \
    git

# 2. Configure production environment
ENV NODE_ENV=production \
    CI=true \
    EXPO_USE_STATIC=1 \
    NPM_CONFIG_LOGLEVEL=verbose

# 3. Copy package files (will error if none exist, which is fine)
COPY package*.json ./
COPY yarn.lock* ./

# 3a. Conditionally copy package-lock.json if it exists
RUN if [ -f package-lock.json ]; then \
      echo "package-lock.json found, copying..."; \
      cp package-lock.json .; \
    else \
      echo "No package-lock.json found, continuing..."; \
    fi

# 4. Install dependencies - works with or without lockfile
RUN if [ -f yarn.lock ]; then \
      yarn install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then \
      npm ci --legacy-peer-deps; \
    else \
      npm install --legacy-peer-deps; \
    fi

# Rest of your Dockerfile remains the same...
