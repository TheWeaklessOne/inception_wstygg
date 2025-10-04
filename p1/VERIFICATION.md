# Part 1 Verification Checklist

This document shows how to verify Part 1 is correctly configured, based on the subject examples.

## 1. Start the cluster

```bash
cd p1
make          # or: vagrant up
```

## 2. Check cluster status from inside server VM

### Connect to server and check nodes
```bash
vagrant ssh wstyggS

# Inside wstyggS VM:
kubectl get nodes -o wide
```

**Expected output:**
```
NAME       STATUS   ROLES                  AGE   VERSION        INTERNAL-IP      ...
wstyggS    Ready    control-plane,master   XXm   v1.XX.X+k3s1   192.168.56.110   ...
wstyggSW   Ready    <none>                 XXm   v1.XX.X+k3s1   192.168.56.111   ...
```

✅ **Check:**
- Both nodes show `Ready`
- wstyggS has `control-plane,master` role
- wstyggSW has `<none>` role (worker)
- IPs are `192.168.56.110` and `192.168.56.111`

## 3. Verify network configuration (from subject screenshot)

### Check network interface on worker
```bash
vagrant ssh wstyggSW

# Inside wstyggSW VM (Linux command):
ip a show eth1

# Or on macOS host (if checking from outside):
ifconfig eth1
```

**Expected output (similar to subject):**
```
eth1: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.56.111  netmask 255.255.255.0  broadcast 192.168.56.255
        ...
```

✅ **Check:**
- Interface `eth1` exists
- IP address matches: `192.168.56.111` for worker, `192.168.56.110` for server

## 4. Test SSH access (passwordless)

```bash
# From host - should work without password prompt
vagrant ssh wstyggS -c "hostname"
# Output: wstyggS

vagrant ssh wstyggSW -c "hostname"  
# Output: wstyggSW
```

✅ **Check:**
- No password prompt
- Correct hostnames returned

## 5. Verify kubectl access from host

```bash
# From host machine (not inside VM)
export KUBECONFIG=$(pwd)/shared/kubeconfig.yaml
kubectl get nodes -o wide
```

**Expected:** Same output as step 2

✅ **Check:**
- kubectl works from host
- Both nodes visible and Ready

## 6. Check K3s services

```bash
# Server
vagrant ssh wstyggS -c "sudo systemctl status k3s | grep Active"
# Expected: Active: active (running)

# Worker  
vagrant ssh wstyggSW -c "sudo systemctl status k3s-agent | grep Active"
# Expected: Active: active (running)
```

## 7. Verify shared artifacts

```bash
# From host
ls -lh shared/
# Expected:
# -rw------- kubeconfig.yaml (600 permissions)
# -rw------- k3s_token (600 permissions)

grep "192.168.56.110:6443" shared/kubeconfig.yaml
# Expected: server: https://192.168.56.110:6443
```

## 8. Check pods in kube-system

```bash
vagrant ssh wstyggS -c "sudo kubectl get pods -A"
```

**Expected:** All pods in `Running` or `Completed` state

## Subject Compliance Summary

Based on the subject screenshot (page 8), here's what evaluators expect to see:

### ✅ Required checks:
1. **kubectl get nodes -o wide** - shows 2 Ready nodes with correct IPs
2. **Network verification** - `ip a show eth1` or `ifconfig eth1` shows correct IPs
3. **Passwordless SSH** - `vagrant ssh` works without password
4. **Correct naming** - wstyggS (server), wstyggSW (worker)
5. **K3s roles** - server has `control-plane,master`, worker has no role

### 📊 Quick one-liner verification:

```bash
# From p1 directory
vagrant ssh wstyggS -c "sudo kubectl get nodes -o wide && ip a show eth1 | grep 'inet 192'"
```

This should show both nodes Ready and the correct IP address.

## Cleanup

```bash
make clean
# or: vagrant destroy -f
```
