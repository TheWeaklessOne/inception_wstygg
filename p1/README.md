# Inception-of-Things — Part 1 (K3s on Vagrant)

This project provisions two Ubuntu 22.04 VMs with Vagrant:
- wstyggS (server) — 192.168.56.110
- wstyggSW (worker) — 192.168.56.111

K3s is installed on both (server + agent), and a kubeconfig is exported to the host via the `shared/` directory so you can use `kubectl` from your host.

## Requirements
- VirtualBox or another Vagrant-supported provider
- Vagrant
- kubectl on your host (install per your OS if not present)

## Directory layout
- Vagrantfile
- scripts/
  - server.sh
  - worker.sh
- shared/
  - kubeconfig.yaml (generated, permission 600)
  - k3s_token (generated, permission 600)
- README.md

## Usage

### With Makefile (recommended)
```bash
make          # Start cluster (vagrant up)
make check    # Verify cluster (run after 'make')
make clean    # Destroy VMs and remove artifacts
make re       # Clean and rebuild
```

### Manual commands
```bash
vagrant up    # Start both VMs
  # Or separately:
  # vagrant up wstyggS
  # vagrant up wstyggSW

# Use kubectl from host
export KUBECONFIG=$(pwd)/shared/kubeconfig.yaml
kubectl get nodes -o wide

# Cleanup
vagrant destroy -f
```

## Notes
- **Local storage**: Vagrant boxes and VM data are stored in `.vagrant.d/` (no sudo/system dirs)
- The kubeconfig server URL is automatically set to https://192.168.56.110:6443 for host access
- The join token is written to shared/k3s_token (permission 600)
- The kubeconfig is written to shared/kubeconfig.yaml (permission 600) for kubectl security
- Vagrant provides passwordless SSH access out of the box
- `make clean` removes all generated files including vagrant boxes (~600MB)

## Testing on Ubuntu x86_64 (Target Environment)

This project is designed for **Ubuntu Linux x86_64** with VirtualBox and Vagrant. Testing commands:

```bash
# 1. Start the cluster
vagrant up

# 2. Verify cluster is ready
export KUBECONFIG=$(pwd)/shared/kubeconfig.yaml
kubectl cluster-info
kubectl get nodes -o wide

# Expected output: 2 nodes (wstyggS and wstyggSW) in Ready state

# 3. Test SSH access (provided by Vagrant)
vagrant ssh wstyggS -c "sudo kubectl get nodes"
vagrant ssh wstyggSW -c "hostname && ip addr show"

# 4. Verify artifacts
ls -la shared/  # Should contain kubeconfig.yaml (600) and k3s_token (600)
grep "192.168.56.110:6443" shared/kubeconfig.yaml  # Should find server URL

# 5. Test idempotency
vagrant provision  # Should succeed without errors
```

## Troubleshooting

If you encounter issues:

```bash
# Check K3s services status
vagrant ssh wstyggS -c "sudo systemctl status k3s"
vagrant ssh wstyggSW -c "sudo systemctl status k3s-agent"

# View logs
vagrant ssh wstyggS -c "sudo journalctl -u k3s -xe --no-pager | tail -n 50"
vagrant ssh wstyggSW -c "sudo journalctl -u k3s-agent -xe --no-pager | tail -n 50"

# Verify shared artifacts
ls -la shared/

# Test network connectivity from worker to server
vagrant ssh wstyggSW -c "curl -k https://192.168.56.110:6443/version"

# Recreate worker if needed
vagrant destroy -f wstyggSW && vagrant up wstyggSW
```

## Subject compliance checklist
- ✅ Two machines with correct naming: wstyggS, wstyggSW
- ✅ Specific IPs: 192.168.56.110 (server), 192.168.56.111 (worker)
- ✅ 1 CPU, 1 GB RAM each
- ✅ Passwordless SSH via Vagrant
- ✅ K3s server/agent setup (server exports kubeconfig and token; worker waits for token)
- ✅ kubectl access from host using shared/kubeconfig.yaml
