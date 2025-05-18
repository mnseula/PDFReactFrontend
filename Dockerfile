# syntax=docker/dockerfile:1.4
# --- Stage 1: Build dependencies ---
FROM node:18-alpine AS dependencies
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install only production dependencies first
RUN npm ci --only=production --legacy-peer-deps

# --- Stage 2: Build app ---
FROM node:18-alpine AS builder
WORKDIR /app

# Install only the minimal required system dependencies with cleanup in the same layer
RUN apk add --no-cache --virtual .build-deps \
    python3 make g++ \
    jpeg-dev cairo-dev pango-dev giflib-dev \
    && rm -rf /var/cache/apk/*

# Copy production node_modules
COPY --from=dependencies /app/node_modules ./node_modules

# Set environment variables
ENV NODE_ENV=production \
    CI=true \
    EXPO_USE_STATIC=1

# Copy only necessary app files
COPY package*.json ./
COPY app.json ./
COPY tsconfig*.json ./
COPY babel.config.js ./
COPY ./src ./src
COPY ./assets ./assets
COPY ./public ./public

# Install missing Expo runtime for web support
RUN npx expo install @expo/metro-runtime

# Export the web build
RUN npx expo export --platform web

# --- Stage 3: Serve ---
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Configure NGINX for port 9091 and cache control
RUN sed -i 's/listen\(.*\)80;/listen\19091;/' /etc/nginx/conf.d/default.conf && \
    printf 'location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff2)$ {\n  expires 1y;\n  add_header Cache-Control "public, immutable";\n}\n' \
    >> /etc/nginx/conf.d/default.conf

# Copy only the built files from the builder stage
COPY --from=builder /app/dist .

EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
