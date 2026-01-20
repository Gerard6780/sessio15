#!/bin/bash
# Verificació ràpida de la configuració actual

echo "=== 1. IP del servidor Kea (hauria de ser /24) ==="
docker exec clab-kea-lab-vlans-kea ip addr show eth1 | grep "inet "

echo ""
echo "=== 2. IP del relay VLAN20 eth1 (hauria de ser /24) ==="
docker exec clab-kea-lab-vlans-relay-vlan20 ip addr show eth1 | grep "inet "

echo ""
echo "=== 3. Test ping relay -> Kea ==="
docker exec clab-kea-lab-vlans-relay-vlan20 ping -c 2 10.25.115.200

echo ""
echo "=== 4. Verificar procés relay ==="
docker exec clab-kea-lab-vlans-relay-vlan20 ps aux | grep dnsmasq
