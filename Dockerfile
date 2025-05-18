# syntax=docker/dockerfile:1.4
FROM node:18-alpine AS builder

WORKDIR /app

# 1. Install system dependencies
RUN apk add --no-cache \
    bash python3 make g++ \
    jpeg-dev cairo-dev pango-dev

# 2. Configure production environment
ENV NODE_ENV=production \
    CI=true \
    EXPO_USE_STATIC=1

# 3. Copy package files first for caching
COPY package*.json ./

# 4. Install dependencies
RUN npm install --legacy-peer-deps && \
    npx expo install react-native@0.73.6 react-dom@18.2.0 react-native-web@~0.19.6 @expo/webpack-config -- --legacy-peer-deps && \
    npm install --legacy-peer-deps @expo/metro-runtime react-native-blob-util

# 5. Apply critical Platform module fix
RUN mkdir -p node_modules/react-native-web/dist/exports && \
    echo "export default { OS: 'web', select: obj => (obj.web || obj.default) };" > node_modules/react-native-web/dist/exports/Platform.js && \
    find node_modules/react-native/Libraries -type f -exec sed -i "s/from '..\/Utilities\/Platform'/from 'react-native-web\/dist\/exports\/Platform'/g" {} +

# 6. Copy app code
COPY . .

# 7. Build web export with verbose output
RUN npx expo export:web --max-workers=1 || \
    (echo "Build failed, dumping debug info..." && \
     cat /app/metro.log && \
     exit 1)

# --- Stage 2: Serve ---
FROM nginx:alpine

# Custom Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=builder /app/web-build /usr/share/nginx/html

EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
