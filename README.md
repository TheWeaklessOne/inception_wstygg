# Inception-of-Things (IoT)

Kubernetes lab project executed entirely inside VirtualBox guests. Host machine is Ubuntu Linux (x86_64) without sudo/root; only Vagrant and VirtualBox are required.

## Repository Layout

```
.
|-- Makefile
|-- README.md
|-- scripts/
|   |-- check_env.sh
|   `-- bootstrap_tools.sh (optional helper for host, if desired)
|-- p1/ (Part 1 - K3s two-node cluster)
|-- p2/ (Part 2 - K3s single node with Ingress)
|-- p3/ (Part 3 - K3d + Argo CD inside dedicated VM)
`-- bonus/ (Optional GitLab integration)
```

## Usage Overview

1. **Verify environment**
   ```bash
   make check-env
   ```
   Confirms Vagrant/VirtualBox presence and basic virtualization support.

2. **Optional host helpers**
   Host interaction is not required, but you may install user-space tools (`kubectl`, `k3d`, `helm`) with:
   ```bash
   ./scripts/bootstrap_tools.sh
   ```
   These binaries are placed under `$HOME/.local/bin`; skip this step if you intend to run everything from inside the guests.

3. **Implement each part**
   - Part 1: `cd p1 && vagrant up`
   - Part 2: `cd p2 && vagrant up`
   - Part 3: follow `p3/README.md` to prepare the dedicated VM, install Docker/k3d, and configure Argo CD.

Read the README inside each part for exact provisioning, verification, and cleanup instructions. All downloads performed by scripts are stored within the repository tree (e.g., `p1/shared/`, `p3/bin/`).

## Constraints
- No sudo on host; do not write outside the repository directory.
- Host-only network `192.168.56.0/24` must already exist in VirtualBox (coordinate with admins if not).
- Do not modify `/etc/hosts`; use curl with explicit `Host` headers for tests.

## Documentation Links
- Subject: `.agents/en.subject.txt`
- Project overview: `.agents/PROJECT_DOCUMENTATION.md`
- Implementation plan: `.agents/IMPLEMENTATION_PLAN.md`

## Automation
- `make check-env` - inspect host environment
- Additional Make targets will be added as implementation progresses.
