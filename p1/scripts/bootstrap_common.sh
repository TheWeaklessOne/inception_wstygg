#!/bin/sh
set -eu

HOSTNAME_TARGET=${1:-wstyggS}

log() {
  printf '[%s] %s
' "$(date -u +%H:%M:%S)" "$1"
}

if command -v hostnamectl >/dev/null 2>&1; then
  CURRENT=$(hostnamectl --static 2>/dev/null || true)
  if [ "${CURRENT:-}" != "$HOSTNAME_TARGET" ]; then
    log "Setting hostname to $HOSTNAME_TARGET"
    hostnamectl set-hostname "$HOSTNAME_TARGET"
  fi
fi

log 'Updating apt cache'
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null
apt-get install -y --no-install-recommends   ca-certificates   curl   jq   net-tools   nfs-common >/dev/null

log 'Loading br_netfilter and configuring sysctl'
modprobe br_netfilter 2>/dev/null || true
cat >/etc/modules-load.d/k8s.conf <<'EOF'
br_netfilter
EOF
cat >/etc/sysctl.d/99-kubernetes-cri.conf <<'EOF'
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system >/dev/null

log 'Disabling swap'
if swapon --summary | grep -q .; then
  swapoff -a
fi
sed -i.bak '/\sswap\s/ s/^/#/' /etc/fstab

SSH_DIR=/home/vagrant/.ssh
AUTH_FILE="$SSH_DIR/authorized_keys"
SOURCE_KEYS=/vagrant/confs/authorized_keys
if [ -f "$SOURCE_KEYS" ]; then
  log 'Configuring passwordless SSH for vagrant user'
  install -d -m 700 "$SSH_DIR"
  touch "$AUTH_FILE"
  chmod 600 "$AUTH_FILE"
  while IFS= read -r line || [ -n "$line" ]; do
    [ -z "${line##\#*}" ] && continue
    grep -qxF "$line" "$AUTH_FILE" 2>/dev/null || printf '%s
' "$line" >>"$AUTH_FILE"
  done <"$SOURCE_KEYS"
  chown -R vagrant:vagrant "$SSH_DIR"
else
  log 'No authorized_keys provided; skipping SSH updates'
fi

log 'Ensuring shared directory exists'
install -d -m 700 /vagrant/shared

log 'Bootstrap complete'
