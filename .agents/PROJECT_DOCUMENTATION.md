# Inception-of-Things Project Overview

This document summarizes the subject requirements and our execution strategy. Always refer to `.agents/en.subject.txt` during evaluation.

## Development Environment (Local Author Machine)
- Apple Silicon macOS (ARM64) used for writing and static validation.
- VirtualBox/Vagrant are unavailable natively; provisioning scripts are crafted but not executed here.
- All runtime validation and defense will happen on the evaluator host described below.

## Host Environment (Evaluator Machine)
- Ubuntu Linux (x86_64), limited disk quota, no sudo/root escalation.
- Oracle VirtualBox 7.x and Vagrant 2.4.x are pre-installed and usable by the current user.
- Docker may be available but is **not** required for the host; all Docker/k3d work happens inside guest virtual machines.
- All project files and downloads must remain under the project directory (no writes to `/tmp` or system locations).

## Guest Responsibilities
Each part provisions its own virtual machines where root access is available during provisioning scripts. Any tooling required by the subject (K3s, kubectl, Docker/k3d, Helm, GitLab) is installed **inside** those guests.

## Project Purpose
- Build lightweight Kubernetes clusters (K3s in Parts 1 & 2, K3d in Part 3) within isolated virtual machines.
- Practice infrastructure-as-code using Vagrant and shell provisioning.
- Demonstrate GitOps workflows with Argo CD and optional GitLab integration.

## Scope and Deliverables

### Part 1 - K3s with Vagrant (Two Nodes)
- Bring up two VirtualBox VMs via Vagrant with 1 vCPU/1 GB RAM each.
- Assign static IPs `192.168.56.110` (`wstyggS`) and `192.168.56.111` (`wstyggSW`).
- Passwordless SSH works out of the box via Vagrant's default key; optionally trust additional keys from `p1/confs/authorized_keys`.
- Install K3s server on `wstyggS`, agent on `wstyggSW`; ensure the worker auto-joins using the shared token.
- Export kubeconfig and node token into `p1/shared/` for host-side use.
- Success = `kubectl --kubeconfig=p1/shared/kubeconfig.yaml get nodes` on the host shows both nodes Ready.

### Part 2 - K3s Single VM with Ingress
- Provision a single VirtualBox VM running K3s server mode.
- Deploy three HTTP applications with distinct Services.
- Configure Ingress routes:
  - `Host: app1.com` -> App 1
  - `Host: app2.com` -> App 2 (exactly 3 replicas)
  - Any other host -> App 3
- Provide curl commands using explicit `Host` headers (no `/etc/hosts` edits).
- Success = curl responses match expectations and replica count equals 3 for App 2.

### Part 3 - K3d and Argo CD (No Vagrant)
- Create a dedicated VirtualBox VM (provisioned via scripts) where Docker and K3d are installed.
- Install Argo CD in namespace `argocd`; deploy an application in `dev` namespace sourced from a public GitHub repo containing the team login.
- Application image: `wil42/playground` tags `v1` and `v2`.
- Demonstrate GitOps: update manifest in GitHub, Argo CD syncs automatically, and the exposed service (port 8888) reflects the new version.
- Success = Argo CD reports Sync/Healthy and HTTP endpoint returns updated payload after Git change.

### Bonus - GitLab Integration (Optional)
- Install GitLab (via Helm) inside the same VM or k3d cluster within a dedicated `gitlab` namespace.
- Redirect Argo CD to consume manifests from the local GitLab instance using PAT stored in a Kubernetes Secret.
- Success = GitLab reachable, Argo CD syncs from GitLab repository, end-to-end GitOps pipeline remains functional.

## Constraints & Assumptions
- Host remains untouched except for operations within the project directory and Vagrant/VirtualBox usage.
- Provisioning scripts run as root inside guests; leverage that for package installs.
- No `/etc/hosts` modifications on host; rely on `curl -H 'Host: ...'` for testing.
- Internet access may be restricted; cache critical binaries in the repository if needed.
- GitHub repository used by Argo CD must be public and include the login in its name.

## Success Metrics
- **Cluster readiness:** K3s/K3d clusters reach Ready state without manual intervention.
- **Automation reproducibility:** `vagrant up/down` (Parts 1 & 2) and scripted Docker/K3d operations (Part 3) succeed using only repository automation.
- **GitOps workflow:** Version switch from `v1` to `v2` verified via HTTP responses and Argo CD status.
- **Documentation clarity:** Engineers can follow README + plan without external guidance.
- **Bonus (optional):** GitLab-backed Argo CD flow mirrors the GitHub setup.

## Tooling Checklist (Host)
- Vagrant 2.4.x
- VirtualBox 7.x
- Shell utilities (bash, curl, jq, ssh)
- Optional: local `kubectl`/`helm`/`k3d` binaries for convenience, but not required.

## Demonstration Flow
1. Run `make check-env` to confirm host readiness.
2. Part 1: `cd p1 && vagrant up`; inside `wstyggS`, run `sudo kubectl get nodes`.
3. Part 2: bring up VM, apply manifests, run curl host-header tests.
4. Part 3: execute Docker/K3d scripts inside dedicated VM; perform GitOps version flip.
5. Bonus (if implemented): demo GitLab-driven sync.

## Open Items
- Ensure package downloads inside guests use project subdirectories (e.g., `/vagrant/shared` or `/home/vagrant/projects/...`).
- Confirm VirtualBox host-only network IDs and adjust if conflicts arise.
- Decide on container images for Part 2.
- Prepare GitHub repository for Part 3 manifests before defense.
- Evaluate resource needs before attempting GitLab bonus (8 GB+ RAM recommended).

Document owners must update this file whenever environment assumptions or tool choices change.
