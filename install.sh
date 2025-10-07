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

# Detect if running as root
if [ "$EUID" -eq 0 ]; then 
    CMD=""
else 
    CMD="sudo"
fi

# Step 1: Clean up any existing Docker repository files
echo -e "${YELLOW}[1/9]${NC} Cleaning up old Docker repository files..."
$CMD rm -f /etc/apt/sources.list.d/docker.list
$CMD rm -f /etc/apt/keyrings/docker.asc

# Step 2: Update system
echo -e "${YELLOW}[2/9]${NC} Updating system packages..."
DEBIAN_FRONTEND=noninteractive $CMD apt-get update -q
DEBIAN_FRONTEND=noninteractive $CMD apt-get upgrade -y -q

# Step 3: Install prerequisites
echo -e "${YELLOW}[3/9]${NC} Installing prerequisites..."
$CMD apt-get install -y -q \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Step 4: Create keyrings directory
echo -e "${YELLOW}[4/9]${NC} Setting up keyrings directory..."
$CMD mkdir -p /etc/apt/keyrings

# Step 5: Add Docker GPG key
echo -e "${YELLOW}[5/9]${NC} Adding Docker's official GPG key..."
$CMD curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
$CMD chmod a+r /etc/apt/keyrings/docker.asc

# Step 6: Add Docker repository
echo -e "${YELLOW}[6/9]${NC} Adding Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  $CMD tee /etc/apt/sources.list.d/docker.list > /dev/null

# Step 7: Install Docker
echo -e "${YELLOW}[7/9]${NC} Installing Docker Engine..."
$CMD apt-get update -q
$CMD apt-get install -y -q \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# Step 8: Start Docker
echo -e "${YELLOW}[8/9]${NC} Starting Docker service..."
$CMD systemctl start docker
$CMD systemctl enable docker

# Step 9: Add user to docker group (if not root)
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}[9/9]${NC} Adding user to docker group..."
    $CMD usermod -aG docker $USER
    echo -e "${GREEN}✓${NC} User added to docker group"
    echo -e "${YELLOW}  Note: Log out and back in for this to take effect${NC}"
else
    echo -e "${YELLOW}[9/9]${NC} Running as root, skipping user group step..."
fi

# Verify installation
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
$CMD systemctl is-active docker

echo
echo -e "${YELLOW}Testing Docker with hello-world container...${NC}"
$CMD docker run --rm hello-world

echo
echo -e "${BLUE}================================${NC}"
echo -e "${GREEN}✓ Installation Complete!${NC}"
echo -e "${BLUE}================================${NC}"
echo
echo "Docker and Docker Compose are now installed and running."
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}Remember:${NC} Log out and back in to use docker without sudo"
fi
echo
