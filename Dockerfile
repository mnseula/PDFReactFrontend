# Use an official Node.js runtime as a parent image
# Choose a version that matches your project requirements, e.g., 18 or 20.
# Using a full Debian-based image as it's easier to install Ruby/Cocoapods than on Alpine.
FROM node:18

# Set the working directory in the container
WORKDIR /usr/src/app

# --- Install Cocoapods ---
# Install Ruby and other dependencies needed for Cocoapods.
# This section is for Debian-based Node images (like node:18, node:20).
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby \
    ruby-dev \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Cocoapods using gem
RUN gem install cocoapods

# --- Application Setup ---
# Copy package.json and yarn.lock (or package-lock.json) first.
# This leverages Docker's layer caching. If these files don't change,
# subsequent builds won't re-run yarn install unless other files change.
COPY package.json yarn.lock ./
# For npm projects, you would copy package.json and package-lock.json:
# COPY package.json package-lock.json ./

# Install project JavaScript dependencies
RUN yarn install --frozen-lockfile
# For npm projects:
# RUN npm ci --only=production # or npm ci if you need devDependencies

# Install react-native-pdf
RUN yarn add react-native-pdf
# For npm projects:
# RUN npm install react-native-pdf

# Copy the rest of your application code into the container
COPY . .

# Navigate to the ios directory and install pods
RUN cd ios && pod install && cd ..

# Expose the port Metro Bundler runs on (default is 8081)
EXPOSE 8081

# Define the command to run your app (e.g., start Metro Bundler)
CMD ["yarn", "start"]