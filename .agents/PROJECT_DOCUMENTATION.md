# Inception-of-Things Project Overview

This internal guide elaborates on the official subject (`.agents/en.subject.txt`) for planning purposes; always treat the subject as the definitive list of mandatory requirements.

## Project Purpose
- Establish foundational Kubernetes skills by orchestrating lightweight K3s and K3d clusters inside controlled virtual machines.
- Practice infrastructure-as-code workflows with Vagrant, scripted provisioning, and declarative manifests.
- Build confidence with GitOps by managing application deployments through Argo CD and public Git repositories.

## Scope and Deliverables

### Part 1 - K3s and Vagrant
- Provision two Vagrant-managed VMs using the latest stable guest OS with minimal resources (1 CPU, 512-1024 MB RAM).
- Use `wstygg` as the Vagrant machine name for both entries; set guest hostnames to `wstyggS` for the controller and `wstyggSW` for the worker.
- Assign static IPs (`192.168.56.110` for Server, `192.168.56.111` for ServerWorker) on the primary interface and enable passwordless SSH access.
- Install K3s in controller mode on the Server node and agent mode on the ServerWorker node; ensure nodes join into a functioning cluster and kubectl is available.
- Supply modern, maintainable Vagrantfile configuration plus any required automation scripts.
- Success criterion: cluster nodes are reachable, ready, and manageable via kubectl from the Server; SSH access works without passwords.

### Part 2 - K3s with Three Applications
- Reuse a single VM (hostname `wstyggS`) running K3s in server mode; host three distinct web applications.
- Configure ingress routing so requests to `192.168.56.110` dispatch traffic by `Host` header: `app1.com` -> App 1, `app2.com` -> App 2 (exactly three replicas), any other host -> default App 3.
- Provide curl/browser test cases that include explicit `Host` headers (`curl -H 'Host: app1.com' http://192.168.56.110`) and document expected responses.
- Document or script Ingress, Service, and Deployment objects required to reproduce the environment, and plan to show the Ingress manifest during the defense.
- Success criterion: functional host-based routing validated via browser or curl, visible replica scaling for App 2, and demonstrable manifests or automation.

### Part 3 - K3d and Argo CD
- Install K3d (requiring Docker and supporting packages) on a VM; provide an installation script to bootstrap dependencies during defense.
- Create a K3d-backed cluster with namespaces `argocd` and `dev`.
- Deploy Argo CD into the `argocd` namespace and configure a GitOps pipeline targeting an application in `dev` sourced from a public GitHub repo whose name contains a team member's login.
- Use Wil's Docker image (`wil42/playground`) with publicly available Docker images tagged `v1` and `v2`; expose it on port 8888.
- Demonstrate automated version promotion by editing the Git repository, observing Argo CD sync, and validating the running version via curl.
- Success criterion: Argo CD reports sync status, namespace resources are healthy, and version flips from `v1` to `v2` (or equivalent) on Git pushes.

### Bonus - GitLab Integration (Optional)
- Deploy GitLab inside the cluster (e.g., via Helm) within a dedicated `gitlab` namespace, using the latest official release.
- Integrate GitLab with the existing GitOps flow so Part 3 functionality works entirely with the local GitLab instance.
- Success criterion: GitLab instance is reachable, namespaces isolate workloads, and Argo CD (or equivalent) operates using GitLab as the source of truth.

## Constraints and Assumptions
- All work must execute inside virtual machines; host provisioning tooling is flexible but Vagrant usage is mandatory for Parts 1 and 2.
- Repository must contain `p1`, `p2`, and `p3` directories (plus `bonus` if attempted) at the root, each holding `Vagrantfile`, `scripts`, and `confs` as needed.
- Provide only the minimum required VM resources to stay lightweight; scaling up should be justified.
- Keep automation idempotent and defense-ready so evaluators can recreate environments quickly.
- Ensure every required toolchain and script runs flawlessly on macOS, including virtualization (Vagrant provider), Docker/K3d, kubectl, and any shell automation.
- Evaluation happens on the team's machine; ensure offline readiness and avoid hard-coded host-specific paths beyond the mandated IPs.

## Success Metrics
- **Operational clusters:** K3s (Parts 1 & 2) and K3d (Part 3) clusters deploy without manual fixes; nodes show Ready status.
- **Network reachability:** Static IPs respond to SSH and HTTP/Ingress traffic according to specification.
- **GitOps workflow:** Argo CD synchronizes application state with Git commits and surfaces version changes on demand.
- **Documentation & reproducibility:** Clear manifests, scripts, and instructions allow evaluators to rebuild environments end-to-end.
- **Bonus readiness (optional):** GitLab-enhanced flow mirrors Part 3 behavior without regressions.

## Tooling Checklist
- Vagrant with a chosen provider (e.g., VirtualBox, VMware, libvirt).
- Guest OS package manager (apt, yum, etc.) and scripting language support (shell, potentially Ansible or others).
- K3s, kubectl, Docker, K3d, Argo CD CLI (optional but helpful), Git, curl, Helm (if tackling the bonus).
- DNS or `/etc/hosts` overrides for testing host-based routing (`app1.com`, `app2.com`, etc.).

## Demonstration Flow for Defense
1. Boot required VMs via Vagrant or K3d scripts.
2. Prove SSH access and kubectl readiness (Part 1).
3. Show host-based routing and scaling behavior for the three applications (Part 2), including Ingress manifest walkthrough and curl tests with custom Host headers.
4. Walk through Argo CD dashboard, trigger a Git-based version change, and verify rollout via curl (Part 3).
5. (Bonus) Present GitLab deployment and end-to-end integration if implemented.

## Open Questions / To Clarify
- Final selection of guest OS images and providers for each part.
- Choice of three applications for Part 2 and whether shared tooling (e.g., Helm charts) will be adopted.
- Decision between Wil's sample application or a custom build for Part 3, and associated Docker repository strategy.

Document owners should revisit this file whenever design choices evolve to keep the shared vision aligned with the project goals.
