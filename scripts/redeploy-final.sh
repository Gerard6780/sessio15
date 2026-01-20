#!/bin/bash
# Redesplegar amb configuració /24 corregida

echo "=========================================="
echo "  REDESPLEGAR LAB AMB BACKEND /24"
echo "=========================================="
echo ""

cd ~/Documents/git/sessio15

echo "=== 1. Destruint lab actual ==="
sudo containerlab destroy --name kea-lab-vlans

echo ""
echo "=== 2. Desplegant lab amb backend /24 ==="
sudo containerlab deploy -t fase2-vlans/topology.clab.yml

echo ""
echo "=== 3. Esperant 25 segons perquè els serveis s'iniciïn ==="
sleep 25

echo ""
echo "=== 4. Verificant IPs (haurien de ser /24) ==="
echo "Servidor Kea:"
docker exec clab-kea-lab-vlans-kea ip addr show eth1 | grep "inet "
echo ""
echo "Relay VLAN20:"
docker exec clab-kea-lab-vlans-relay-vlan20 ip addr show eth1 | grep "inet "

echo ""
echo "=== 5. Test de connectivitat relay -> Kea ==="
docker exec clab-kea-lab-vlans-relay-vlan20 ping -c 3 10.25.115.200

echo ""
echo "=== 6. Provant DHCP a VLAN 20 ==="
docker exec clab-kea-lab-vlans-client-vlan20 udhcpc -i eth1 -n

echo ""
echo "=== 7. Verificant IP assignada ==="
docker exec clab-kea-lab-vlans-client-vlan20 ip addr show eth1 | grep "inet "

echo ""
echo "=== 8. Provant les altres VLANs ==="
echo "VLAN 10:"
docker exec clab-kea-lab-vlans-client-vlan10 udhcpc -i eth1 -n
echo ""
echo "VLAN 30:"
docker exec clab-kea-lab-vlans-client-vlan30 udhcpc -i eth1 -n

echo ""
echo "=========================================="
echo "  ✅ COMPLETAT!"
echo "=========================================="
