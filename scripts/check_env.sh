#!/bin/sh
set -eu

STATUS=0

green() { printf '[32m%s[0m' "$1"; }
red() { printf '[31m%s[0m' "$1"; }
yellow() { printf '[33m%s[0m' "$1"; }
plain() { printf '%s' "$1"; }

print_status() {
  label="$1"
  verdict="$2"
  shift 2 || true
  message="$*"
  printf '%-35s' "$label"
  case "$verdict" in
    OK) green "[OK]" ;;
    WARN) yellow "[WARN]" ;;
    FAIL) red "[FAIL]" ; STATUS=1 ;;
    INFO) plain "[INFO]" ;;
    *) plain "[INFO]" ;;
  esac
  [ -n "$message" ] && printf ' %s' "$message"
  printf '
'
}

OS=$(uname -s 2>/dev/null || printf 'unknown')
ARCH=$(uname -m 2>/dev/null || printf 'unknown')
print_status "Operating system" INFO "$OS"
print_status "CPU architecture" INFO "$ARCH"

if [ "$OS" = "Linux" ]; then
  print_status "Linux requirement" OK
else
  print_status "Linux requirement" FAIL "Project targets Ubuntu/Linux hosts"
fi

if [ "$ARCH" = "x86_64" ]; then
  print_status "x86_64 requirement" OK
else
  print_status "x86_64 requirement" FAIL "Detected $ARCH"
fi

if [ -r /proc/cpuinfo ]; then
  if grep -E -q 'vmx|svm' /proc/cpuinfo; then
    print_status "CPU virtualization flags" OK "vmx/svm flag detected"
  else
    print_status "CPU virtualization flags" WARN "Hardware virtualization not exposed"
  fi
else
  print_status "CPU virtualization flags" WARN "Cannot read /proc/cpuinfo"
fi

if command -v systemd-detect-virt >/dev/null 2>&1; then
  if systemd-detect-virt --quiet 2>/dev/null; then
    virt=$(systemd-detect-virt 2>/dev/null || printf 'unknown')
    print_status "Host virtualization layer" WARN "Running inside $virt"
  else
    print_status "Host virtualization layer" OK "Bare metal or undetected"
  fi
else
  print_status "Host virtualization layer" INFO "systemd-detect-virt not available"
fi

if command -v vagrant >/dev/null 2>&1; then
  version=$(vagrant --version 2>/dev/null || printf 'detected')
  print_status "Vagrant" OK "$version"
else
  print_status "Vagrant" FAIL "Not found in PATH"
fi

if command -v VBoxManage >/dev/null 2>&1; then
  print_status "VirtualBox provider" OK "Version $(VBoxManage --version 2>/dev/null)"
elif command -v virsh >/dev/null 2>&1; then
  print_status "Libvirt provider" OK "$(virsh --version 2>/dev/null)"
else
  print_status "Virtualization provider" FAIL "Install VirtualBox or libvirt"
fi

if command -v kubectl >/dev/null 2>&1; then
  print_status "kubectl" OK "$(kubectl version --client --short 2>/dev/null || echo 'present')"
else
  print_status "kubectl" WARN "Not found; needed for cluster management"
fi

if command -v docker >/dev/null 2>&1; then
  if docker info >/dev/null 2>&1; then
    print_status "Docker" OK "daemon reachable"
  else
    print_status "Docker" WARN "CLI found but daemon unreachable"
  fi
else
  print_status "Docker" WARN "Not found; required for k3d"
fi

if command -v k3d >/dev/null 2>&1; then
  print_status "k3d" OK "$(k3d version 2>/dev/null | head -n 1)"
else
  print_status "k3d" WARN "Not found; required for Part 3"
fi

if command -v helm >/dev/null 2>&1; then
  print_status "Helm" OK "$(helm version --short 2>/dev/null || echo 'present')"
else
  print_status "Helm" WARN "Not found; recommended for bonus"
fi

if command -v virsh >/dev/null 2>&1; then
  if id -nG 2>/dev/null | grep -qw libvirt; then
    print_status "User in libvirt group" OK
  else
    print_status "User in libvirt group" WARN "Add current user to libvirt for provider access"
  fi
fi

if command -v docker >/dev/null 2>&1; then
  if id -nG 2>/dev/null | grep -qw docker; then
    print_status "User in docker group" OK
  else
    print_status "User in docker group" WARN "Add current user to docker group"
  fi
fi

print_status "Effective UID" INFO "$(id -u)"

if [ $STATUS -ne 0 ]; then
  echo "One or more required checks failed. Review the FAIL entries above." >&2
fi

exit $STATUS
