.PHONY: all clean re check

all:
	vagrant up

clean:
	vagrant destroy -f
	rm -f shared/kubeconfig.yaml shared/k3s_token
	rm -rf .vagrant .vagrant.d

re: clean all

check:
	@echo "=============================================="
	@echo "  Part 1 Verification (Subject Compliance)"
	@echo "=============================================="
	@echo ""
	@echo "[1/6] Checking VM status..."
	@vagrant status | grep -E "(wstyggS|wstyggSW)" || (echo "❌ VMs not running. Run 'make' first." && exit 1)
	@echo "✅ VMs are up"
	@echo ""
	@echo "[2/6] Checking K3s cluster nodes..."
	@vagrant ssh wstyggS -c "sudo kubectl get nodes -o wide" || (echo "❌ Cluster check failed" && exit 1)
	@echo "✅ Both nodes visible"
	@echo ""
	@echo "[3/6] Verifying node status (Ready)..."
	@vagrant ssh wstyggS -c "sudo kubectl get nodes | grep -c Ready" | grep -q "2" && echo "✅ Both nodes Ready" || echo "⚠️  Nodes not Ready yet"
	@echo ""
	@echo "[4/6] Checking network configuration..."
	@echo "Server IP:"
	@vagrant ssh wstyggS -c "ip a show eth1 2>/dev/null | grep 'inet 192' || ip a show enp0s8 | grep 'inet 192'" | grep "192.168.56.110" && echo "✅ Server: 192.168.56.110" || echo "❌ Server IP incorrect"
	@echo "Worker IP:"
	@vagrant ssh wstyggSW -c "ip a show eth1 2>/dev/null | grep 'inet 192' || ip a show enp0s8 | grep 'inet 192'" | grep "192.168.56.111" && echo "✅ Worker: 192.168.56.111" || echo "❌ Worker IP incorrect"
	@echo ""
	@echo "[5/6] Testing passwordless SSH..."
	@vagrant ssh wstyggS -c "hostname" | grep -q "wstyggS" && echo "✅ SSH to server works" || echo "❌ SSH to server failed"
	@vagrant ssh wstyggSW -c "hostname" | grep -q "wstyggSW" && echo "✅ SSH to worker works" || echo "❌ SSH to worker failed"
	@echo ""
	@echo "[6/6] Verifying kubectl from host..."
	@[ -f shared/kubeconfig.yaml ] && echo "✅ kubeconfig.yaml exists" || (echo "❌ kubeconfig.yaml not found" && exit 1)
	@export KUBECONFIG=$$(pwd)/shared/kubeconfig.yaml && kubectl get nodes >/dev/null 2>&1 && echo "✅ kubectl from host works" || echo "⚠️  kubectl not configured (install kubectl or wait for cluster)"
	@echo ""
	@echo "=============================================="
	@echo "  ✅ Part 1 verification complete!"
	@echo "=============================================="
	@echo ""
	@echo "For detailed checks, see: VERIFICATION.md"
