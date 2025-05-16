# Build stage
FROM node:18 AS builder

WORKDIR /app
COPY . .

# Install dependencies and build static site
RUN npm install -g expo-cli
RUN npm install
RUN npx expo export:web

# Production stage
FROM nginx:alpine

# Copy built static files to nginx html directory
COPY --from=builder /app/dist /usr/share/nginx/html

# Copy a custom nginx config (optional but recommended)
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
