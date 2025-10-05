# Implementation Plan for Inception-of-Things

Target environment: Ubuntu Linux (x86_64) host without sudo/root. VirtualBox 7.x and Vagrant 2.4.x are available. All Kubernetes/Docker tooling is installed inside guest VMs where root access exists. Host operations must stay within the project directory; avoid `/tmp` or system locations.

## Global Workflow
1. Clone the repository into the designated workspace with sufficient disk space.
2. Run `make check-env` to confirm Vagrant/VirtualBox availability.
3. For each part, follow the steps below. All downloads (scripts, binaries) must be written under the project tree (e.g., `p1/shared/`, `p3/bin/`).

## Part 1 - K3s with Vagrant (Two Nodes)

### Goals
- Bring up two VirtualBox guests (`wstyggS`, `wstyggSW`) on Ubuntu 22.04 with the subject IPs.
- Let Vagrant handle passwordless SSH (additional keys optional).
- Install K3s server/agent and drop cluster artefacts (token, kubeconfig) into a shared folder for host-side kubectl.

### Steps
1. **Directory layout**: create `p1/` with `Vagrantfile`, a `scripts/` directory (contains shell provisioners), and an empty `shared/` folder tracked in git. Keep `confs/` only if we later store extra configuration such as custom `authorized_keys`.
2. **Vagrantfile**:
   - Base both machines on `bento/ubuntu-22.04` (or another current LTS) with `config.vm.provider :virtualbox` set to 1 vCPU / 1024 MB RAM.
   - Declare the private network IPs `192.168.56.110` (server) and `192.168.56.111` (agent).
   - Mount `./shared` to `/vagrant_shared` (`create: true`) so provisioning scripts can exchange the node token and kubeconfig.
   - Rely on Vagrant's default SSH key for passwordless access; if we need to trust additional keys later, add a simple inline provisioner that appends `/vagrant/confs/authorized_keys` when the file exists.
3. **Provisioning scripts** (two small shell scripts keep things lightweight):
   - `scripts/server.sh`: update apt cache, install `curl`, run the official K3s installer. **Crucially, wait for K3s API to respond to `/readyz` (full readiness, not just `/ping`) before exporting token and kubeconfig** to prevent race conditions. The `/readyz` endpoint ensures the server can serve agent certificate requests (`/v1-k3s/server-ca.crt`, `/v1-k3s/config`), which require database initialization to complete. Only after `/readyz` succeeds, copy token to `/vagrant_shared/k3s_token` and kubeconfig to `/vagrant_shared/kubeconfig.yaml` with server URL `https://192.168.56.110:6443`. Set both artifacts to mode `600`.
   - `scripts/worker.sh`: wait for `/vagrant_shared/k3s_token`, **then wait for server `/readyz` endpoint** (up to 10 minutes) to ensure the server can issue certificates. Use `INSTALL_K3S_SKIP_START=true` to avoid installer blocking on systemd start, then manually `systemctl start k3s-agent` and wait up to 3 minutes for agent to become active. Pass `--node-name`/`--node-ip` flags and exit early if agent already running.
   - Keep the scripts idempotent (e.g. skip reinstall if `k3s` already running) to support `vagrant provision`.
   - **Race condition prevention**: The `/readyz` checks (not `/ping`) ensure the server's full API stack (including certificate issuer and database) is operational before the worker attempts to join. This eliminates "context deadline exceeded" errors during agent bootstrap on minimal resources (1 CPU/1 GB RAM) where SQLite initialization can take 30-60 seconds.
4. **Verification artefacts**:
   - After `vagrant up`, run `kubectl --kubeconfig=p1/shared/kubeconfig.yaml get nodes` on the host to confirm both nodes are Ready.
   - Optionally ship a helper script `scripts/check_cluster.sh` that wraps the command above for quicker testing.
5. **Documentation**: update `p1/README.md` with instructions to add personal SSH keys (if desired), run `vagrant up`, use the exported kubeconfig, and destroy the lab via `vagrant destroy -f`.

## Part 2 - K3s Single Node with Ingress

### Goals
- Provision a single K3s VM (`wstyggS`) that serves three HTTP apps via Traefik Ingress using host headers.
- Guarantee the second app always runs exactly three replicas.
- Export kubeconfig for host-side verification and supply a smoke test to demo routing.

### Steps
1. **Directory layout**: scaffold `p2/` with:
   - `Vagrantfile`
   - `scripts/` (`server.sh`, `bootstrap_apps.sh`, `smoke.sh`)
   - `manifests/` (single `apps.yaml` bundling namespace, ConfigMaps, Deployments, Services, Ingress)
   - `shared/` (empty, tracked via `.gitignore` pattern)
2. **Vagrantfile**:
   - Base on `ubuntu/jammy64`, 1 vCPU / 1024 MB RAM, machine name/IP `wstyggS` → `192.168.56.110`.
   - Mount `./shared` to `/vagrant_shared` for kubeconfig export.
   - First shell provisioner runs `scripts/server.sh`; second runs `scripts/bootstrap_apps.sh` so manifests apply only after the control plane is ready.
3. **`scripts/server.sh`**:
   - Implement a self-contained installer for Part 2: update apt cache, install prerequisites, run K3s with proper SAN/node-ip, wait for `/readyz`, and export kubeconfig into `/vagrant_shared/` with mode `600`. (Поскольку части оцениваются отдельно, не полагаемся на скрипты из `p1`.)
   - Keep output concise; exit non-zero if readiness probes fail.
4. **`scripts/bootstrap_apps.sh`**:
   - Wait until `kubectl get nodes` reports the single node `Ready`.
   - Apply `/vagrant/manifests/apps.yaml`; reapply safely on subsequent provisions (idempotent).
   - Optionally wait for the three deployments to report available replicas (`kubectl rollout status`).
5. **Kubernetes manifests (`manifests/apps.yaml`)**:
   - Namespace `webapps`.
   - Three ConfigMaps holding minimal HTML snippets for `app1`, `app2`, `app3`.
   - Deployments mounting the ConfigMaps; set `replicas: 3` only for app 2.
   - ClusterIP Services and a Traefik Ingress with exact host rules (`app1.com`, `app2.com`, wildcard/default to app3) plus fallback rule for any host.
6. **Validation helpers**:
   - `scripts/smoke.sh` (run via `vagrant ssh wstyggS -c`) to print pod status and execute the required curl host-header tests.
   - Host instructions to run `kubectl --kubeconfig=p2/shared/kubeconfig.yaml get pods -n webapps`.
7. **Documentation**: update `p2/README.md`
8. **Automation**: author a lightweight `Makefile` in `p2/` with targets `all` (alias for `vagrant up`), `re` (`destroy` then `up`), and `check` (run smoke script + host-side `kubectl` check).
 with macOS-development note, `vagrant up` usage, smoke test, and cleanup steps (`vagrant destroy -f`).

## Part 3 - K3d & Argo CD (Without Vagrant)

### Goals
- Use a dedicated VirtualBox VM (created manually or via helper script) where Docker and K3d are installed with root privilege.
- Install Argo CD, configure GitOps application linked to public GitHub repo.

### Steps
1. **VM Preparation**:
   - Provide instructions/script under `p3/` to create a VirtualBox VM (e.g., using `VBoxManage clone` or documented manual setup). Ensure machine has 2 vCPU/4 GB RAM.
   - Inside VM, run provisioning script (`p3/scripts/bootstrap_vm.sh`) to install Docker (system packages), enable user access, install K3d, kubectl, and Helm. Script executes within VM with sudo.
2. **Cluster Scripts**:
   - `create_cluster.sh`: `k3d cluster create wstygg --api-port 6550 --port "8888:80@loadbalancer"`, store kubeconfig in project folder inside VM (e.g., `/home/vagrant/projects/p3/kubeconfig`).
   - `install_argocd.sh`: apply Argo CD manifests, wait for pods ready, port-forward or expose via LoadBalancer and note admin password retrieval command.
3. **GitOps Application**:
   - Maintain Argo `Application` manifest pointing to GitHub repo (`wstygg-iot-app`). Repository contains Deployment referencing `wil42/playground:v1` and Service/Ingress for port 8888.
   - Document steps to change image tag to `v2`, push commit, and show Argo CD sync.
4. **Validation Scripts**: create `verify_app.sh` to run inside VM:
   ```sh
   kubectl -n dev get deploy
   curl http://localhost:8888/
   ```
5. **Cleanup**: script `destroy_cluster.sh` deletes k3d cluster, removes kubeconfig, and stops Docker containers.

## Bonus - GitLab

1. Use existing VM from Part 3; ensure resources (>=8 GB RAM).
2. Script `install_gitlab.sh` runs Helm install with values stored in `bonus/confs/gitlab-values.yaml` (trim services to essentials).
3. Document creation of PAT, Kubernetes Secret, and Argo CD application update.
4. Provide uninstall script to remove release and namespace.

## Documentation Updates
- Rewrite top-level `README.md` to emphasize host requirements (Vagrant/VirtualBox only) and reference per-part instructions.
- Each part gets its own README with provisioning, verification, and cleanup steps.
- Add note that all downloads happen inside project folders.

## Validation Checklist
- `make check-env` passes (Linux/x86_64, Vagrant, VirtualBox detected).
- Part 1: `kubectl --kubeconfig=p1/shared/kubeconfig.yaml get nodes` on the host shows two Ready nodes; `vagrant ssh` still works without a password.
- Part 2: curl tests confirm Ingress routing; App 2 shows exactly 3 replicas.
- Part 3: k3d cluster runs inside VM, Argo CD syncs GitHub repository, version flip verified via curl.
- Bonus (optional): GitLab deployment accessible and Argo CD continues to sync.

Following this plan keeps host untouched beyond VirtualBox/Vagrant usage and confines all package installation to guest machines.
