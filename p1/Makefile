.PHONY: all clean re check doctor

all:
	vagrant up

clean:
	vagrant destroy -f
	rm -f shared/kubeconfig.yaml shared/k3s_token diagnosis.log
	rm -rf .vagrant .vagrant.d

re: clean all

check:
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
	@echo "[6/6] Verifying kubeconfig export..."
	@[ -f shared/kubeconfig.yaml ] && echo "✅ kubeconfig.yaml exported" || (echo "❌ kubeconfig.yaml not found" && exit 1)
	@grep -q "192.168.56.110:6443" shared/kubeconfig.yaml && echo "✅ kubeconfig server URL correct" || echo "❌ kubeconfig server URL incorrect"
	@echo ""
	@echo "💡 To use kubectl from host, install kubectl and run:"
	@echo "   export KUBECONFIG=$$(pwd)/shared/kubeconfig.yaml"
	@echo "   kubectl get nodes"
	@echo ""

doctor:
	@echo "=== 🩺 Inception Part1 Diagnostics ==="
	@echo "Collecting diagnostic information..."
	@echo "" > diagnosis.log
	@echo "=== Vagrant VM Status ===" | tee -a diagnosis.log
	@vagrant status | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== Server (wstyggS) Network Interfaces ===" | tee -a diagnosis.log
	@timeout 10 vagrant ssh wstyggS -- ip a 2>&1 | tee -a diagnosis.log || echo "⚠️  Timeout or connection failed" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== Worker (wstyggSW) Network Interfaces ===" | tee -a diagnosis.log
	@timeout 10 vagrant ssh wstyggSW -- ip a 2>&1 | tee -a diagnosis.log || echo "⚠️  Timeout or connection failed" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== Server K3s Service Status ===" | tee -a diagnosis.log
	@timeout 10 vagrant ssh wstyggS -- sudo systemctl status k3s --no-pager -l 2>&1 | tee -a diagnosis.log || echo "⚠️  Service check failed" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== Worker K3s-Agent Service Status ===" | tee -a diagnosis.log
	@timeout 10 vagrant ssh wstyggSW -- sudo systemctl status k3s-agent --no-pager -l 2>&1 | tee -a diagnosis.log || echo "⚠️  Service check failed" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== Server K3s Service Logs (last 100 lines) ===" | tee -a diagnosis.log
	@timeout 10 vagrant ssh wstyggS -- sudo journalctl -u k3s --no-pager -n 100 2>&1 | tee -a diagnosis.log || echo "⚠️  Log retrieval failed" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== Worker K3s-Agent Logs (last 100 lines) ===" | tee -a diagnosis.log
	@timeout 10 vagrant ssh wstyggSW -- sudo journalctl -u k3s-agent --no-pager -n 100 2>&1 | tee -a diagnosis.log || echo "⚠️  Log retrieval failed" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== Network Connectivity: Ping Server from Worker ===" | tee -a diagnosis.log
	@timeout 10 vagrant ssh wstyggSW -- ping -c 3 192.168.56.110 2>&1 | tee -a diagnosis.log || echo "⚠️  Ping failed" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== K3s API Connectivity from Worker ===" | tee -a diagnosis.log
	@timeout 10 vagrant ssh wstyggSW -- curl -k https://192.168.56.110:6443/ping 2>&1 | tee -a diagnosis.log || echo "⚠️  API unreachable" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== Shared Folder Contents ===" | tee -a diagnosis.log
	@ls -lh shared/ 2>&1 | tee -a diagnosis.log || echo "⚠️  Shared folder not accessible" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== Token File (first 20 chars) ===" | tee -a diagnosis.log
	@head -c 20 shared/k3s_token 2>&1 | tee -a diagnosis.log || echo "⚠️  Token file not found" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== Cluster Nodes ===" | tee -a diagnosis.log
	@timeout 10 vagrant ssh wstyggS -- sudo kubectl get nodes -o wide 2>&1 | tee -a diagnosis.log || echo "⚠️  kubectl get nodes failed" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== Cluster Pods (all namespaces) ===" | tee -a diagnosis.log
	@timeout 10 vagrant ssh wstyggS -- sudo kubectl get pods -A 2>&1 | tee -a diagnosis.log || echo "⚠️  kubectl get pods failed" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "=== 📋 Diagnostic Summary ===" | tee -a diagnosis.log
	@echo "Server K3s Service:" | tee -a diagnosis.log
	@timeout 5 vagrant ssh wstyggS -- sudo systemctl is-active k3s 2>&1 | grep -q active && echo "  ✅ Active" | tee -a diagnosis.log || echo "  ❌ Inactive/Failed" | tee -a diagnosis.log
	@echo "Worker K3s-Agent Service:" | tee -a diagnosis.log
	@timeout 5 vagrant ssh wstyggSW -- sudo systemctl is-active k3s-agent 2>&1 | grep -q active && echo "  ✅ Active" | tee -a diagnosis.log || echo "  ❌ Inactive/Failed" | tee -a diagnosis.log
	@echo "Cluster Status:" | tee -a diagnosis.log
	@timeout 5 vagrant ssh wstyggS -- "sudo kubectl get nodes 2>/dev/null | grep -c Ready" 2>&1 | grep -q "2" && echo "  ✅ Both nodes Ready" | tee -a diagnosis.log || echo "  ⚠️  Nodes not Ready" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
	@echo "📄 Full diagnostic log saved to: diagnosis.log" | tee -a diagnosis.log
	@echo "" | tee -a diagnosis.log
