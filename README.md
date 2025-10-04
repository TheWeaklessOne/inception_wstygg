# Inception-of-Things (IoT)

This project implements a series of Kubernetes infrastructure exercises using K3s, K3d, and Vagrant.

## Project Structure

```
.
├── p1/                   # Part 1: K3s cluster with Vagrant (2 nodes)
│   ├── Makefile          # Part 1 automation (all, clean, re)
│   ├── Vagrantfile
│   ├── scripts/
│   └── README.md
├── p2/                   # Part 2: K3s + Ingress (TBD)
├── p3/                   # Part 3: K3d + Argo CD (TBD)
└── bonus/                # Bonus: GitLab integration (TBD)
```

## Quick Start

### Prerequisites

- **Target environment**: Ubuntu Linux x86_64
- **Required tools**: Vagrant 2.4.x, VirtualBox 7.x, kubectl

### Part 1 - K3s Cluster

Deploy and test the two-node K3s cluster:
```bash
cd p1
make          # Start cluster (vagrant up)

# Test from host
export KUBECONFIG=$(pwd)/shared/kubeconfig.yaml
kubectl get nodes -o wide

# Cleanup
make clean    # Destroy VMs and remove artifacts
```

See [p1/README.md](p1/README.md) for detailed Part 1 documentation.

### Part 1 Makefile Commands

Inside `p1/` directory:
- `make` or `make all` - Start cluster (vagrant up)
- `make check` - Verify cluster is correctly configured
- `make clean` - Destroy VMs and remove artifacts
- `make re` - Clean and rebuild (clean + all)

## Subject Requirements

### Part 1: K3s and Vagrant ✅
- [x] Two VMs: wstyggS (server), wstyggSW (worker)
- [x] Static IPs: 192.168.56.110/111
- [x] 1 CPU, 1 GB RAM each
- [x] Passwordless SSH via Vagrant
- [x] K3s server/agent setup
- [x] kubectl access from host

### Part 2: K3s and Ingress (TODO)
- [ ] Single VM with K3s
- [ ] Three applications with Ingress routing
- [ ] App 2 with exactly 3 replicas

### Part 3: K3d and Argo CD (TODO)
- [ ] K3d cluster (no Vagrant)
- [ ] Argo CD GitOps setup
- [ ] GitHub repository integration

### Bonus: GitLab (TODO)
- [ ] Local GitLab installation
- [ ] Argo CD + GitLab integration

## Documentation

- [Implementation Plan](.agents/IMPLEMENTATION_PLAN.md) - Detailed implementation strategy
- [Project Documentation](.agents/PROJECT_DOCUMENTATION.md) - Project overview and requirements
- [Subject](.agents/en.subject.txt) - Original project subject

## Notes

### Storage & Permissions
- **All files stay in project directory** - no sudo/root access required
- Vagrant boxes stored locally in `p1/.vagrant.d/` (~600MB per box)
- VM data in `p1/.vagrant/` - both cleaned by `make clean`
- All artifacts use permission 600 for security

### Technical Details
- All VMs run Ubuntu 22.04 (jammy64)
- K3s is installed via official installer script
- Shared folder `/vagrant_shared` is used for token/kubeconfig exchange
- Project designed for Ubuntu Linux x86_64 host environment

## License

School project for 42 School / École 42
