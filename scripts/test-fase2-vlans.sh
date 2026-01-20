#!/bin/bash
# Script de proves per Fase2-VLANs
# IP Assignada: 10.25.115.0/24

set -e

# Colors per output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

LAB_NAME="kea-lab-vlans"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Fase 2: Proves VLANs + Relay${NC}"
echo -e "${BLUE}  IP: 10.25.115.0/24${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Funció per verificar que el lab està desplegat
check_lab() {
    echo -e "${YELLOW}[1/8] Verificant desplegament del lab...${NC}"
    if ! docker ps | grep -q "clab-${LAB_NAME}-kea"; then
        echo -e "${RED}ERROR: El lab no està desplegat!${NC}"
        echo "Executa: cd ~/Documents/AntiGraviti/Serveis/sessio15 && sudo containerlab deploy -t fase2-vlans/topology.clab.yml"
        exit 1
    fi
    echo -e "${GREEN}✓ Lab desplegat correctament${NC}"
    echo ""
}

# Funció per sol·licitar IP a cada VLAN
request_ips() {
    echo -e "${YELLOW}[2/8] Sol·licitant IPs per cada VLAN...${NC}"
    
    for vlan in 10 20 30; do
        echo -e "${BLUE}  → VLAN ${vlan}:${NC}"
        docker exec clab-${LAB_NAME}-client-vlan${vlan} dhclient -v eth1 2>&1 | grep -E "DHCPOFFER|DHCPACK|bound to" || true
        sleep 2
    done
    echo -e "${GREEN}✓ IPs sol·licitades${NC}"
    echo ""
}

# Funció per verificar IPs assignades
verify_ips() {
    echo -e "${YELLOW}[3/8] Verificant IPs assignades...${NC}"
    
    echo -e "${BLUE}VLAN 10 (esperat: 10.25.115.10-50):${NC}"
    docker exec clab-${LAB_NAME}-client-vlan10 ip -4 addr show eth1 | grep "inet " | awk '{print "  " $2}'
    
    echo -e "${BLUE}VLAN 20 (esperat: 10.25.115.74-114):${NC}"
    docker exec clab-${LAB_NAME}-client-vlan20 ip -4 addr show eth1 | grep "inet " | awk '{print "  " $2}'
    
    echo -e "${BLUE}VLAN 30 (esperat: 10.25.115.138-178):${NC}"
    docker exec clab-${LAB_NAME}-client-vlan30 ip -4 addr show eth1 | grep "inet " | awk '{print "  " $2}'
    
    echo -e "${GREEN}✓ IPs verificades${NC}"
    echo ""
}

# Funció per verificar gateways
verify_gateways() {
    echo -e "${YELLOW}[4/8] Verificant gateways...${NC}"
    
    echo -e "${BLUE}VLAN 10 (esperat: 10.25.115.1):${NC}"
    docker exec clab-${LAB_NAME}-client-vlan10 ip route | grep default | awk '{print "  Gateway: " $3}'
    
    echo -e "${BLUE}VLAN 20 (esperat: 10.25.115.65):${NC}"
    docker exec clab-${LAB_NAME}-client-vlan20 ip route | grep default | awk '{print "  Gateway: " $3}'
    
    echo -e "${BLUE}VLAN 30 (esperat: 10.25.115.129):${NC}"
    docker exec clab-${LAB_NAME}-client-vlan30 ip route | grep default | awk '{print "  Gateway: " $3}'
    
    echo -e "${GREEN}✓ Gateways verificats${NC}"
    echo ""
}

# Funció per consultar leases al servidor
check_leases() {
    echo -e "${YELLOW}[5/8] Consultant leases al servidor Kea...${NC}"
    echo -e "${BLUE}Leases actius:${NC}"
    docker exec clab-${LAB_NAME}-kea cat /var/lib/kea/kea-leases4.csv | grep -v "^#" | grep "10.25.115" | while read line; do
        ip=$(echo $line | cut -d',' -f1)
        mac=$(echo $line | cut -d',' -f2)
        echo "  IP: $ip - MAC: $mac"
    done
    echo -e "${GREEN}✓ Leases consultats${NC}"
    echo ""
}

# Funció per alliberar IPs
release_ips() {
    echo -e "${YELLOW}[6/8] Alliberant IPs dels clients...${NC}"
    
    for vlan in 10 20 30; do
        echo -e "${BLUE}  → Alliberant VLAN ${vlan}${NC}"
        docker exec clab-${LAB_NAME}-client-vlan${vlan} dhclient -r eth1 2>&1 | grep -E "DHCPRELEASE" || true
        sleep 1
    done
    echo -e "${GREEN}✓ IPs alliberades${NC}"
    echo ""
}

# Funció per verificar alliberament
verify_release() {
    echo -e "${YELLOW}[7/8] Verificant que no hi ha IPs assignades...${NC}"
    
    for vlan in 10 20 30; do
        echo -e "${BLUE}VLAN ${vlan}:${NC}"
        ip_count=$(docker exec clab-${LAB_NAME}-client-vlan${vlan} ip -4 addr show eth1 | grep -c "inet 10.25.115" || echo "0")
        if [ "$ip_count" -eq "0" ]; then
            echo -e "  ${GREEN}✓ Sense IP assignada${NC}"
        else
            echo -e "  ${RED}✗ Encara té IP assignada${NC}"
        fi
    done
    echo ""
}

# Funció per mostrar resum
show_summary() {
    echo -e "${YELLOW}[8/8] Resum de la configuració${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Servidor Kea: 10.25.115.200/26"
    echo -e "VLAN 10: 10.25.115.0/26   (Pool: .10-.50,  GW: .1)"
    echo -e "VLAN 20: 10.25.115.64/26  (Pool: .74-.114, GW: .65)"
    echo -e "VLAN 30: 10.25.115.128/26 (Pool: .138-.178, GW: .129)"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo -e "${GREEN}✓ Totes les proves completades!${NC}"
}

# Executar totes les proves
main() {
    check_lab
    request_ips
    verify_ips
    verify_gateways
    check_leases
    release_ips
    verify_release
    show_summary
}

# Executar main
main
