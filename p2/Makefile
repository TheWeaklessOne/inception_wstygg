.PHONY: all clean re check smoke

all:
	vagrant up

clean:
	vagrant destroy -f
	rm -f shared/kubeconfig.yaml
	rm -rf .vagrant .vagrant.d

re: clean all

check:
	@echo "[1/5] Checking VM status..."
	@vagrant status | grep wstyggS | grep running || (echo "❌ VM not running. Run 'make' first." && exit 1)
	@echo "✅ VM is running"
	@echo ""
	@echo "[2/5] Checking K3s cluster..."
	@vagrant ssh wstyggS -c "sudo kubectl get nodes" || (echo "❌ Cluster check failed" && exit 1)
	@echo "✅ Cluster is accessible"
	@echo ""
	@echo "[3/5] Checking deployments..."
	@vagrant ssh wstyggS -c "sudo kubectl get deployments -n webapps"
	@echo ""
	@echo "[4/5] Verifying app2 has 3 replicas..."
	@vagrant ssh wstyggS -c "sudo kubectl get deployment app2 -n webapps -o jsonpath='{.spec.replicas}'" | grep -q "3" && echo "✅ App2 has 3 replicas" || echo "❌ App2 replica count incorrect"
	@echo ""
	@echo "[5/5] Verifying kubeconfig export..."
	@[ -f shared/kubeconfig.yaml ] && echo "✅ kubeconfig.yaml exported" || echo "❌ kubeconfig.yaml not found"
	@echo ""
	@echo "💡 To test Ingress routing, run: make smoke"

smoke:
	@echo "Running smoke tests inside VM..."
	@vagrant ssh wstyggS -c "bash /vagrant/scripts/smoke.sh"
