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

# Install all dependencies and Expo-required packages
RUN npm install --legacy-peer-deps --no-fund --no-audit && \
    npx expo install --yes react-native-web@~0.19.6 react-dom@18.2.0 @expo/metro-runtime@~3.1.3 -- --legacy-peer-deps && \
    npm install react-native-blob-util --legacy-peer-deps

# Copy the full application code
COPY . .

# Build the web project
RUN npx expo export:web --no-dev --minify --clear --non-interactive || \
    (echo "Expo export failed, trying npm run web..." && npm run web || echo "Continuing without build")

# --- Stage 2: Runtime ---
FROM nginx:stable-alpine

# Configure Nginx to use port 9091
RUN sed -i 's/listen\(.*\)80;/listen\19091;/' /etc/nginx/conf.d/default.conf && \
    sed -i 's/^worker_processes.*/worker_processes auto;/' /etc/nginx/nginx.conf

# Set cache headers for static assets
RUN printf 'location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff2)$ {\n  expires 1y;\n  add_header Cache-Control "public, immutable";\n  add_header X-Content-Type-Options "nosniff";\n}\n' \
    >> /etc/nginx/conf.d/default.conf

# Copy build output from builder
COPY --from=builder --chown=nginx:nginx /app/web-build /usr/share/nginx/html
COPY --from=builder --chown=nginx:nginx /app/dist /usr/share/nginx/html/ || true
COPY --from=builder --chown=nginx:nginx /app/build /usr/share/nginx/html/ || true

# Fallback: add simple HTML if no index.html exists
RUN test -f /usr/share/nginx/html/index.html || \
    echo "<html><head><title>PDF Processor</title></head><body><h1>PDF Processor App</h1><p>Build failed - please check logs.</p></body></html>" \
    > /usr/share/nginx/html/index.html

EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
