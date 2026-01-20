#!/bin/bash
# Script per arreglar les rutes i connectivitat

echo "=== Afegint rutes al servidor Kea ==="
docker exec clab-kea-lab-vlans-kea ip route add 10.25.115.0/26 via 10.25.115.100 || echo "Ruta VLAN10 ja existeix"
docker exec clab-kea-lab-vlans-kea ip route add 10.25.115.64/26 via 10.25.115.101 || echo "Ruta VLAN20 ja existeix"
docker exec clab-kea-lab-vlans-kea ip route add 10.25.115.128/26 via 10.25.115.102 || echo "Ruta VLAN30 ja existeix"

echo ""
echo "=== Verificant rutes ==="
docker exec clab-kea-lab-vlans-kea ip route

echo ""
echo "=== Test de connectivitat relay VLAN20 -> Kea ==="
docker exec clab-kea-lab-vlans-relay-vlan20 ping -c 3 10.25.115.200

echo ""
echo "=== Test de connectivitat relay VLAN10 -> Kea ==="
docker exec clab-kea-lab-vlans-relay-vlan10 ping -c 3 10.25.115.200

echo ""
echo "=== Provant DHCP a VLAN 20 ==="
docker exec clab-kea-lab-vlans-client-vlan20 udhcpc -i eth1 -n

echo ""
echo "=== Verificant IP assignada ==="
docker exec clab-kea-lab-vlans-client-vlan20 ip addr show eth1 | grep "inet "

echo ""
echo "✅ Fet!"
