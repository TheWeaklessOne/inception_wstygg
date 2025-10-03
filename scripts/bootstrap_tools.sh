#!/bin/sh
set -eu

PREFIX=${PREFIX:-"$HOME/.local/bin"}
mkdir -p "$PREFIX"

log() {
  printf '%s
' "$*"
}

fetch() {
  url=$1
  dest=$2
  tmp=$(mktemp)
  log "Downloading $url"
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$url" -o "$tmp"
  elif command -v wget >/dev/null 2>&1; then
    wget -q "$url" -O "$tmp"
  else
    echo "Neither curl nor wget available" >&2
    exit 1
  fi
  mv "$tmp" "$dest"
}

install_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then
    log "kubectl already in PATH ($(command -v kubectl))"
    return
  fi
  version=${KUBECTL_VERSION:-"v1.30.6"}
  url="https://dl.k8s.io/release/${version}/bin/linux/amd64/kubectl"
  dest="$PREFIX/kubectl"
  fetch "$url" "$dest"
  chmod +x "$dest"
  log "kubectl ${version} installed to $dest"
}

install_k3d() {
  if command -v k3d >/dev/null 2>&1; then
    log "k3d already in PATH ($(command -v k3d))"
    return
  fi
  version=${K3D_VERSION:-"v5.8.3"}
  url="https://github.com/k3d-io/k3d/releases/download/${version}/k3d-linux-amd64"
  dest="$PREFIX/k3d"
  fetch "$url" "$dest"
  chmod +x "$dest"
  log "k3d ${version} installed to $dest"
}

install_helm() {
  if command -v helm >/dev/null 2>&1; then
    log "Helm already in PATH ($(command -v helm))"
    return
  fi
  version=${HELM_VERSION:-"v3.16.3"}
  archive="helm-${version}-linux-amd64.tar.gz"
  url="https://get.helm.sh/${archive}"
  tmpdir=$(mktemp -d)
  fetch "$url" "$tmpdir/$archive"
  tar -xzf "$tmpdir/$archive" -C "$tmpdir"
  mv "$tmpdir/linux-amd64/helm" "$PREFIX/helm"
  chmod +x "$PREFIX/helm"
  rm -rf "$tmpdir"
  log "Helm ${version} installed to $PREFIX/helm"
}

install_kubectl
install_k3d
install_helm

log "Ensure $PREFIX is on your PATH (export PATH="$PREFIX:$PATH")."
