#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="${SERVER_IP:-192.168.56.110}"
NODE_IP="${NODE_IP:-192.168.56.111}"
NODE_NAME="${NODE_NAME:-wstyggSW}"

SHARED_DIR="/vagrant_shared"
TOKEN_PATH="$SHARED_DIR/k3s_token"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl

if systemctl is-active --quiet k3s-agent; then
  echo "K3s agent already installed; nothing to do."
  exit 0
fi

echo "Waiting for join token at ${TOKEN_PATH} ..."
for i in $(seq 1 120); do
  if [ -s "$TOKEN_PATH" ]; then
    break
  fi
  sleep 5
done

if [ ! -s "$TOKEN_PATH" ]; then
  echo "ERROR: Token not found after waiting; cannot join cluster." >&2
  exit 1
fi

echo "Installing K3s agent on ${NODE_NAME} (${NODE_IP}), joining https://${SERVER_IP}:6443 ..."
curl -sfL https://get.k3s.io | \
  K3S_URL="https://${SERVER_IP}:6443" \
  K3S_TOKEN_FILE="$TOKEN_PATH" \
  sh -s - agent \
    --node-name "$NODE_NAME" \
    --node-ip "$NODE_IP"

systemctl enable k3s-agent >/dev/null 2>&1 || true
systemctl is-active --quiet k3s-agent && echo "K3s agent is active."