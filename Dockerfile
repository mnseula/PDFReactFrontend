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

# 3. Copy ALL package files including lockfile
COPY package*.json ./
COPY yarn.lock* ./
COPY package-lock.json* ./  # Add this line

# 4. Install dependencies - using regular install if lockfile is missing
RUN if [ -f package-lock.json ]; then \
      npm ci --legacy-peer-deps; \
    else \
      npm install --legacy-peer-deps; \
    fi

# 5. Install exact versions of critical dependencies
RUN npx expo install --check

# 6. Copy app code
COPY . .

# 7. Verify environment
RUN echo "Node version: $(node --version)" && \
    echo "NPM version: $(npm --version)" && \
    echo "Expo CLI version: $(npx expo --version)"

# 8. Build web export
RUN npx expo export:web && \
    # Verify the output exists
    [ -d "web-build" ] || { \
      echo "Build failed - web-build directory not created"; \
      mkdir -p web-build && \
      echo '<!DOCTYPE html><html><head><title>App Error</title></head><body><h1>Build Failed</h1><p>Check Docker build logs</p></body></html>' > web-build/index.html; \
      exit 1; \
    }

# --- Stage 2: Serve ---
FROM nginx:alpine

# Configure Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=builder /app/web-build /usr/share/nginx/html

EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
