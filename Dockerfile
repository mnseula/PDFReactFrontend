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
RUN npm install -g expo-cli eas-cli serve-handler

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# make the deploy-production.sh executable
RUN chmod +x deploy-production.sh

# Build the production version of the app
RUN expo build:web

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

# Set the default command to run when starting the container
CMD ["/bin/sh", "/app/start-prod.sh"]
