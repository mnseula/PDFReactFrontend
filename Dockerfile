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

# Install Expo CLI globally
# Using npx instead of global install to avoid Node 17+ compatibility issues
RUN npm install -g serve-handler

# Copy package files
COPY package*.json ./

# Install dependencies with specific react-native-web version
RUN npm install
RUN npm install react-native-web@latest

# Copy the rest of the application
COPY . .

# make the deploy-production.sh executable if it exists
RUN if [ -f deploy-production.sh ]; then chmod +x deploy-production.sh; fi

# Build the production version of the app using npx
RUN npx expo export:web

# Set environment variables
ENV NODE_ENV=production
ENV PORT=9091

# Expose the web server port
EXPOSE 9091

# Create the start script directly in the Dockerfile
RUN echo '#!/bin/sh' > /app/start-prod.sh && \
    echo 'echo "Starting PDF Processor App in production mode..."' >> /app/start-prod.sh && \
    echo 'cd /app/web-build && serve-handler --port 9091 --public .' >> /app/start-prod.sh && \
    chmod +x /app/start-prod.sh

# Debug: List files to ensure the script exists
RUN ls -la /app/
RUN ls -la /app/web-build || echo "web-build directory not found"

# Set the default command to run when starting the container
CMD ["/bin/sh", "/app/start-prod.sh"]
