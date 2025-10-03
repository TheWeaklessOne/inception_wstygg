#!/bin/sh
set -eu

NODE_IP=${1:?"worker IP required"}
SERVER_IP=${2:?"server IP required"}
SHARED_DIR=${3:-/vagrant/shared}

log() {
  printf '[%s] %s
' "$(date -u +%H:%M:%S)" "$1"
}

TOKEN_FILE="$SHARED_DIR/node-token"
COUNTER=0
log "Waiting for token file at $TOKEN_FILE"
while [ ! -s "$TOKEN_FILE" ]; do
  sleep 2
  COUNTER=$((COUNTER + 1))
  if [ $COUNTER -gt 30 ]; then
    log 'Still waiting for node token...'
    COUNTER=0
  fi
done

K3S_TOKEN=$(sed -n '1p' "$TOKEN_FILE" | tr -d '
')
if [ -z "$K3S_TOKEN" ]; then
  log 'Token file is empty'
  exit 1
fi

K3S_VERSION_FILE=/vagrant/confs/k3s_version
if [ -f "$K3S_VERSION_FILE" ]; then
  K3S_VERSION=$(sed -n '1p' "$K3S_VERSION_FILE" | tr -d '
')
else
  K3S_VERSION=""
fi

INSTALL_ARGS="agent --node-ip ${NODE_IP} --node-name $(hostname --short)"
K3S_URL="https://${SERVER_IP}:6443"

if systemctl is-active --quiet k3s-agent; then
  log 'k3s-agent already active; skipping install'
else
  log 'Installing k3s agent'
  if [ -n "$K3S_VERSION" ]; then
    log "Using k3s version $K3S_VERSION"
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" INSTALL_K3S_EXEC="$INSTALL_ARGS" K3S_TOKEN="$K3S_TOKEN" K3S_URL="$K3S_URL" sh -
  else
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="$INSTALL_ARGS" K3S_TOKEN="$K3S_TOKEN" K3S_URL="$K3S_URL" sh -
  fi
fi

systemctl enable --now k3s-agent >/dev/null
log 'k3s agent provisioning complete'
