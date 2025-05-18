FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apk add --no-cache bash git python3 make g++ \
    && apk add --no-cache --virtual .build-deps \
    jpeg-dev \
    cairo-dev \
    pango-dev \
    giflib-dev

# Install serve-handler globally
RUN npm install -g serve-handler

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps

# Install web-specific dependencies using correct syntax
RUN npx expo install react-native-web@~0.19.6 react-dom@18.2.0 @expo/metro-runtime@~3.1.3 -- --legacy-peer-deps

# Install missing react-native-blob-util dependency
RUN npm install react-native-blob-util --legacy-peer-deps

# Copy the rest of the application
COPY . .

# make the deploy-production.sh executable if it exists
RUN if [ -f deploy-production.sh ]; then chmod +x deploy-production.sh; fi

# Attempt to build for web with proper dependencies now installed
# Add verbose output with set -x to see exactly what's happening
RUN set -x && npx expo export:web -- --legacy-peer-deps || npm run web || echo "Web build failed but continuing..."

# Set environment variables
ENV NODE_ENV=production
ENV PORT=9091

# Expose the web server port
EXPOSE 9091

# Enhanced debugging: Find all potential web build directories and their contents
RUN echo "=== Searching for web build directories ===" && \
    find /app -type d -name "web-build" -o -name "dist" -o -name "build" | xargs -I{} sh -c 'echo "Found: {}"; ls -la {}'

# Create a more robust start script directly in the Dockerfile
RUN echo '#!/bin/sh' > /app/start-prod.sh && \
    echo 'set -x' >> /app/start-prod.sh && \
    echo 'echo "Starting PDF Processor App in production mode..."' >> /app/start-prod.sh && \
    echo '' >> /app/start-prod.sh && \
    echo '# List directories to help with debugging' >> /app/start-prod.sh && \
    echo 'echo "Contents of /app:"' >> /app/start-prod.sh && \
    echo 'ls -la /app/' >> /app/start-prod.sh && \
    echo '' >> /app/start-prod.sh && \
    echo '# Find where the web build is located' >> /app/start-prod.sh && \
    echo 'if [ -d "/app/web-build" ]; then' >> /app/start-prod.sh && \
    echo '  echo "Using /app/web-build"' >> /app/start-prod.sh && \
    echo '  cd /app/web-build' >> /app/start-prod.sh && \
    echo 'elif [ -d "/app/dist" ]; then' >> /app/start-prod.sh && \
    echo '  echo "Using /app/dist"' >> /app/start-prod.sh && \
    echo '  cd /app/dist' >> /app/start-prod.sh && \
    echo 'elif [ -d "/app/build" ]; then' >> /app/start-prod.sh && \
    echo '  echo "Using /app/build"' >> /app/start-prod.sh && \
    echo '  cd /app/build' >> /app/start-prod.sh && \
    echo 'else' >> /app/start-prod.sh && \
    echo '  echo "No build directory found. Checking package.json for potential web script..."' >> /app/start-prod.sh && \
    echo '  cd /app' >> /app/start-prod.sh && \
    echo '  if grep -q "web" package.json; then' >> /app/start-prod.sh && \
    echo '    echo "Found web script in package.json, attempting to build..."' >> /app/start-prod.sh && \
    echo '    npm run web' >> /app/start-prod.sh && \
    echo '    # Check again for build directories' >> /app/start-prod.sh && \
    echo '    if [ -d "/app/web-build" ]; then' >> /app/start-prod.sh && \
    echo '      cd /app/web-build' >> /app/start-prod.sh && \
    echo '    elif [ -d "/app/dist" ]; then' >> /app/start-prod.sh && \
    echo '      cd /app/dist' >> /app/start-prod.sh && \
    echo '    elif [ -d "/app/build" ]; then' >> /app/start-prod.sh && \
    echo '      cd /app/build' >> /app/start-prod.sh && \
    echo '    else' >> /app/start-prod.sh && \
    echo '      echo "Web build directory still not found, creating a simple HTML file to serve"' >> /app/start-prod.sh && \
    echo '      mkdir -p /app/fallback-web' >> /app/start-prod.sh && \
    echo '      echo "<html><head><title>PDF Processor</title></head><body><h1>PDF Processor App</h1><p>Build failed - please check Docker logs.</p></body></html>" > /app/fallback-web/index.html' >> /app/start-prod.sh && \
    echo '      cd /app/fallback-web' >> /app/start-prod.sh && \
    echo '    fi' >> /app/start-prod.sh && \
    echo '  else' >> /app/start-prod.sh && \
    echo '    echo "Web build directory not found and no web script in package.json. Creating fallback HTML."' >> /app/start-prod.sh && \
    echo '    mkdir -p /app/fallback-web' >> /app/start-prod.sh && \
    echo '    echo "<html><head><title>PDF Processor</title></head><body><h1>PDF Processor App</h1><p>Build failed - please check Docker logs.</p></body></html>" > /app/fallback-web/index.html' >> /app/start-prod.sh && \
    echo '    cd /app/fallback-web' >> /app/start-prod.sh && \
    echo '  fi' >> /app/start-prod.sh && \
    echo 'fi' >> /app/start-prod.sh && \
    echo '' >> /app/start-prod.sh && \
    echo '# List current directory contents to verify we are in the right place' >> /app/start-prod.sh && \
    echo 'echo "Current directory contents:"' >> /app/start-prod.sh && \
    echo 'ls -la' >> /app/start-prod.sh && \
    echo '' >> /app/start-prod.sh && \
    echo '# Start the server' >> /app/start-prod.sh && \
    echo 'echo "Starting serve-handler on port 9091..."' >> /app/start-prod.sh && \
    echo 'serve-handler --port 9091 --public . 2>&1' >> /app/start-prod.sh && \
    chmod +x /app/start-prod.sh

# Make sure the script is executable
RUN chmod +x /app/start-prod.sh && ls -la /app/start-prod.sh

# Set the default command to run when starting the container
CMD ["/bin/sh", "/app/start-prod.sh"]
