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
# Note the -- before flags to pass them to the underlying npm command
RUN npx expo install react-native-web@~0.19.6 react-dom@18.2.0 @expo/metro-runtime@~3.1.3 -- --legacy-peer-deps

# Install missing react-native-blob-util dependency
RUN npm install react-native-blob-util --legacy-peer-deps

# Copy the rest of the application
COPY . .

# make the deploy-production.sh executable if it exists
RUN if [ -f deploy-production.sh ]; then chmod +x deploy-production.sh; fi

# Attempt to build for web with proper dependencies now installed
RUN npx expo export:web -- --legacy-peer-deps || npm run web

# Set environment variables
ENV NODE_ENV=production
ENV PORT=9091

# Expose the web server port
EXPOSE 9091

# Create the start script directly in the Dockerfile
RUN echo '#!/bin/sh' > /app/start-prod.sh && \
    echo 'echo "Starting PDF Processor App in production mode..."' >> /app/start-prod.sh && \
    echo '# Find where the web build is located' >> /app/start-prod.sh && \
    echo 'if [ -d "/app/web-build" ]; then' >> /app/start-prod.sh && \
    echo '  cd /app/web-build' >> /app/start-prod.sh && \
    echo 'elif [ -d "/app/dist" ]; then' >> /app/start-prod.sh && \
    echo '  cd /app/dist' >> /app/start-prod.sh && \
    echo 'elif [ -d "/app/build" ]; then' >> /app/start-prod.sh && \
    echo '  cd /app/build' >> /app/start-prod.sh && \
    echo 'else' >> /app/start-prod.sh && \
    echo '  echo "Web build directory not found!"' >> /app/start-prod.sh && \
    echo '  exit 1' >> /app/start-prod.sh && \
    echo 'fi' >> /app/start-prod.sh && \
    echo 'serve-handler --port 9091 --public .' >> /app/start-prod.sh && \
    chmod +x /app/start-prod.sh

# Debug: List files to ensure the script exists and the web-build directory was created
RUN ls -la /app/
RUN find /app -name "web-build" -type d || echo "web-build directory not found"
RUN find /app -name "dist" -type d || echo "dist directory not found"
RUN find /app -name "build" -type d || echo "build directory not found"

# Set the default command to run when starting the container
CMD ["/bin/sh", "/app/start-prod.sh"]
