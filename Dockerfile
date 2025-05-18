# syntax=docker/dockerfile:1.4

# --- Stage 1: Build ---
FROM node:18-alpine AS builder

WORKDIR /app

# 1. Install system dependencies required for building some native packages
RUN apk add --no-cache \
    bash git python3 make g++ \
    jpeg-dev cairo-dev pango-dev giflib-dev

# 2. Configure production environment
ENV NODE_ENV=production \
    CI=true \
    EXPO_USE_STATIC=1

# 3. Copy package files for dependency installation and caching
COPY package*.json ./

# 4. Install dependencies and critical Expo packages
RUN npm install --legacy-peer-deps --ignore-scripts && \
    npx expo install react-native@0.73.6 -- --legacy-peer-deps && \
    npx expo install react-dom@18.2.0 react-native-web@~0.19.6 @expo/webpack-config -- --legacy-peer-deps && \
    npm install --legacy-peer-deps @expo/metro-runtime react-native-blob-util

# 5. Apply web compatibility fix for Platform module resolution
RUN sed -i "s/require('..\/Utilities\/Platform')/require('react-native\/dist\/exports\/Platform')/g" \
    node_modules/react-native/Libraries/NativeComponent/NativeComponentRegistry.js && \
    sed -i "s/require('..\/Utilities\/Platform')/require('react-native\/dist\/exports\/Platform')/g" \
    node_modules/react-native/Libraries/Utilities/codegenNativeComponent.js

# 6. Copy application source code
COPY . .

# 7. Build the web version of the app
RUN npx expo export --platform web

# --- Stage 2: Serve ---
FROM nginx:alpine

# 8. Configure Nginx to use a custom port and caching headers
RUN sed -i 's/listen\(.*\)80;/listen\19091;/' /etc/nginx/conf.d/default.conf && \
    printf 'location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|webp|woff2)$ {\n  expires 1y;\n  add_header Cache-Control "public, immutable";\n}\n' \
    >> /etc/nginx/conf.d/default.conf

# 9. Copy the web-build folder from the builder stage to Nginx's HTML folder
COPY --from=builder --chown=nginx:nginx /app/dist /usr/share/nginx/html

# 10. Expose the custom port and start Nginx
EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
