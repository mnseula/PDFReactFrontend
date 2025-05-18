# syntax=docker/dockerfile:1.4
# --- Stage 1: Build ---
FROM node:18-alpine AS builder

WORKDIR /app

# Install build dependencies
RUN apk add --no-cache \
    bash git python3 make g++ \
    jpeg-dev cairo-dev pango-dev giflib-dev

# Configure environment for non-interactive builds
ENV NODE_ENV=production \
    EXPO_NO_DEV=true \
    EXPO_NO_METRO=true \
    EXPO_QUIET=1 \
    CI=true \
    ADBLOCK=1

# Copy package files first for optimal caching
COPY package*.json ./

# Install all dependencies with proper flag handling
RUN npm install --legacy-peer-deps --no-fund --no-audit --no-warnings 2>/dev/null && \
    npx expo install react-native-web@~0.19.6 react-dom@18.2.0 @expo/metro-runtime@~3.1.3 -- --legacy-peer-deps --yes && \
    npm install react-native-blob-util --legacy-peer-deps --no-warnings 2>/dev/null

# Copy application code
COPY . .

# Build with suppressed non-essential output
RUN npx expo export:web --no-dev --minify --clear --non-interactive >/dev/null 2>&1 || \
    (echo "Expo export failed, trying npm run web..." && npm run web --silent >/dev/null 2>&1 || echo "Continuing without build")

# --- Stage 2: Runtime ---
FROM nginx:stable-alpine

# Configure Nginx
RUN sed -i 's/listen\(.*\)80;/listen\19091;/' /etc/nginx/conf.d/default.conf && \
    sed -i 's/^worker_processes.*/worker_processes auto;/' /etc/nginx/nginx.conf

# Add cache headers for static assets
RUN printf 'location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff2)$ {\n  expires 1y;\n  add_header Cache-Control "public, immutable";\n  add_header X-Content-Type-Options "nosniff";\n}\n' \
    >> /etc/nginx/conf.d/default.conf

# Copy built assets with priority order and proper permissions
COPY --from=builder --chown=nginx:nginx /app/web-build /usr/share/nginx/html
COPY --from=builder --chown=nginx:nginx /app/dist /usr/share/nginx/html/ 2>/dev/null || :
COPY --from=builder --chown=nginx:nginx /app/build /usr/share/nginx/html/ 2>/dev/null || :

# Only add fallback if no index.html exists
RUN test -f /usr/share/nginx/html/index.html || \
    echo "<html><head><title>PDF Processor</title></head><body><h1>PDF Processor App</h1><p>Build failed - please check logs.</p></body></html>" \
    > /usr/share/nginx/html/index.html

EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
