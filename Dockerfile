# --- Stage 1: Build ---
FROM node:18-alpine AS builder

WORKDIR /app

# 1. Install system dependencies
RUN apk add --no-cache \
    bash git python3 make g++ \
    jpeg-dev cairo-dev pango-dev giflib-dev

# 2. Configure environment
ENV NODE_ENV=production \
    EXPO_NO_DEV=true \
    EXPO_NO_METRO=true \
    CI=true

# 3. Copy package files first
COPY package*.json ./

# 4. Install dependencies with web support
RUN npm install --legacy-peer-deps && \
    npm install react-native-web@~0.19.6 @expo/webpack-config @expo/metro-config --legacy-peer-deps

# 5. Copy app code
COPY . .

# 6. Debug web export - remove output suppression
RUN npx expo export:web --no-dev --minify --clear

# --- Stage 2: Serve ---
FROM nginx:alpine
COPY --from=builder /app/web-build /usr/share/nginx/html
EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
