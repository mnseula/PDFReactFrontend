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
    EXPO_USE_STATIC=1

# 3. Copy and install dependencies
COPY package*.json ./

# Install dependencies (including expo cli if needed)
RUN npm install --legacy-peer-deps

# ✅ Explicitly install missing Expo web dependency
RUN npx expo install @expo/metro-runtime

# 4. Copy full app
COPY . .

# 5. Optional: Add Metro alias to fix Platform import issue (if still needed)
# This can often be omitted with correct versions
RUN echo "module.exports = {" \
    "resolver: {" \
    "extraNodeModules: {" \
    "'../Utilities/Platform': require.resolve('react-native/Libraries/Utilities/Platform')" \
    "}" \
    "}" \
    "};" > metro.config.js

# 6. Export the web build
RUN npx expo export --platform web

# --- Stage 2: Serve ---
FROM nginx:alpine

# Change port to 9091 and add caching
RUN sed -i 's/listen\(.*\)80;/listen\19091;/' /etc/nginx/conf.d/default.conf && \
    printf 'location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff2)$ {\n  expires 1y;\n  add_header Cache-Control "public, immutable";\n}\n' \
    >> /etc/nginx/conf.d/default.conf

# Copy exported web build
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
