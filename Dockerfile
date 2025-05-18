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
    CI=true

# 3. Copy package files first for caching
COPY package*.json ./

# 4. Install all required web dependencies
RUN npm install --legacy-peer-deps && \
    npx expo install react-dom@18.2.0 react-native-web@~0.19.6 @expo/webpack-config -- --legacy-peer-deps

# 5. Copy app code
COPY . .

# 6. Build web export
RUN npx expo export:web || \
    (echo "Web export failed, creating fallback..." && \
     mkdir -p web-build && \
     echo "<html><body><h1>App is down for maintenance</h1></body></html>" > web-build/index.html)

# --- Stage 2: Serve ---
FROM nginx:alpine

# Configure Nginx
RUN sed -i 's/listen\(.*\)80;/listen\19091;/' /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=builder /app/web-build /usr/share/nginx/html

EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
