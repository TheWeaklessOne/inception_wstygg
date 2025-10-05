#!/usr/bin/env bash
set -euo pipefail

SERVER_IP="${SERVER_IP:-192.168.56.110}"
NODE_NAME="${NODE_NAME:-wstyggS}"

SHARED_DIR="/vagrant_shared"
KUBECONFIG_SRC="/etc/rancher/k3s/k3s.yaml"
KUBECONFIG_DST="$SHARED_DIR/kubeconfig.yaml"

mkdir -p "$SHARED_DIR"

echo "[INFO] Updating package list..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq > /dev/null 2>&1

echo "[INFO] Installing dependencies..."
apt-get install -y -qq curl > /dev/null 2>&1

# Check if K3s is already installed and running
if systemctl is-active --quiet k3s; then
  echo "[INFO] K3s server already installed and running"
else
  echo "[INFO] Installing K3s server on ${NODE_NAME} (${SERVER_IP})..."
  curl -sfL https://get.k3s.io | sh -s - server \
    --node-name "$NODE_NAME" \
    --node-ip "$SERVER_IP" \
    --advertise-address "$SERVER_IP" \
    --write-kubeconfig-mode 644 \
    --tls-san "$SERVER_IP" \
    --flannel-iface=enp0s8
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
  echo "[ERROR] K3s server failed to start"
  systemctl status k3s --no-pager
  exit 1
fi

echo "[INFO] Waiting for K3s API to be fully ready..."
echo "[INFO] This may take a minute on minimal resources..."

# Wait up to 10 minutes for full API readiness
API_READY=false
for i in $(seq 1 120); do
  if curl -sk --max-time 5 "https://${SERVER_IP}:6443/readyz" >/dev/null 2>&1; then
    echo ""
    echo "[OK] K3s API is fully ready (took $((i*5))s)"
    API_READY=true
    break
  fi
  
  # Progress indicator every 30 seconds
  if [ $((i % 6)) -eq 0 ]; then
    echo ""
    echo "[INFO] Still waiting... ($((i*5))s elapsed)"
  else
    echo -n "."
  fi
  sleep 5
done

echo ""
if [ "$API_READY" = "false" ]; then
  echo "[ERROR] K3s API did not become ready within 10 minutes"
  echo "[DEBUG] Checking K3s service status:"
  systemctl status k3s --no-pager -l
  echo "[DEBUG] Recent K3s logs:"
  journalctl -u k3s -n 50 --no-pager
  exit 1
fi

# Export kubeconfig for host access
echo "[INFO] Exporting kubeconfig..."

# Wait for kubeconfig file
for i in $(seq 1 30); do
  [ -f "$KUBECONFIG_SRC" ] && break
  sleep 2
done

if [ -f "$KUBECONFIG_SRC" ]; then
  tmp="${KUBECONFIG_DST}.tmp"
  cp "$KUBECONFIG_SRC" "$tmp"
  
  # Replace 127.0.0.1 with actual server IP for host access
  sed -E -i "s/server:\\s+https:\\/\\/(127\\.0\\.0\\.1|localhost):6443/server: https:\\/\\/${SERVER_IP}:6443/" "$tmp"
  
  install -m 600 -o vagrant -g vagrant "$tmp" "$KUBECONFIG_DST"
  rm -f "$tmp"
  
  echo "[OK] Kubeconfig exported to $KUBECONFIG_DST"
else
  echo "[ERROR] Kubeconfig file not found"
  exit 1
fi

echo "[SUCCESS] K3s server installation completed"
exit 0
