#!/bin/bash
set -e

SERVER_IP="${SERVER_IP:-192.168.56.110}"
NODE_IP="${NODE_IP:-192.168.56.111}"
NODE_NAME="${NODE_NAME:-wstyggSW}"
SHARED_DIR="/vagrant_shared"
TOKEN_PATH="${SHARED_DIR}/k3s_token"

echo "[INFO] Waiting for join token from server..."

# Simple wait for token
until [ -f "${TOKEN_PATH}" ]; do
    sleep 5
done

echo "[INFO] Token found! Installing K3s agent on ${NODE_NAME} (${NODE_IP})..."

# Install K3s agent - let the installer handle everything
curl -sfL https://get.k3s.io | \
    K3S_URL="https://${SERVER_IP}:6443" \
    K3S_TOKEN="$(cat ${TOKEN_PATH})" \
    sh -s - agent \
        --node-name="${NODE_NAME}" \
        --node-ip="${NODE_IP}"

echo "[SUCCESS] K3s agent installation complete!"
echo "[INFO] Agent should join cluster automatically via systemd"
