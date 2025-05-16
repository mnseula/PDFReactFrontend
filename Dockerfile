# Use an official Node.js runtime as a parent image
# Choose a version that matches your project requirements, e.g., 18 or 20.
# Using a full Debian-based image as it's easier to install Ruby/Cocoapods than on Alpine.
FROM node:18

# Set the working directory in the container
WORKDIR /usr/src/app

# --- Install Cocoapods ---
# Install Ruby, Java, Android SDK dependencies, and other build essentials.
# This section is for Debian-based Node images (like node:18, node:20).
# --- Install Cocoapods ---
RUN apt-get update && apt-get install -y --no-install-recommends \
    ruby \
    ruby-dev \
    build-essential \
    openjdk-17-jdk \  # Updated
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*
# Install Cocoapods using gem
RUN gem install cocoapods

# --- Application Setup ---
# --- Install Android SDK ---
# Set up Android environment variables
ENV ANDROID_SDK_ROOT /opt/android-sdk
# Ensure cmdline-tools and platform-tools are on the PATH
ENV PATH $PATH:${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${ANDROID_SDK_ROOT}/platform-tools

# Download and install Android command-line tools
# Create the directory for SDK and download tools
# Check https://developer.android.com/studio#command-tools for the latest version/link if needed
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools && \
    wget https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -O /tmp/cmdline-tools.zip && \
    unzip /tmp/cmdline-tools.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools && \
    # The tools are extracted into a 'cmdline-tools' sub-folder, move them to 'latest'
    mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest && \
    rm /tmp/cmdline-tools.zip

# Accept Android SDK licenses and install platform-tools, build-tools, and a platform version
# Adjust build-tools (e.g., 33.0.2) and platform (e.g., android-33) versions as needed for your project
RUN yes | sdkmanager --licenses > /dev/null && \
    sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.2"
    # You can add other packages if your project needs them, e.g., "ndk;25.2.9519653" or "emulator"

# Copy package.json and package-lock.json first.
# This leverages Docker's layer caching. If these files don't change,
# subsequent builds won't re-run npm install unless other files change.
COPY package.json package-lock.json ./

# Install project JavaScript dependencies
RUN npm ci # Using npm ci is generally recommended for reproducible builds

# Copy the rest of your application code into the container
COPY . .

# Navigate to the ios directory and install pods
RUN cd ios && pod install && cd ..

# Expose the port Metro Bundler runs on (default is 8081)
EXPOSE 8081
# Expose a common port for web development (e.g., if you use `react-native-web` or have a separate web app)
EXPOSE 3000

# Define the command to run your app (e.g., start Metro Bundler)
CMD ["npm", "start"]

# --- Notes for Building/Running Android and Web ---
#
# This Dockerfile sets up the environment. The default CMD starts Metro.
#
# To build your Android app (after starting the container, e.g., with `docker run ...`):
#   1. Open a new terminal.
#   2. Execute a shell in your running container: `docker exec -it <your_container_name_or_id> bash`
#   3. Inside the container shell: `cd android && ./gradlew assembleDebug` (or `assembleRelease`, etc.)
#
# To run your web app (if you have a script like `npm run web` that starts a dev server on port 3000):
#   1. Similarly, use `docker exec -it <your_container_name_or_id> npm run web`
#   2. Or, you could modify the CMD above to use a tool like 'concurrently'
#      to run `npm start` (Metro) and `npm run web` (your web script) together.
