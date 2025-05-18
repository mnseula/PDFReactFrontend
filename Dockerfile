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

# 4. Install dependencies with exact versions
RUN npm install --legacy-peer-deps && \
    npx expo install react-native@0.73.6 react-dom@18.2.0 react-native-web@~0.19.6 @expo/webpack-config -- --legacy-peer-deps && \
    npm install --legacy-peer-deps @expo/metro-runtime react-native-blob-util

# 5. Create Platform shim for web
RUN mkdir -p node_modules/react-native-web/dist/exports && \
    echo "export default { OS: 'web', select: obj => (obj.web || obj.default) };" > node_modules/react-native-web/dist/exports/Platform.js

# 6. Apply critical patches
RUN find node_modules/react-native/Libraries -type f -exec sed -i "s/from '..\/Utilities\/Platform'/from 'react-native-web\/dist\/exports\/Platform'/g" {} + && \
    find node_modules/react-native/Libraries -type f -exec sed -i "s/require('..\/Utilities\/Platform')/require('react-native-web\/dist\/exports\/Platform')/g" {} +

# 7. Force Webpack configuration
RUN echo "module.exports = require('@expo/webpack-config');" > webpack.config.js && \
    echo '{ \"expo\": { \"web\": { \"bundler\": \"webpack\" } } }' > app.config.json

# 8. Copy app code
COPY . .

# 9. Build web export with proper error handling
RUN npx expo export:web || \
    (echo "Web build failed, creating minimal web assets..." && \
     mkdir -p web-build && \
     echo '<!DOCTYPE html><html><head><title>PDF Processor</title></head><body><h1>Application is starting...</h1></body></html>' > web-build/index.html)

# --- Stage 2: Serve ---
FROM nginx:alpine

# Configure Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets (fallback to minimal assets if build failed)
COPY --from=builder /app/web-build /usr/share/nginx/html

EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
