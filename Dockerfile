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

# Install EAS CLI and serve-handler globally (Expo CLI will be used from local project dependencies)
RUN npm install -g eas-cli serve-handler

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application
COPY . .

# make the deploy-production.sh executable
RUN chmod +x deploy-production.sh

# Build/export the web version of the app using the local Expo CLI
RUN npx expo export

# Set environment variables
ENV NODE_ENV=production
ENV PORT=8081

# Expose the web server port
EXPOSE 8081

# Create script to run the app in production mode
RUN echo -e '#!/bin/sh\n\
echo "Starting PDF Processor App in production mode..."\n\
cd dist && serve-handler --port 8081 --public .\n\
' > /app/start-prod.sh && chmod +x /app/start-prod.sh

# Set the default command to run when starting the container
CMD ["/app/start-prod.sh"]
