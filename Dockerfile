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

# Install dependencies (use legacy-peer-deps to handle dependency conflicts)
RUN npm install --legacy-peer-deps

# Copy the rest of the application
COPY . .

# make the deploy-production.sh executable if it exists
RUN if [ -f deploy-production.sh ]; then chmod +x deploy-production.sh; fi

# Build the production version of the app using npx and forcing legacy behavior
RUN npx --legacy-peer-deps expo export:web || npx --legacy-peer-deps expo export

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

# Debug: List files to ensure the script exists and the web-build directory was created
RUN ls -la /app/
RUN find /app -name "web-build" -type d || echo "web-build directory not found, checking for alternative build outputs:"
RUN ls -la /app/dist || echo "dist directory not found"
RUN ls -la /app/build || echo "build directory not found"
RUN ls -la /app/expo-dist || echo "expo-dist directory not found"

# Set the default command to run when starting the container
CMD ["/bin/sh", "/app/start-prod.sh"]
