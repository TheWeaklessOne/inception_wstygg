# Part 2: K3s and Three Simple Applications

## Overview

Part 2 demonstrates **host-based routing** using Kubernetes Ingress with three simple web applications running on a single K3s server node.

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     VM: wstyggS                         │
│                  IP: 192.168.56.110                     │
│                                                         │
│  ┌───────────────────────────────────────────────────┐ │
│  │              K3s Server (single node)             │ │
│  │                                                   │ │
│  │  ┌─────────────────────────────────────────────┐ │ │
│  │  │     Traefik Ingress Controller             │ │ │
│  │  │                                             │ │ │
│  │  │  Host: app1.com    →    App1 (1 replica)  │ │ │
│  │  │  Host: app2.com    →    App2 (3 replicas) │ │ │
│  │  │  Host: * (default) →    App3 (1 replica)  │ │ │
│  │  └─────────────────────────────────────────────┘ │ │
│  │                                                   │ │
│  │  Namespace: webapps                               │ │
│  │  - Deployments: app1, app2, app3                  │ │
│  │  - Services: app1-service, app2-service, app3...  │ │
│  │  - Ingress: apps-ingress                          │ │
│  └───────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Requirements Met

✅ **Single VM** with K3s in server mode  
✅ **VM name**: wstyggS (login + S)  
✅ **IP address**: 192.168.56.110  
✅ **3 web applications** with host-based routing  
✅ **App2 has 3 replicas** (as per subject requirement)  
✅ **Minimal resources**: 1 CPU, 1024 MB RAM (subject allows 512-1024)  

## Directory Structure

```
p2/
├── Vagrantfile                 # VM configuration
├── Makefile                    # Automation targets
├── README.md                   # This file
├── scripts/
│   ├── server.sh              # K3s server installation script
│   ├── bootstrap_apps.sh      # Application deployment script
│   └── smoke.sh               # Ingress routing tests
├── manifests/
│   └── apps.yaml              # All Kubernetes resources
└── shared/                     # Created by Vagrant
    └── kubeconfig.yaml        # Exported for host access
```

## Usage

### Quick Start

```bash
# Start the cluster and deploy apps
make

# Check cluster status and verify setup
make check

# Run Ingress routing tests
make smoke

# Clean up everything
make clean

# Rebuild from scratch
make re
```

### Manual Testing

#### 1. Access VM

```bash
vagrant ssh wstyggS
```

#### 2. Check Cluster

```bash
# Inside VM
sudo kubectl get nodes
sudo kubectl get deployments -n webapps
sudo kubectl get pods -n webapps
sudo kubectl get ingress -n webapps
```

#### 3. Test Ingress Routing

```bash
# Inside VM - test host-based routing
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl -H "Host: anything.else" http://192.168.56.110  # Should route to app3
curl http://192.168.56.110                            # Should route to app3 (default)
```

#### 4. From Host Machine

```bash
# Test from your Mac using exported kubeconfig
export KUBECONFIG=./shared/kubeconfig.yaml
kubectl get nodes
kubectl get pods -n webapps

# Test Ingress routing from host using Host header (no /etc/hosts modification needed)
curl -H "Host: app1.com" http://192.168.56.110
curl -H "Host: app2.com" http://192.168.56.110
curl http://192.168.56.110  # Default route to app3
```

## Components

### Applications

1. **App1** (`app1.com`)
   - 1 replica
   - Nginx serving blue-themed HTML
   - Accessed via `Host: app1.com`

2. **App2** (`app2.com`)
   - **3 replicas** (subject requirement)
   - Nginx serving purple-themed HTML
   - Accessed via `Host: app2.com`
   - Load balanced across 3 pods

3. **App3** (default/catch-all)
   - 1 replica
   - Nginx serving green-themed HTML
   - Default route for any other hostname or no hostname

### Ingress Configuration

The Ingress resource (`apps-ingress`) uses Traefik (K3s default) to route traffic based on the `Host` header:

- **Specific hosts**: `app1.com` → app1, `app2.com` → app2
- **Catch-all**: Any other host or no host → app3 (default)

## Validation

### Automated Checks

Run `make check` to verify:

1. ✅ VM is running
2. ✅ K3s cluster is accessible
3. ✅ Deployments are ready
4. ✅ App2 has exactly 3 replicas
5. ✅ Kubeconfig is exported

### Smoke Tests

Run `make smoke` to test:

1. ✅ `app1.com` routes to App1
2. ✅ `app2.com` routes to App2
3. ✅ Unknown host routes to App3 (default)
4. ✅ No host header routes to App3 (default)

## Troubleshooting

### VM won't start

```bash
# Check Vagrant status
vagrant status

# See detailed logs
vagrant up --debug

# Check VirtualBox VMs
VBoxManage list vms
```

### K3s not ready

```bash
# SSH into VM
vagrant ssh wstyggS

# Check K3s service
sudo systemctl status k3s

# View logs
sudo journalctl -u k3s -f

# Check API readiness
curl -sk https://192.168.56.110:6443/readyz
```

### Deployments not starting

```bash
vagrant ssh wstyggS

# Check pod status
sudo kubectl get pods -n webapps

# Describe pods for events
sudo kubectl describe pods -n webapps

# Check pod logs
sudo kubectl logs -n webapps -l app=app2
```

### Ingress not routing correctly

```bash
vagrant ssh wstyggS

# Check Ingress resource
sudo kubectl get ingress -n webapps -o yaml

# Check Traefik logs (K3s default ingress controller)
sudo kubectl logs -n kube-system -l app.kubernetes.io/name=traefik

# Test from inside VM
curl -v -H "Host: app1.com" http://192.168.56.110
```

### Port 80 issues

K3s/Traefik listens on port 80 by default. If you see "connection refused":

```bash
# Check if Traefik is running
sudo kubectl get pods -n kube-system -l app.kubernetes.io/name=traefik

# Check service
sudo kubectl get svc -n kube-system traefik
```

## Performance Notes

With **minimal resources** (1 CPU, 1024 MB RAM):
- Initial K3s startup: 1-3 minutes
- SQLite initialization can be slow
- All 3 apps + Ingress fit comfortably in memory
- Provisioning time: 3-5 minutes total

## Subject Compliance

This implementation strictly follows the subject requirements:

✅ Uses **Vagrant** for VM management  
✅ Uses **latest stable Ubuntu** (jammy64 = 22.04 LTS)  
✅ **Minimal resources**: 1 CPU, 1024 MB RAM  
✅ **VM name**: wstyggS (login + S)  
✅ **IP address**: 192.168.56.110  
✅ **K3s in server mode** (single node for Part 2)  
✅ **3 web applications** with distinct content  
✅ **Host-based routing** via Ingress  
✅ **App2 has 3 replicas**  
✅ **Default route** goes to app3  

## Next Steps

After verifying Part 2:
- Move to **Part 3**: K3d and Argo CD for GitOps workflow
- Explore advanced Ingress features (TLS, path-based routing)
- Scale deployments dynamically
- Add monitoring with Prometheus/Grafana

---

**Author**: wstygg  
**Project**: Inception-of-Things (IoT)  
**Part**: 2/3
