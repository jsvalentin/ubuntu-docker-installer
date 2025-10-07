#!/usr/bin/env bash
set -e

echo "=== 🧩 Updating system ==="
sudo DEBIAN_FRONTEND=noninteractive apt update -y
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y -o Dpkg::Options::="--force-confold"

echo "=== 📦 Installing dependencies ==="
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo "=== 🔑 Adding Docker GPG key ==="
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo "=== 🧾 Fixing any old Docker repo issues ==="
if [ -f /etc/apt/sources.list.d/docker.list ]; then
  echo "Removing invalid Docker repo file..."
  sudo rm -f /etc/apt/sources.list.d/docker.list
fi

echo "=== 🐋 Adding Docker repository ==="
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable
EOF

echo "=== ⚙️ Installing Docker Engine and Compose ==="
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "=== 🔍 Checking Docker service ==="
if ! systemctl is-active --quiet docker; then
  echo "Docker not running — starting it..."
  sudo systemctl start docker
else
  echo "Docker is already running."
fi

echo "=== 🧷 Enabling Docker on boot ==="
sudo systemctl enable docker

echo "=== 🧠 Adding current user to docker group ==="
if [ "$SUDO_USER" ]; then
  sudo usermod -aG docker "$SUDO_USER"
  echo "✅ Added $SUDO_USER to docker group (log out/in or run 'newgrp docker')"
else
  echo "⚠️ No non-root user detected, skipping docker group setup"
fi

echo "=== 🧪 Verifying installation ==="
docker --version || { echo "❌ Docker not found"; exit 1; }
docker compose version || { echo "❌ Docker Compose not found"; exit 1; }

echo "=== 🧱 Running test container ==="
docker run --rm hello-world || { echo "❌ Docker test failed"; exit 1; }

echo
echo "✅ Everything is working properly! Docker and Compose are ready to use."
