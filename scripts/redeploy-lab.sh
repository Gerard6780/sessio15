#!/bin/bash
# Script per redesplegar el lab amb la configuració corregida

echo "=========================================="
echo "  REDESPLEGAR LAB AMB CONFIGURACIÓ FIXA"
echo "=========================================="
echo ""

echo "=== 1. Destruint lab actual ==="
sudo containerlab destroy --name kea-lab-vlans

echo ""
echo "=== 2. Desplegant lab amb configuració corregida ==="
sudo containerlab deploy -t fase2-vlans/topology.clab.yml

echo ""
echo "=== 3. Esperant que els serveis s'iniciïn (30 segons) ==="
sleep 30

echo ""
echo "=== 4. Verificant rutes del servidor Kea ==="
docker exec clab-kea-lab-vlans-kea ip route

echo ""
echo "=== 5. Test de connectivitat relay -> Kea ==="
echo "Relay VLAN10:"
docker exec clab-kea-lab-vlans-relay-vlan10 ping -c 2 10.25.115.200
echo ""
echo "Relay VLAN20:"
docker exec clab-kea-lab-vlans-relay-vlan20 ping -c 2 10.25.115.200
echo ""
echo "Relay VLAN30:"
docker exec clab-kea-lab-vlans-relay-vlan30 ping -c 2 10.25.115.200

echo ""
echo "=== 6. Provant DHCP a les 3 VLANs ==="
echo "VLAN 10:"
docker exec clab-kea-lab-vlans-client-vlan10 udhcpc -i eth1 -n
echo ""
echo "VLAN 20:"
docker exec clab-kea-lab-vlans-client-vlan20 udhcpc -i eth1 -n
echo ""
echo "VLAN 30:"
docker exec clab-kea-lab-vlans-client-vlan30 udhcpc -i eth1 -n

echo ""
echo "=== 7. Verificant IPs assignades ==="
echo "VLAN 10:"
docker exec clab-kea-lab-vlans-client-vlan10 ip addr show eth1 | grep "inet "
echo ""
echo "VLAN 20:"
docker exec clab-kea-lab-vlans-client-vlan20 ip addr show eth1 | grep "inet "
echo ""
echo "VLAN 30:"
docker exec clab-kea-lab-vlans-client-vlan30 ip addr show eth1 | grep "inet "

echo ""
echo "=========================================="
echo "  ✅ REDESPLEGAR COMPLETAT"
echo "=========================================="
