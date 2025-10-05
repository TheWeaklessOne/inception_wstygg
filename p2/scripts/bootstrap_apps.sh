#!/usr/bin/env bash
set -euo pipefail

echo "[INFO] Waiting for K3s node to be Ready..."

# Wait for node to be Ready
for i in $(seq 1 60); do
  if kubectl get nodes | grep -q " Ready"; then
    echo "[OK] Node is Ready"
    break
  fi
  echo -n "."
  sleep 2
done

if ! kubectl get nodes | grep -q " Ready"; then
  echo "[ERROR] Node did not become Ready"
  kubectl get nodes
  exit 1
fi

echo "[INFO] Applying application manifests..."

# Apply manifests (idempotent)
kubectl apply -f /vagrant/manifests/apps.yaml

echo "[INFO] Waiting for deployments to be ready..."

# Wait for deployments to roll out with proper error handling
DEPLOY_FAILED=false
if ! kubectl rollout status deployment/app1 -n webapps --timeout=180s; then
  echo "[WARNING] app1 deployment failed or timed out"
  DEPLOY_FAILED=true
fi

if ! kubectl rollout status deployment/app2 -n webapps --timeout=180s; then
  echo "[WARNING] app2 deployment failed or timed out"
  DEPLOY_FAILED=true
fi

if ! kubectl rollout status deployment/app3 -n webapps --timeout=180s; then
  echo "[WARNING] app3 deployment failed or timed out"
  DEPLOY_FAILED=true
fi

echo "[INFO] Checking deployment status..."
kubectl get deployments -n webapps
kubectl get pods -n webapps
kubectl get services -n webapps
kubectl get ingress -n webapps

if [ "$DEPLOY_FAILED" = "true" ]; then
  echo "[ERROR] Some deployments failed. Check logs above."
  exit 1
fi

# Verify app2 has exactly 3 replicas
APP2_REPLICAS=$(kubectl get deployment app2 -n webapps -o jsonpath='{.status.readyReplicas}')
if [ "$APP2_REPLICAS" != "3" ]; then
  echo "[WARNING] app2 does not have 3 ready replicas (found: $APP2_REPLICAS)"
else
  echo "[OK] app2 has 3 ready replicas"
fi

echo "[SUCCESS] Applications deployed successfully"
exit 0
