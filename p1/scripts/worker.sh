#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="${SERVER_IP:-192.168.56.110}"
NODE_IP="${NODE_IP:-192.168.56.111}"
NODE_NAME="${NODE_NAME:-wstyggSW}"

SHARED_DIR="/vagrant_shared"
TOKEN_PATH="$SHARED_DIR/k3s_token"

echo "[INFO] Updating package list..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /dev/null 2>&1
echo "[INFO] Installing dependencies..."
apt-get install -y -qq curl > /dev/null 2>&1

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

echo "Waiting for K3s server API to be fully ready at https://${SERVER_IP}:6443 ..."
for i in $(seq 1 120); do
  if curl -sk --max-time 10 "https://${SERVER_IP}:6443/readyz" >/dev/null 2>&1; then
    echo "[OK] K3s server API is fully ready (took $((i*5))s)"
    break
  fi
  echo -n "."
  sleep 5
done

if ! curl -sk --max-time 10 "https://${SERVER_IP}:6443/readyz" >/dev/null 2>&1; then
  echo ""
  echo "[WARN] K3s server API /readyz not responding, but attempting join anyway..."
fi

echo "Installing K3s agent on ${NODE_NAME} (${NODE_IP}), joining https://${SERVER_IP}:6443 ..."
echo "[INFO] This may take a few minutes as the agent retrieves configuration from server..."

# Let the installer start the service, but give it time
# The agent needs to connect to the server which may still be under load
curl -sfL https://get.k3s.io | \
  K3S_URL="https://${SERVER_IP}:6443" \
  K3S_TOKEN_FILE="$TOKEN_PATH" \
  sh -s - agent \
    --node-name "$NODE_NAME" \
    --node-ip "$NODE_IP"

echo "[INFO] K3s agent installation completed"
echo "[INFO] Waiting for agent service to become active..."

# Give some time for the service to start
for i in $(seq 1 60); do
  if systemctl is-active --quiet k3s-agent; then
    echo "[OK] K3s agent is active (took ${i}s)"
    exit 0
  fi
  echo -n "."
  sleep 2
done

echo ""
if systemctl is-active --quiet k3s-agent; then
  echo "[OK] K3s agent is active"
  exit 0
else
  echo "[WARN] K3s agent may still be starting after install. This is normal on minimal resources."
  echo "[INFO] Service status:"
  systemctl status k3s-agent --no-pager || true
  echo ""
  echo "[INFO] The agent will continue attempting to join the cluster in the background."
  echo "[INFO] Run 'vagrant ssh wstyggSW -c \"sudo systemctl status k3s-agent\"' to check status."
  exit 0
fi
