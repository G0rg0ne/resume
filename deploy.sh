#!/bin/bash

# Check if server IP is provided
if [ -z "$1" ]; then
    echo "Usage: ./deploy.sh <server-ip>"
    exit 1
fi

SERVER_IP=$1

# Build the Docker image locally
echo "Building Docker image..."
docker-compose build

# Save the image
echo "Saving Docker image..."
docker save react-portfolio:latest | gzip > portfolio.tar.gz

# Copy files to server
echo "Copying files to server..."
scp portfolio.tar.gz docker-compose.yml $SERVER_IP:~/

# SSH into server and deploy
echo "Deploying to server..."
ssh $SERVER_IP << 'ENDSSH'
    # Install Docker if not installed
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    fi

    # Install Docker Compose if not installed
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    # Load the Docker image
    echo "Loading Docker image..."
    docker load < portfolio.tar.gz

    # Start the container
    echo "Starting container..."
    docker-compose up -d

    # Clean up
    rm portfolio.tar.gz
ENDSSH

# Clean up local files
rm portfolio.tar.gz

echo "Deployment complete!" 