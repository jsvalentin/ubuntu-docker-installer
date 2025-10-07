#!/bin/bash
set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=== Docker Installation Script for Ubuntu ==="
echo

# Check if running on Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    echo -e "${RED}❌ This script is designed for Ubuntu only${NC}"
    exit 1
fi

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    SUDO=""
    SUDO_ENV=""
else
    SUDO="sudo"
    SUDO_ENV="sudo -E"
    # Check if sudo is available
    if ! command -v sudo &> /dev/null; then
        echo -e "${RED}❌ sudo is not available. Please run as root or install sudo${NC}"
        exit 1
    fi
fi

echo "=== Updating system ==="
export DEBIAN_FRONTEND=noninteractive
$SUDO apt-get update -y
$SUDO_ENV apt-get upgrade -y -o Dpkg::Options::="--force-confold"

echo "=== Installing dependencies ==="
$SUDO apt-get install -y ca-certificates curl gnupg lsb-release

echo "=== Removing old Docker installations (if any) ==="
$SUDO apt-get remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true

echo "=== Adding Docker GPG key ==="
$SUDO install -m 0755 -d /etc/apt/keyrings
$SUDO curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
$SUDO chmod a+r /etc/apt/keyrings/docker.asc

echo "=== Adding Docker repository ==="
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "=== Installing Docker Engine and Compose ==="
$SUDO apt-get update -y
$SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== Starting Docker service ==="
if ! systemctl is-active --quiet docker; then
  echo "Starting Docker..."
  $SUDO systemctl start docker
  sleep 2
else
  echo "Docker is already running."
fi

echo "=== Enabling Docker on boot ==="
$SUDO systemctl enable docker

echo "=== Adding current user to docker group (if not root) ==="
if [[ $EUID -ne 0 ]]; then
    $SUDO usermod -aG docker $USER
    echo -e "${YELLOW}⚠️  You need to log out and back in for group changes to take effect${NC}"
    echo -e "${YELLOW}   Or run: newgrp docker${NC}"
fi

echo
echo "=== Verifying installation ==="
echo
echo "Docker version:"
docker --version || { echo -e "${RED}❌ Docker not found${NC}"; exit 1; }

echo
echo "Docker Compose version:"
docker compose version || { echo -e "${RED}❌ Docker Compose not found${NC}"; exit 1; }

echo
echo "Docker service status:"
$SUDO systemctl status docker --no-pager || { echo -e "${RED}❌ Docker service not running${NC}"; exit 1; }

echo
echo "=== Running test container ==="
if $SUDO docker run --rm hello-world; then
    echo
    echo -e "${GREEN}✅ Everything is working properly! Docker and Compose are ready to use.${NC}"
    echo
    if [[ $EUID -ne 0 ]]; then
        echo -e "${YELLOW}📝 Remember to log out and back in (or run 'newgrp docker') to use Docker without sudo${NC}"
    fi
else
    echo -e "${RED}❌ Docker test failed${NC}"
    exit 1
fi

echo
echo "=== Installation Summary ==="
echo "• Docker version: $(docker --version)"
echo "• Docker Compose version: $(docker compose version)"
echo "• Docker service: $(systemctl is-active docker)"
echo
echo -e "${GREEN}Installation complete!${NC}"
