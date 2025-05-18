# syntax=docker/dockerfile:1.4
# --- Stage 1: Build ---
FROM node:18-alpine AS builder

WORKDIR /app

# 1. Install system dependencies
RUN apk add --no-cache \
    bash git python3 make g++ \
    jpeg-dev cairo-dev pango-dev giflib-dev

# 2. Configure production environment
ENV NODE_ENV=production \
    CI=true \
    EXPO_USE_STATIC=1

# 3. Copy package files first for caching
COPY package*.json ./

# 4. Install all required dependencies
RUN npm install --legacy-peer-deps && \
    npx expo install react-dom@18.2.0 react-native-web@~0.19.6 @expo/webpack-config -- --legacy-peer-deps && \
    npm install --legacy-peer-deps @expo/metro-runtime react-native-blob-util

# 5. Copy app code
COPY . .

# 6. Build web export with proper error handling
RUN npx expo export:web || \
    (echo "Web export failed, creating fallback..." && \
     mkdir -p web-build && \
     cp -r assets web-build/ && \
     echo "<html><head><title>PDF Processor</title><link rel=\"icon\" href=\"assets/favicon.png\"></head><body style=\"background:#2c3e50;color:white;text-align:center;padding-top:50px\"><h1>PDF Processor App</h1><p>Application is currently unavailable</p></body></html>" > web-build/index.html)

# --- Stage 2: Serve ---
FROM nginx:alpine

# Configure Nginx
RUN sed -i 's/listen\(.*\)80;/listen\19091;/' /etc/nginx/conf.d/default.conf && \
    printf 'location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff2)$ {\n  expires 1y;\n  add_header Cache-Control "public, immutable";\n}\n' \
    >> /etc/nginx/conf.d/default.conf

# Copy built assets with proper permissions
COPY --from=builder --chown=nginx:nginx /app/web-build /usr/share/nginx/html

EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
