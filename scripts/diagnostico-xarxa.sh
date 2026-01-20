#!/bin/bash
# Diagnòstic de connectivitat de xarxa

echo "=== Verificant bridges i connectivitat ==="
echo ""

echo "1. IPs del relay VLAN10:"
docker exec clab-kea-lab-vlans-relay-vlan10 ip addr | grep "inet "

echo ""
echo "2. IPs del relay VLAN20:"
docker exec clab-kea-lab-vlans-relay-vlan20 ip addr | grep "inet "

echo ""
echo "3. IPs del servidor Kea:"
docker exec clab-kea-lab-vlans-kea ip addr | grep "inet "

echo ""
echo "4. Test ping des del relay VLAN10 al seu gateway backend:"
docker exec clab-kea-lab-vlans-relay-vlan10 ping -c 2 10.25.115.100

echo ""
echo "5. Test ping des del relay VLAN20 al seu gateway backend:"
docker exec clab-kea-lab-vlans-relay-vlan20 ping -c 2 10.25.115.101

echo ""
echo "6. Test ping des del servidor Kea al relay VLAN10:"
docker exec clab-kea-lab-vlans-kea ping -c 2 10.25.115.100

echo ""
echo "7. Test ping des del servidor Kea al relay VLAN20:"
docker exec clab-kea-lab-vlans-kea ping -c 2 10.25.115.101

echo ""
echo "8. Verificar taula ARP del servidor Kea:"
docker exec clab-kea-lab-vlans-kea ip neigh

echo ""
echo "9. Verificar taula ARP del relay VLAN20:"
docker exec clab-kea-lab-vlans-relay-vlan20 ip neigh
