# Implementation Plan for Inception-of-Things

This plan expands the official requirements to outline concrete implementation steps and best practices per project part. All work must remain macOS-compatible and reproducible.

## Part 1 - K3s and Vagrant (Two-Node Cluster)

### Snapshot
- Goal: lightweight controller/worker pair (`wstyggS`, `wstyggSW`) with static IPs `192.168.56.110/111` and working K3s.
- Success: `kubectl get nodes` shows both Ready; macOS host SSHs in with its key; `shared/node-token` + `shared/kubeconfig` exist.

### Host Setup (macOS ARM)
1. Install Rosetta (if prompted) and Homebrew.
2. Run `make setup` to install Vagrant, the vagrant-qemu plugin (Apple Silicon), UTM, kubectl, jq, and helpers.
3. Keep the `192.168.56.0/24` host-only subnet free and allowed through the firewall.
4. Expect to run with the QEMU provider on Apple Silicon; VirtualBox's ARM builds remain preview quality and are not supported for this project.

### Host Setup (Linux/Intel macOS/Windows)
1. Install Vagrant and a supported provider (VirtualBox recommended, libvirt acceptable).
2. Install kubectl, jq, and curl via the platform package manager.
3. Ensure host-only networking can allocate `192.168.56.0/24` (or adjust the Vagrantfile accordingly).

### Repo Layout
- `p1/Vagrantfile` - defines both VMs, mounts `./confs` + `./shared`, pins resources to 1 vCPU/1 GB each. Apple Silicon users rely on the qemu plugin (`vagrant up` defaults to it); x86 hosts can choose VirtualBox or libvirt via `VAGRANT_DEFAULT_PROVIDER`.
- `p1/scripts/` - shared bootstrap, server install, agent install (all POSIX `sh`).
- `p1/confs/` - public keys (`authorized_keys`) and optional `k3s_version.txt` to pin releases.
- `p1/shared/` - runtime artifacts populated during provisioning (token, kubeconfig).

### Provisioning Flow
1. `bootstrap_common.sh` sets hostname, installs essentials (`curl`, `ca-certificates`, etc.), enables bridge sysctls, disables swap, appends host SSH keys, ensures `/vagrant/shared` exists.
2. `install_k3s_server.sh` runs K3s server with explicit node IP/SAN, waits for `/var/lib/rancher/k3s/server/node-token`, copies token + kubeconfig into the shared folder (chmod 600).
3. `install_k3s_agent.sh` waits for `shared/node-token`, reads it, joins via `https://192.168.56.110:6443`, and enables the agent service.

### Operations
- `cd p1 && vagrant up` - brings cluster up; rerun `vagrant provision <name>` after script edits.
- Verify: `vagrant ssh wstyggS --command "sudo kubectl get nodes"` or `KUBECONFIG=shared/kubeconfig kubectl get nodes` from macOS.
- SSH from host: `ssh vagrant@192.168.56.110` using the uploaded public key.
- Destroy: `vagrant destroy -f` clears both nodes; remove files from `shared/` if you need a clean token/kubeconfig.

### Guardrails
- Keep scripts idempotent; safe to reapply without wiping the VM.
- Never commit private keys; only public keys live under `confs/`.
- Troubleshoot join issues by checking token presence and `sudo systemctl status k3s` / `k3s-agent`.

## Part 2 - K3s with Three Applications (Ingress Routing)

### 1. Environment Setup
- Reuse the `p2/` directory mirroring the Part 1 layout; define a single VM in `p2/Vagrantfile` with machine name `wstygg`, hostname `wstyggS`, static IP `192.168.56.110`.
- Provision using modular scripts from Part 1 (symlink or invoke shared library scripts) to avoid duplication.
- Declare and apply a dedicated namespace `webapps` via `kubectl apply -f p2/confs/k8s/namespace.yaml`; ensure every manifest in this part sets `metadata.namespace: webapps`.

### 2. Application Packaging
- Select three simple HTTP applications (e.g., Nginx static site, Python Flask, Node.js Express); package each as a container or K3s deployment manifest.
- Store Dockerfiles and build scripts (if custom) in `p2/confs/apps/`; push images to a registry accessible from the VM (Docker Hub or local registry).
- Maintain Kubernetes manifests per app (`deployment`, `service`) in `p2/confs/k8s/`; template with Kustomize or Helm if helpful, and ensure each manifest targets the `webapps` namespace.

### 3. Ingress Configuration
- Deploy Traefik (bundled with K3s) or custom ingress controller; confirm CRDs available.
- Create `Ingress` manifest mapping:
  - `Host: app1.com` -> Service `app1` (1 replica).
  - `Host: app2.com` -> Service `app2` (Deployment replica count exactly 3).
  - Default backend -> Service `app3`.
- Commit Ingress and service manifests to `p2/confs/k8s/ingress.yaml`; annotate with TLS/HTTP redirect placeholders for future enhancements, and set `namespace: webapps` on the Ingress resource.

### 4. DNS / Host Overrides
- Document macOS `/etc/hosts` additions (`app1.com`, `app2.com` -> `192.168.56.110`); test the default backend using a non-matching host header such as `curl -H 'Host: unknown.test' http://192.168.56.110`.
- Provide a helper script `p2/scripts/update_hosts.sh` that first backs up `/etc/hosts` with a timestamped copy, appends/removes entries safely using `sudo tee`, and offers a cleanup routine to restore the previous state.

### 5. Verification Checklist
- `kubectl get pods -n webapps` to confirm `app2` has exactly three replicas; implement a CI hook or Kustomize patch preventing drift.
- Execute curl smoke tests with explicit host headers; script them in `p2/scripts/smoke_tests.sh` and ensure exit codes bubble up.
- Capture screenshots or terminal logs demonstrating routing for defense documentation.

### 6. Best Practices
- Externalize configuration (ports, image tags) via ConfigMaps or Helm `values.yaml` to simplify updates.
- Use readiness and liveness probes on deployments to ensure stable ingress routing.
- Enforce resource limits/requests within the `webapps` namespace to prevent any single app from exhausting cluster capacity.

## Part 3 - K3d and Argo CD (GitOps Pipeline)

### 1. Host Tooling Script
- Author `p3/scripts/setup_host_macos.sh` to install Docker Desktop (or Colima + k3d-compatible Docker daemon), K3d, kubectl, Argo CD CLI, Helm via Homebrew.
- Script should check for Rosetta, set Docker Desktop to use `colima`/`docker` CLI context, and start the Docker service if stopped.

### 2. Repository Layout
- `p3/` contains `scripts/`, `confs/`, and documentation; no Vagrantfile needed if using native macOS Docker.
- Provide `p3/scripts/create_cluster.sh` that creates a K3d cluster with one server, two agents (if needed), ingress port mappings, and nodes named `wstygg-...` for consistency.

### 3. Cluster Bootstrapping
- Script cluster creation with `k3d cluster create wstygg --agents 1 --api-port 6550 -p "8080:80@loadbalancer" -p "8888:8888@loadbalancer"` and store kubeconfig under `p3/confs/kubeconfig`.
- Apply namespace manifests (`argocd`, `dev`) from `p3/confs/namespaces.yaml`.
- Install Argo CD via Helm or official manifests; keep values file in `p3/confs/argocd/values.yaml` with admin password secret handling instructions.

### 4. GitOps Application Setup
- Create or fork a public GitHub repository named `wstygg-iot-app` (or similar) containing Kubernetes manifests.
- Define Argo CD Application manifest pointing to the repo, target revision `main`, and namespace `dev`.
- Include deployment manifest referencing Docker image tags `v1` and `v2` (either Wil's `wil42/playground` or custom image hosted on Docker Hub).

### 5. Automation & Testing
- Provide script `p3/scripts/deploy_argocd.sh` to apply Argo CD manifests and port-forward the UI (macOS-compatible using `kubectl port-forward --address 0.0.0.0` when needed).
- Document retrieval of the initial Argo CD admin password with `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d`, and include instructions to rotate it immediately via `argocd account update-password`.
- Document workflow to switch application version: edit Git repo, commit/push, watch Argo CD sync, verify with `curl http://localhost:8888/`.
- Implement smoke tests verifying namespace health and Argo CD Application status using `argocd app get`.

### 6. Best Practices
- Store sensitive data via Kubernetes Secrets managed through Sealed Secrets or SOPS; never commit plain-text passwords.
- Configure Argo CD RBAC for read-only evaluator access; document admin password rotation procedure.
- Add Makefile targets (`make cluster`, `make clean`) to simplify host commands and ensure idempotence.

## Bonus - GitLab Integration

### 1. Prerequisites
- Ensure host Docker runtime has sufficient resources (>= 8 GB RAM) for GitLab; document expectation in README.
- Install Helm (already available) and add GitLab chart repo (`helm repo add gitlab https://charts.gitlab.io`).

### 2. Namespace & Storage
- Create `gitlab` namespace and configure persistent storage class (use local-path provisioner or K3d external volume); document volume directory on macOS (`~/Library/Containers/com.docker.docker/Data/vms/...`).
- For durability, mount host directories via K3d volume flags (`--volume $HOME/gitlab-data:/var/lib/rancher/k3s/storage`).

### 3. Deployment Steps
- Recreate (or update) the K3d cluster to expose the GitOps application on host port 9999 in addition to the existing mappings, for example: `k3d cluster create wstygg --agents 1 --api-port 6550 -p "8080:80@loadbalancer" -p "8888:8888@loadbalancer" -p "9999:80@loadbalancer"` (delete the old cluster first if needed).
- Craft Helm values file `bonus/confs/gitlab/values.yaml` tuned for resource limits, disabling unnecessary components (registry, monitoring) if not required.
- Install GitLab with `helm upgrade --install gitlab gitlab/gitlab -f values.yaml -n gitlab`; monitor pods until Ready.
- Configure Ingress to expose GitLab via host-only mapping (e.g., `gitlab.local`); update macOS `/etc/hosts` accordingly.

### 4. GitOps Integration
- Mirror the existing GitHub repo into GitLab or host manifests directly in GitLab; update Argo CD Application source to point to GitLab repository using HTTPS with PAT stored in Secret.
  - Create a Kubernetes secret (e.g., `argocd-repo-secret`) containing the Personal Access Token: `kubectl -n argocd create secret generic argocd-repo-secret --from-literal=username=<gitlab-username> --from-literal=password=<gitlab-pat>` and reference it in the Argo CD `Application` `spec.source.repoURL` credentials per the [Argo CD repository access docs](https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/).
- Set up GitLab CI (optional) to build and push Docker images tagged `v1`/`v2`; document pipeline triggers.

### 5. Validation
- Log into GitLab web UI, confirm project availability, and demonstrate Argo CD syncing from GitLab.
- Run end-to-end test: modify manifest in GitLab, trigger Argo CD refresh, verify application update at `http://localhost:9999/`.

### 6. Best Practices
- Enable GitLab backups (scheduled job writing to host-mounted volume) and document restore steps.
- Monitor resource usage with `kubectl top` (install metrics server if needed) to ensure cluster stability.
- Use HTTPS for GitLab ingress (self-signed cert acceptable) and document trust-store configuration on macOS.

## Cross-Cutting Practices
- Maintain shared utility scripts under `.agents/scripts/` (if needed) and reference them from p1/p2/p3 to avoid drift.
- Enforce shell linting (e.g., `shellcheck`) and YAML validation (`yamllint`) via pre-commit hooks compatible with macOS Python.
- Document teardown commands (`vagrant destroy`, `k3d cluster delete wstygg`) to ensure clean state between defenses.
- Keep changelog in `.agents/CHANGELOG.md` capturing major updates to infrastructure and documentation.
