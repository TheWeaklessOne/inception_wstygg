# inception_wstygg - Argo CD GitOps Repository

This repository contains Kubernetes manifests for the Inception Part 3 project, monitored by Argo CD for automated deployments.

## 📋 Contents

- `deployment.yaml` - Kubernetes Deployment for wil42/playground app
- `service.yaml` - NodePort Service exposing the app on port 30080

## 🔄 Version Management

### Option 1: GitHub Actions (Web Interface) ⭐ RECOMMENDED

1. Go to **Actions** tab in GitHub
2. Select **Toggle Application Version** workflow
3. Click **Run workflow**
4. Click green **Run workflow** button

✨ The workflow will automatically:
   - Detect current version (v1 or v2)
   - Toggle to the opposite version
   - Commit and push changes!

### Option 2: Manual (Command Line)

To switch between versions manually:

### Switch to v2
```bash
sed -i 's/playground:v1/playground:v2/' deployment.yaml
git add deployment.yaml
git commit -m "Switch to v2"
git push
```

### Switch to v1
```bash
sed -i 's/playground:v2/playground:v1/' deployment.yaml
git add deployment.yaml
git commit -m "Switch to v1"
git push
```

Argo CD will automatically detect changes and deploy the new version within 3 minutes.

## 🎯 Argo CD Configuration

This repository is monitored by Argo CD Application configured in the main project under `p3/manifests/argo-application.yaml`.

### Application Details
- **Namespace**: `dev`
- **Port**: 8888 (container), 30080 (NodePort)
- **Auto-sync**: Enabled
- **Self-heal**: Enabled
- **Prune**: Enabled

## 📦 Available Versions

- **v1**: wil42/playground:v1
- **v2**: wil42/playground:v2

## 🚀 Usage

1. Argo CD monitors this repository
2. Make changes to `deployment.yaml`
3. Commit and push to GitHub
4. Argo CD automatically syncs the changes
5. Verify deployment: `kubectl get pods -n dev`

## 🔗 Related

Main project repository: [Inception-of-Things]

---

Part of the 42 School Inception-of-Things project
