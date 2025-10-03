#!/bin/sh
set -eu

cd "$(dirname "$0")/.."

if ! command -v vagrant >/dev/null 2>&1; then
  echo 'Vagrant is not installed or not in PATH.' >&2
  exit 1
fi

vagrant ssh wstyggS -c "sudo kubectl get nodes -o wide"
