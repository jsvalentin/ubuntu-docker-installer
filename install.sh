#!/bin/bash
set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Docker Installation for Ubuntu${NC}"
echo -e "${BLUE}================================${NC}"
echo

# Step 1: Update system
echo -e "${YELLOW}[1/7]${NC} Running apt update..."
sudo apt update

# Step 2: Upgrade system with keep original config
echo -e "${YELLOW}[2/7]${NC} Running apt upgrade..."
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -o Dpkg::Options::="--force-confold"

# Step 3: Install Docker
echo -e "${YELLOW}[3/7]${NC} Installing Docker..."
echo "  - Adding Docker's official GPG key..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "  - Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Step 4: Install Docker packages
echo -e "${YELLOW}[4/7]${NC} Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Step 5: Check and start Docker service
echo -e "${YELLOW}[5/7]${NC} Checking Docker service..."
if ! sudo systemctl is-active --quiet docker; then
  echo "  - Docker is not running, starting it..."
  sudo systemctl start docker
else
  echo "  - Docker is already running"
fi
sudo systemctl enable docker

# Step 6: Install docker-compose
echo -e "${YELLOW}[6/7]${NC} Installing docker-compose..."
sudo apt-get install -y docker-compose

# Step 7: Verify installation
echo -e "${YELLOW}[7/7]${NC} Verifying installation..."
echo

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Verification${NC}"
echo -e "${BLUE}================================${NC}"
echo

echo -e "${GREEN}✓${NC} Docker Version:"
docker --version

echo
echo -e "${GREEN}✓${NC} Docker Compose Version:"
docker compose version

echo
echo -e "${GREEN}✓${NC} Docker Service Status:"
sudo systemctl is-active docker

echo
echo -e "${YELLOW}Testing Docker with hello-world container...${NC}"
sudo docker run --rm hello-world

echo
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}✓ Installation Complete!${NC}"
echo -e "${BLUE}================================${NC}"
echo
echo "Docker and Docker Compose are now installed and running."
echo
