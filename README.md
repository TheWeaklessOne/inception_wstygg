# Inception-of-Things (IoT)

System Administration project focused on mastering Kubernetes through K3s, K3d, and Vagrant.

## 📋 Project Structure

```
.
├── Makefile              # Build automation for all parts
├── p1/                   # Part 1: K3s + Vagrant (2-node cluster)
│   ├── Vagrantfile
│   ├── scripts/
│   └── confs/
├── p2/                   # Part 2: K3s + 3 applications (Ingress)
├── p3/                   # Part 3: K3d + Argo CD (GitOps)
└── bonus/                # Bonus: GitLab integration
```

## 🚀 Quick Start

### Prerequisites Check & Installation

The Makefile will automatically check and install all required tools:

```bash
make setup
```

This installs (if missing):
- Homebrew
- Vagrant
- VirtualBox
- kubectl
- Docker Desktop
- k3d
- Helm

### Running a Part

Each part has standardized commands:

```bash
# Part 1: K3s + Vagrant
make p1-setup    # Setup prerequisites
make p1-run      # Start the cluster (includes setup + test)
make p1-test     # Test the cluster
make p1-clean    # Clean everything

# Part 2: K3s + 3 Applications
make p2-setup
make p2-run
make p2-test
make p2-clean

# Part 3: K3d + Argo CD
make p3-setup
make p3-run
make p3-test
make p3-clean

# Bonus: GitLab Integration
make bonus-setup
make bonus-run
make bonus-clean
```

## 📖 Detailed Commands

### Global Commands

- `make help` - Show all available commands
- `make setup` - Check and install all required tools
- `make check-tools` - Verify tools are installed

### Part 1 - K3s and Vagrant

Creates a 2-node K3s cluster:
- **Server** (`wstyggS`): 192.168.56.110
- **Worker** (`wstyggSW`): 192.168.56.111

```bash
# Start everything
make p1-run

# Or step by step:
make p1-setup     # Configure SSH keys, /etc/hosts
cd p1 && vagrant up
make p1-test      # Verify cluster and SSH access

# Clean for fresh start
make p1-clean     # Destroys VMs, removes all temp files
```

**What p1-clean removes:**
- ✅ Vagrant VMs
- ✅ `.vagrant/` directory
- ✅ Shared files (node-token, kubeconfig)
- ✅ VirtualBox VM registrations
- ✅ `/etc/hosts` entries

**Manual access:**
```bash
# SSH to nodes
ssh vagrant@192.168.56.110  # Server
ssh vagrant@192.168.56.111  # Worker

# Or via Vagrant
cd p1 && vagrant ssh wstygg
cd p1 && vagrant ssh wstygg_worker

# Check cluster
cd p1 && vagrant ssh wstygg -c "sudo kubectl get nodes"
```

### Part 2 - K3s and Three Applications

Single VM with 3 web apps and Ingress routing:
- `app1.com` → Application 1
- `app2.com` → Application 2 (3 replicas)
- default → Application 3

```bash
make p2-run       # Start everything
make p2-test      # Test all three applications
make p2-clean     # Clean everything
```

**What p2-clean removes:**
- ✅ Vagrant VMs
- ✅ `.vagrant/` directory
- ✅ Shared files
- ✅ `/etc/hosts` entries (app1.com, app2.com, app3.com)
- ✅ VirtualBox VM registrations

### Part 3 - K3d and Argo CD

K3d cluster with GitOps pipeline:
- Namespace `argocd`: Argo CD installation
- Namespace `dev`: Deployed application

```bash
make p3-run       # Create cluster and deploy Argo CD
make p3-test      # Test namespaces and pods
make p3-clean     # Destroy cluster
```

**What p3-clean removes:**
- ✅ K3d cluster
- ✅ Generated kubeconfig files
- ✅ Docker containers and networks

### Bonus - GitLab Integration

GitLab running in cluster with Argo CD integration.

```bash
make bonus-run
make bonus-clean
```

## 🧹 Clean Commands Details

Each `clean` command ensures **complete removal** of all artifacts:

### p1-clean
1. Destroys Vagrant VMs (`vagrant destroy -f`)
2. Removes `.vagrant/` directory
3. Removes shared files (token, kubeconfig)
4. Unregisters VirtualBox VMs
5. Removes `/etc/hosts` entries (requires sudo)

### p2-clean
1. Destroys Vagrant VMs
2. Removes `.vagrant/` directory
3. Removes shared files
4. Unregisters VirtualBox VMs
5. Removes app `/etc/hosts` entries

### p3-clean
1. Deletes k3d cluster (`k3d cluster delete`)
2. Removes kubeconfig files
3. Cleans Docker containers/networks

## 🔧 Troubleshooting

### Part 1 Issues

**VMs won't start:**
```bash
make p1-clean  # Clean everything first
make p1-run    # Try again
```

**SSH not working:**
```bash
# Check SSH key is configured
cat p1/confs/authorized_keys

# Regenerate if needed
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
cat ~/.ssh/id_ed25519.pub > p1/confs/authorized_keys
```

**Vagrant errors:**
```bash
# Validate Vagrantfile
cd p1 && vagrant validate

# Check VirtualBox
VBoxManage list vms
```

### Part 3 Issues

**Docker not running:**
```bash
# Start Docker Desktop manually
open -a Docker

# Wait for Docker to start
docker info
```

**k3d cluster issues:**
```bash
# List clusters
k3d cluster list

# Delete and recreate
make p3-clean
make p3-run
```

## 📝 Defense Preparation

Before defense, ensure clean environment:

```bash
# Clean everything
make p1-clean
make p2-clean
make p3-clean

# Verify tools are installed
make check-tools

# Start fresh
make p1-run
```

## 🔒 Security Notes

- SSH keys are auto-generated if missing
- Private keys are NEVER committed to git
- Only public keys are stored in `confs/authorized_keys`
- Sudo required for `/etc/hosts` modifications

## 📚 Additional Resources

- [Official Subject](.agents/en.subject.txt)
- [Project Documentation](.agents/PROJECT_DOCUMENTATION.md)
- [Implementation Plan](.agents/IMPLEMENTATION_PLAN.md)
- [Part 1 README](p1/README.md)

## 🎯 Project Requirements Summary

- **Part 1**: 2 VMs, K3s cluster, passwordless SSH
- **Part 2**: 1 VM, 3 apps, Ingress routing, app2 has exactly 3 replicas
- **Part 3**: K3d cluster, Argo CD, GitOps with v1/v2 versions
- **Bonus**: GitLab in cluster, integrated with Argo CD

---

**Made with ❤️ for 42 School**
