#!/bin/bash
set -e

echo "=== Updating system ==="
sudo DEBIAN_FRONTEND=noninteractive apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -o Dpkg::Options::="--force-confold"

echo "=== Installing dependencies ==="
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo "=== Adding Docker GPG key ==="
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "=== Adding Docker repository ==="
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "=== Installing Docker Engine and Compose ==="
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== Checking Docker service ==="
if ! systemctl is-active --quiet docker; then
  echo "Docker not running — starting it..."
  sudo systemctl start docker
else
  echo "Docker is already running."
fi

echo "=== Enabling Docker on boot ==="
sudo systemctl enable docker

echo "=== Verifying installation ==="
echo
echo "Docker version:"
docker --version || { echo "❌ Docker not found"; exit 1; }

echo
echo "Docker Compose version:"
docker compose version || { echo "❌ Docker Compose not found"; exit 1; }

echo
echo "=== Running test container ==="
docker run --rm hello-world || { echo "❌ Docker test failed"; exit 1; }

echo
echo "✅ Everything is working properly! Docker and Compose are ready to use."
