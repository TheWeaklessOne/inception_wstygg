#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="${SERVER_IP:-192.168.56.110}"
NODE_NAME="${NODE_NAME:-wstyggS}"

SHARED_DIR="/vagrant_shared"
KUBECONFIG_SRC="/etc/rancher/k3s/k3s.yaml"
KUBECONFIG_DST="$SHARED_DIR/kubeconfig.yaml"
TOKEN_SRC="/var/lib/rancher/k3s/server/node-token"
TOKEN_DST="$SHARED_DIR/k3s_token"

mkdir -p "$SHARED_DIR"

echo "[INFO] Updating package list..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /dev/null 2>&1
echo "[INFO] Installing dependencies..."
apt-get install -y -qq curl > /dev/null 2>&1

if systemctl is-active --quiet k3s; then
  echo "K3s server already installed; ensuring artifacts are exported..."
else
  echo "Installing K3s server on ${NODE_NAME} (${SERVER_IP}) ..."
  curl -sfL https://get.k3s.io | sh -s - server \
    --node-name "$NODE_NAME" \
    --node-ip "$SERVER_IP" \
    --advertise-address "$SERVER_IP" \
    --write-kubeconfig-mode 644 \
    --tls-san "$SERVER_IP"
fi

# Wait for kubeconfig to be generated
for i in $(seq 1 60); do
  [ -f "$KUBECONFIG_SRC" ] && break
  sleep 2
done

# Export kubeconfig with server URL pointing to the server IP
if [ -f "$KUBECONFIG_SRC" ]; then
  tmp="${KUBECONFIG_DST}.tmp"
  cp "$KUBECONFIG_SRC" "$tmp"
  # Replace 127.0.0.1 or localhost with the private IP for host-side kubectl
  sed -E -i "s/server:\s+https:\/\/(127\.0\.0\.1|localhost):6443/server: https:\/\/${SERVER_IP}:6443/" "$tmp"
  install -m 600 -o vagrant -g vagrant "$tmp" "$KUBECONFIG_DST"
  rm -f "$tmp"
  echo "Exported kubeconfig to $KUBECONFIG_DST"
fi

# Wait for join token to be generated
for i in $(seq 1 60); do
  [ -f "$TOKEN_SRC" ] && break
  sleep 2
done

# Export token for worker join
if [ -f "$TOKEN_SRC" ]; then
  install -m 600 -o vagrant -g vagrant "$TOKEN_SRC" "$TOKEN_DST"
  echo "Exported join token to $TOKEN_DST"
else
  echo "ERROR: K3s join token not found after waiting" >&2
  exit 1
fi

systemctl enable k3s >/dev/null 2>&1 || true

echo "[INFO] Waiting for K3s server service to be active..."
for i in $(seq 1 30); do
  if systemctl is-active --quiet k3s; then
    echo "[OK] K3s server is active (took ${i}s)"
    break
  fi
  echo -n "."
  sleep 1
done

echo ""
if ! systemctl is-active --quiet k3s; then
  echo "[WARN] K3s server may still be starting. Check: sudo systemctl status k3s"
  exit 1
fi

echo "[INFO] Waiting for K3s API to be ready at https://${SERVER_IP}:6443 ..."
for i in $(seq 1 60); do
  if curl -sk --max-time 5 "https://${SERVER_IP}:6443/ping" >/dev/null 2>&1; then
    echo "[OK] K3s API is ready and responding (took ${i}s)"
    exit 0
  fi
  echo -n "."
  sleep 5
done

echo ""
echo "[WARN] K3s API did not respond to /ping within expected time"
echo "[INFO] Server may still be initializing. Check: curl -sk https://${SERVER_IP}:6443/ping"
exit 1
