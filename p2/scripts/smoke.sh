#!/usr/bin/env bash

echo "========================================="
echo "    Part 2: Ingress Routing Test"
echo "========================================="
echo ""

echo "=== Cluster Status ==="
kubectl get nodes
echo ""

echo "=== Deployments in webapps namespace ==="
kubectl get deployments -n webapps
echo ""

echo "=== Pods in webapps namespace ==="
kubectl get pods -n webapps
echo ""

echo "=== Services in webapps namespace ==="
kubectl get services -n webapps
echo ""

echo "=== Ingress in webapps namespace ==="
kubectl get ingress -n webapps
echo ""

echo "=== Testing Ingress Routing ==="
echo ""

echo "[Test 1] app1.com → should return App1"
curl -H "Host: app1.com" http://192.168.56.110 2>/dev/null | grep -o "<h1>.*</h1>"
echo ""

echo "[Test 2] app2.com → should return App2"
curl -H "Host: app2.com" http://192.168.56.110 2>/dev/null | grep -o "<h1>.*</h1>"
echo ""

echo "[Test 3] any other host → should return App3 (default)"
curl -H "Host: example.com" http://192.168.56.110 2>/dev/null | grep -o "<h1>.*</h1>"
echo ""

echo "[Test 4] no host header → should return App3 (default)"
curl http://192.168.56.110 2>/dev/null | grep -o "<h1>.*</h1>"
echo ""

echo "========================================="
echo "    Smoke tests completed!"
echo "========================================="
