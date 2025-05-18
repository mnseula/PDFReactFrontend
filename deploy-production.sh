#!/bin/bash

# Set bold text
bold=$(tput bold)
normal=$(tput sgr0)

echo "🚀 ${bold}PDF Processor App Production Setup${normal}"
echo "===============================================\n"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ ${bold}Docker is not installed.${normal} Please install Docker first."
    echo "   Visit https://docs.docker.com/get-docker/ for installation instructions."
    exit 1
fi

# Check if docker-compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ ${bold}Docker Compose is not installed.${normal} Please install Docker Compose first."
    echo "   Visit https://docs.docker.com/compose/install/ for installation instructions."
    exit 1
fi

echo "📦 ${bold}Setting up production environment...${normal}"

# Create assets directory if it doesn't exist
mkdir -p assets

# Create placeholder icon and splash images if they don't exist
if [ ! -f "./assets/icon.png" ]; then
    echo "Creating placeholder icon.png"
    # Use base64 encoded 512x512 transparent PNG
    cat > ./assets/icon.png << EOL
iVBORw0KGgoAAAANSUhEUgAAAgAAAAIAAQMAAADOtka5AAAAA1BMVEUcHBwY5c/qAAAASElEQVR4
2u3BMQEAAADCIPunNsU+YAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAehA+
4QAB+0gHnQAAAABJRU5ErkJggg==
EOL
fi

if [ ! -f "./assets/splash.png" ]; then
    echo "Creating placeholder splash.png"
    # Using the same placeholder for splash
    cp ./assets/icon.png ./assets/splash.png
fi

if [ ! -f "./assets/adaptive-icon.png" ]; then
    echo "Creating placeholder adaptive-icon.png"
    cp ./assets/icon.png ./assets/adaptive-icon.png
fi

if [ ! -f "./assets/favicon.png" ]; then
    echo "Creating placeholder favicon.png"
    cp ./assets/icon.png ./assets/favicon.png
fi

# Create web-build directory if it doesn't exist
mkdir -p web-build

echo "🏗️ ${bold}Building Docker images...${normal}"
docker-compose build

echo "\n🚀 ${bold}Starting PDF Processor App in production mode...${normal}"
docker-compose up -d

echo "\n✅ ${bold}Setup Complete!${normal}"
echo "Your PDF Processor App is now running in production mode."
echo "You can access it at http://localhost"
echo "\n📊 ${bold}Container Status:${normal}"
docker-compose ps

echo "\n🔍 ${bold}Logs:${normal}"
echo "To view logs, run: docker-compose logs -f"
echo "To stop the application, run: docker-compose down"
