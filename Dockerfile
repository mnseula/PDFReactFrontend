# syntax=docker/dockerfile:1.4
FROM node:18-alpine AS builder
WORKDIR /app

# 1. Install system dependencies
RUN apk add --no-cache \
    bash python3 make g++ \
    jpeg-dev cairo-dev pango-dev \
    git # Adding git which is sometimes needed for npm installations

# 2. Configure production environment
ENV NODE_ENV=production \
    CI=true \
    EXPO_USE_STATIC=1 \
    NPM_CONFIG_LOGLEVEL=verbose # Add more verbose npm logging

# 3. Copy package files first for caching
COPY package*.json ./
COPY app.json ./
COPY babel.config.js ./
COPY metro.config.js ./
COPY webpack.config.js ./

# 4. Install dependencies with exact versions and proper error handling
RUN npm install --legacy-peer-deps || (echo "NPM install failed" && exit 1)

# 5. Install Expo specific dependencies
RUN npx expo install react-native@0.73.6 react-dom@18.2.0 react-native-web@~0.19.6 @expo/webpack-config@^19.0.0 -- --legacy-peer-deps || \
    (echo "Expo dependencies installation failed" && exit 1)

RUN npm install --legacy-peer-deps @expo/metro-runtime react-native-blob-util || \
    (echo "Additional dependencies installation failed" && exit 1)

# 6. Copy app code
COPY . .

# 7. Make sure proper app.config.js/json exists
# If app.config.js doesn't exist in your source, this will create a minimal one
RUN if [ ! -f app.config.js ] && [ ! -f app.config.json ]; then \
      echo '{ "expo": { "name": "MyApp", "slug": "my-app", "version": "1.0.0", "web": { "bundler": "webpack" } } }' > app.config.json; \
    fi

# 8. Ensure webpack config is properly set up
RUN if [ ! -f webpack.config.js ]; then \
      echo "module.exports = require('@expo/webpack-config');" > webpack.config.js; \
    fi

# 9. Build web export with detailed debugging
RUN mkdir -p web-build && \
    { \
      set -e; \
      echo "Starting build process..."; \
      # First try with environment export
      if npx expo export:web --output-dir web-build --dump-sourcemap --dump-assetmap; then \
        echo "Build successful. Application is in web-build/"; \
      else \
        echo "First build attempt failed, trying alternative approach..."; \
        # Try with the expo build:web command (older approach)
        if npx expo build:web --no-pwa; then \
          echo "Alternative build successful."; \
        else \
          echo "Build attempts failed. See logs above for details."; \
          # Create fallback page with more details
          rm -rf web-build/*; \
          echo '<!DOCTYPE html><html><head><title>App Error</title><style>body{font-family:sans-serif;padding:2rem;color:#333}</style></head><body><h1>Application Error</h1><p>The build failed. Please check the logs.</p><pre>' > web-build/index.html; \
          echo 'Build log summary:' >> web-build/index.html; \
          echo '- Node version: ' >> web-build/index.html; \
          node --version >> web-build/index.html; \
          echo '- NPM version: ' >> web-build/index.html; \
          npm --version >> web-build/index.html; \
          echo '- Installed packages: ' >> web-build/index.html; \
          npm list --depth=0 >> web-build/index.html; \
          echo '</pre></body></html>' >> web-build/index.html; \
          exit 1; \
        fi; \
      fi; \
    }

# --- Stage 2: Serve ---
FROM nginx:alpine

# Configure Nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built assets
COPY --from=builder /app/web-build /usr/share/nginx/html

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s CMD wget -q -O - http://localhost:9091/ || exit 1

EXPOSE 9091
CMD ["nginx", "-g", "daemon off;"]
