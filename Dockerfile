# syntax=docker/dockerfile:1.4
# --- Stage 1: Build ---
FROM node:18-alpine AS builder
WORKDIR /app

# 1. Install system dependencies
RUN apk add --no-cache \
    bash git python3 make g++ \
    jpeg-dev cairo-dev pango-dev giflib-dev

# 2. Set environment variables
ENV NODE_ENV=production \
    CI=true \
    EXPO_USE_STATIC=1 \
    NPM_CONFIG_LOGLEVEL=verbose

# 3. Copy package files first for better layer caching
COPY package*.json ./

# 4. Install dependencies with improved error handling and networking settings
RUN npm cache clean --force && \
    npm config set network-timeout 300000 && \
    npm install --legacy-peer-deps --no-optional || \
    (cat /root/.npm/_logs/*-debug-0.log && exit 1)

# 5. Install missing Expo runtime for web support
RUN npx expo install @expo/metro-runtime

# 6. Copy the full app
COPY . .

# 7. Export the web build
RUN npx expo export --platform web

# --- Stage 2: Serve ---
FROM nginx:alpine

# Configure NGINX for port 9091 and cache control
RUN sed -i 's/listen\(.*\)80;/listen\19091;/' /etc/nginx/conf.d/default.conf && \
    printf 'location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff2)$ {\n  expires 1y;\n  add_header Cache-Control "public, immutable";\n}\n' \
    >> /etc/nginx/conf.d/default.conf

# Copy static build to web root
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
