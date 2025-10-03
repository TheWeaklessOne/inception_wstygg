# Part 1 - K3s Two-Node Cluster

This directory provisions two Ubuntu 22.04 virtual machines using Vagrant + VirtualBox:

- `wstyggS` (controller) at `192.168.56.110`
- `wstyggSW` (worker) at `192.168.56.111`

Both guests run K3s; the worker joins automatically using the shared token.

## Prerequisites
- Host runs Ubuntu Linux (x86_64) with Vagrant 2.4.x and VirtualBox 7.x available.
- No sudo privileges are required; run all commands from the repository root.
- Ensure the VirtualBox host-only network `192.168.56.0/24` exists and is free.

## Files
- `Vagrantfile` - defines the two VMs and provisioning workflow.
- `scripts/bootstrap_common.sh` - common setup (packages, sysctl, swap off, SSH keys).
- `scripts/install_k3s_server.sh` - installs K3s controller and exports token/kubeconfig to `shared/`.
- `scripts/install_k3s_agent.sh` - installs K3s agent and joins the cluster.
- `scripts/check_cluster.sh` - helper to run `kubectl get nodes` inside the controller.
- `confs/authorized_keys` - add host SSH public keys (one per line).
- `shared/` - populated with `node-token` and `kubeconfig` after provisioning.

## Usage

1. Populate SSH keys (optional but recommended):
   ```bash
   cat ~/.ssh/id_ed25519.pub >> p1/confs/authorized_keys
   ```
2. Start the environment:
   ```bash
   cd p1
   vagrant up
   ```
3. Check cluster status:
   ```bash
   ./scripts/check_cluster.sh
   ```
   or from inside the controller:
   ```bash
   vagrant ssh wstyggS -c "sudo kubectl get nodes -o wide"
   ```
4. Access the nodes:
   ```bash
   vagrant ssh wstyggS
   vagrant ssh wstyggSW
   ```
5. Optional host-side kubectl:
   ```bash
   KUBECONFIG=shared/kubeconfig kubectl get nodes
   ```

## Cleanup
```bash
cd p1
vagrant destroy -f
rm -f shared/node-token shared/kubeconfig
```

## Notes
- Provisioning scripts are idempotent; re-run `vagrant provision wstyggS` or `vagrant provision wstyggSW` after script updates.
- `confs/k3s_version` (optional) can pin a specific K3s release by placing the version string on the first line.
