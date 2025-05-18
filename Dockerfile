FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install system dependencies required for building native modules
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

# Install serve-handler globally
RUN npm install -g serve-handler

# Copy only dependency files to leverage Docker cache
COPY package*.json ./

# Install only production dependencies
RUN npm install --omit=dev --legacy-peer-deps && \
    npx expo install react-native-web@~0.19.6 react-dom@18.2.0 @expo/metro-runtime@~3.1.3 -- --legacy-peer-deps && \
    npm install react-native-blob-util --legacy-peer-deps --omit=dev

# Copy the rest of the app source code
COPY . .

# Make any custom shell scripts executable (if they exist)
RUN chmod +x /app/deploy-production.sh 2>/dev/null || true

# Attempt to build the web export
RUN npx expo export:web -- --legacy-peer-deps || \
    (echo "Expo export failed, trying npm run web..." && npm run web || echo "Web build failed.")

# Set environment variables
ENV NODE_ENV=production
ENV PORT=9091

# Expose the port
EXPOSE 9091

# Create a simplified production start script
RUN echo '#!/bin/sh' > /app/start-prod.sh && \
    echo 'set -x' >> /app/start-prod.sh && \
    echo 'cd /app/web-build 2>/dev/null || cd /app/dist 2>/dev/null || cd /app/build 2>/dev/null || {' >> /app/start-prod.sh && \
    echo '  echo "No web build found. Creating fallback page."' >> /app/start-prod.sh && \
    echo '  mkdir -p /app/fallback-web' >> /app/start-prod.sh && \
    echo '  echo "<html><body><h1>Build Failed</h1></body></html>" > /app/fallback-web/index.html' >> /app/start-prod.sh && \
    echo '  cd /app/fallback-web' >> /app/start-prod.sh && \
    echo '}' >> /app/start-prod.sh && \
    echo 'serve-handler --port 9091 --public . 2>&1' >> /app/start-prod.sh && \
    chmod +x /app/start-prod.sh

# Default CMD
CMD ["/bin/sh", "/app/start-prod.sh"]
