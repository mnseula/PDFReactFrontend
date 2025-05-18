FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install all system dependencies in a single RUN
RUN apk add --no-cache \
    bash \
    git \
    python3 \
    make \
    g++ \
    jpeg-dev \
    cairo-dev \
    pango-dev \
    giflib-dev

# Install global dependencies
RUN npm install -g serve-handler

# Copy package files first to leverage Docker cache
COPY package*.json ./

# Install all npm dependencies in a single RUN
RUN npm install --legacy-peer-deps && \
    npx expo install react-native-web@~0.19.6 react-dom@18.2.0 @expo/metro-runtime@~3.1.3 -- --legacy-peer-deps && \
    npm install react-native-blob-util --legacy-peer-deps

# Copy application code
COPY . .

# Set environment variables for production build
ENV NODE_ENV=production \
    EXPO_NO_DEV=true \
    EXPO_NO_METRO=true \
    PORT=9091

# Build the application
RUN npx expo export:web --no-dev --minify --clear || \
    (echo "Expo export failed, trying npm run web..." && npm run web || echo "Web build failed")

# Create production start script
RUN echo '#!/bin/sh\n\
set -x\n\
echo "Starting PDF Processor App in production mode..."\n\
cd /app/web-build || cd /app/dist || cd /app/build || cd /app/fallback-web || {\n\
  echo "No valid build directory found. Creating fallback page..."\n\
  mkdir -p /app/fallback-web\n\
  echo "<html><head><title>PDF Processor</title></head><body><h1>PDF Processor App</h1><p>Build failed - please check Docker logs.</p></body></html>" > /app/fallback-web/index.html\n\
  cd /app/fallback-web\n\
}\n\
serve-handler --port 9091 --public . 2>&1' > /app/start-prod.sh && \
    chmod +x /app/start-prod.sh

EXPOSE 9091
CMD ["/bin/sh", "/app/start-prod.sh"]
