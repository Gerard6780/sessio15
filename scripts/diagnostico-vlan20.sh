#!/bin/bash
# Script de diagnòstic per DHCP VLAN 20
# Executa aquest script i passa'm la sortida completa

echo "=========================================="
echo "  DIAGNÒSTIC DHCP VLAN 20"
echo "=========================================="
echo ""

echo "=== 1. Verificar configuració Kea ==="
echo "--- Configuració carregada al servidor ---"
docker exec clab-kea-lab-vlans-kea cat /etc/kea/kea-dhcp4.conf
echo ""

echo "=== 2. Verificar IPs del servidor Kea ==="
docker exec clab-kea-lab-vlans-kea ip addr show eth1
echo ""

echo "=== 3. Verificar rutes del servidor Kea ==="
docker exec clab-kea-lab-vlans-kea ip route
echo ""

echo "=== 4. Verificar IPs del relay VLAN 20 ==="
docker exec clab-kea-lab-vlans-relay-vlan20 ip addr
echo ""

echo "=== 5. Verificar procés relay VLAN 20 ==="
docker exec clab-kea-lab-vlans-relay-vlan20 ps aux
echo ""

echo "=== 6. Verificar logs del servidor Kea ==="
docker logs clab-kea-lab-vlans-kea --tail 100
echo ""

echo "=== 7. Verificar logs del relay VLAN 20 ==="
docker logs clab-kea-lab-vlans-relay-vlan20 --tail 50
echo ""

echo "=== 8. Test de connectivitat relay -> Kea ==="
docker exec clab-kea-lab-vlans-relay-vlan20 ping -c 3 10.25.115.200
echo ""

echo "=== 9. Verificar si Kea està escoltant ==="
docker exec clab-kea-lab-vlans-kea ss -ulnp | grep 67
echo ""

echo "=== 10. Provar VLAN 10 (per comparar) ==="
docker exec clab-kea-lab-vlans-client-vlan10 dhclient -v eth1 2>&1 | head -20
echo ""

echo "=========================================="
echo "  FI DEL DIAGNÒSTIC"
echo "=========================================="
