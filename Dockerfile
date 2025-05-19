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

# 5. Create Platform shim and patch files
RUN mkdir -p node_modules/react-native-web/dist/exports && \
    echo "export default { OS: 'web', select: obj => (obj.web || obj.default) };" > node_modules/react-native-web/dist/exports/Platform.js && \
    for file in $(grep -rl "../Utilities/Platform" node_modules/react-native/Libraries/); do \
      sed -i "s|from '../Utilities/Platform'|from 'react-native-web/dist/exports/Platform'|g" "$file"; \
      sed -i "s|require('../Utilities/Platform')|require('react-native-web/dist/exports/Platform')|g" "$file"; \
    done

# 6. Force Webpack configuration
RUN echo "module.exports = require('@expo/webpack-config');" > webpack.config.js && \
    echo '{ \"expo\": { \"web\": { \"bundler\": \"webpack\" } } }' > app.config.json

# 7. Copy app code
COPY . .

# 8. Build web export with detailed logging
RUN { \
      echo "Starting build process..."; \
      # Ensure output goes to web-build
      npx expo export:web --output-dir web-build 2>&1 | tee build.log; \
      BUILD_EXIT_CODE=$?; \
      if [ $BUILD_EXIT_CODE -ne 0 ]; then \
        echo "Build failed with exit code $BUILD_EXIT_CODE"; \
        echo "Build logs:"; \
        cat build.log; \
        echo "Creating fallback assets..."; \
        mkdir -p web-build && \
        # Clean web-build in case expo export partially wrote to it before failing
        rm -rf web-build/* && \
        echo '<!DOCTYPE html><html><head><title>App Error</title><style>body{font-family:sans-serif;padding:2rem;color:#333}</style></head><body><h1>Application Error</h1><p>The build failed. Please check the logs.</p><pre>' > web-build/index.html && \
        cat build.log >> web-build/index.html && \
        echo '</pre></body></html>' >> web-build/index.html; \
      fi; \
      exit $BUILD_EXIT_CODE; \
    }

# --- Stage 2: Serve ---
FROM nginx:alpine

# Configure Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=builder /app/web-build /usr/share/nginx/html

EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
