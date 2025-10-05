#!/bin/bash
set -e

SERVER_IP="${SERVER_IP:-192.168.56.110}"
NODE_NAME="${NODE_NAME:-wstyggS}"
SHARED_DIR="/vagrant_shared"

echo "[INFO] Installing K3s server on ${NODE_NAME} (${SERVER_IP})..."

# Install K3s server - let the installer handle everything
curl -sfL https://get.k3s.io | sh -s - server \
    --write-kubeconfig-mode=644 \
    --node-name="${NODE_NAME}" \
    --node-ip="${SERVER_IP}" \
    --advertise-address="${SERVER_IP}" \
    --tls-san="${SERVER_IP}"

echo "[INFO] Waiting for K3s to generate token and kubeconfig..."

# Simple wait for token file
until [ -f /var/lib/rancher/k3s/server/node-token ]; do
    sleep 2
done

# Simple wait for kubeconfig
until [ -f /etc/rancher/k3s/k3s.yaml ]; do
    sleep 2
done

echo "[INFO] Exporting token and kubeconfig to shared directory..."

# Copy token
mkdir -p "${SHARED_DIR}"
cp /var/lib/rancher/k3s/server/node-token "${SHARED_DIR}/k3s_token"
chmod 600 "${SHARED_DIR}/k3s_token"

# Copy and fix kubeconfig
cp /etc/rancher/k3s/k3s.yaml "${SHARED_DIR}/kubeconfig.yaml"
sed -i "s/127.0.0.1/${SERVER_IP}/g" "${SHARED_DIR}/kubeconfig.yaml"
chmod 600 "${SHARED_DIR}/kubeconfig.yaml"

echo "[SUCCESS] K3s server installation complete!"
echo "[INFO] Token exported to: ${SHARED_DIR}/k3s_token"
echo "[INFO] Kubeconfig exported to: ${SHARED_DIR}/kubeconfig.yaml"
