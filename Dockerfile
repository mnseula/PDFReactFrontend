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

# Create script to run the app in production mode
RUN printf '#!/bin/sh\necho "Starting PDF Processor App in production mode..."\ncd web-build && serve-handler --port 9091 --public .\n' > /app/start-prod.sh

# Make the script executable
RUN chmod +x /app/start-prod.sh

# Set the default command to run when starting the container
CMD ["/app/start-prod.sh"]
