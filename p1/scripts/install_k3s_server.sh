#!/bin/sh
set -eu

NODE_IP=${1:?"node IP required"}
SHARED_DIR=${2:-/vagrant/shared}

log() {
  printf '[%s] %s
' "$(date -u +%H:%M:%S)" "$1"
}

K3S_VERSION_FILE=/vagrant/confs/k3s_version
if [ -f "$K3S_VERSION_FILE" ]; then
  K3S_VERSION=$(sed -n '1p' "$K3S_VERSION_FILE" | tr -d '
')
else
  K3S_VERSION=""
fi

INSTALL_ARGS="server --node-ip ${NODE_IP} --tls-san ${NODE_IP} --write-kubeconfig-mode 644 --node-name $(hostname --short)"

if systemctl is-active --quiet k3s; then
  log 'k3s service already active; skipping install'
else
  log 'Installing k3s server'
  if [ -n "$K3S_VERSION" ]; then
    log "Using k3s version $K3S_VERSION"
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="$K3S_VERSION" INSTALL_K3S_EXEC="$INSTALL_ARGS" sh -
  else
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="$INSTALL_ARGS" sh -
  fi
fi

systemctl enable --now k3s >/dev/null

TOKEN_SRC=/var/lib/rancher/k3s/server/node-token
KUBECONFIG_SRC=/etc/rancher/k3s/k3s.yaml

log 'Waiting for node token'
COUNTER=0
while [ ! -s "$TOKEN_SRC" ]; do
  sleep 2
  COUNTER=$((COUNTER + 1))
  if [ $COUNTER -gt 30 ]; then
    log 'Still waiting for node token...'
    COUNTER=0
  fi
  systemctl is-active --quiet k3s || systemctl restart k3s || true
done

install -d -m 700 "$SHARED_DIR"
install -m 600 "$TOKEN_SRC" "$SHARED_DIR/node-token"
chown vagrant:vagrant "$SHARED_DIR/node-token"
log "Copied node token to $SHARED_DIR/node-token"

if [ -f "$KUBECONFIG_SRC" ]; then
  install -m 600 "$KUBECONFIG_SRC" "$SHARED_DIR/kubeconfig"
  chown vagrant:vagrant "$SHARED_DIR/kubeconfig"
  log "Copied kubeconfig to $SHARED_DIR/kubeconfig"
fi

log 'k3s server provisioning complete'
