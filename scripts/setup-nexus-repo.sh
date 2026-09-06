#!/bin/bash
set -e

echo "🐧 [NEXUS CLUSTER] Configurando Repositorio Oficial APT..."

SERVER_URL="http://192.168.196.101/apt"

sudo apt-get update -y >/dev/null 2>&1 || true
sudo apt-get install -y curl ca-certificates >/dev/null 2>&1 || true

echo "deb [trusted=yes] $SERVER_URL stable main" | sudo tee /etc/apt/sources.list.d/nexus.list > /dev/null

sudo apt-get update -y

echo "✔ Repositorio Nexus APT configurado com sucesso!"
echo "Comandos disponiveis para instalacao:"
echo "  sudo apt install nexus-app-hub"
echo "  sudo apt install neoblocks"
echo "  sudo apt install nexus-dashboard"
