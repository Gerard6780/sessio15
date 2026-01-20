# Fase 2 - Guia Ràpida: VLANs i DHCP Relay

**IP Assignada**: 10.25.115.0/24  
**Directori**: `fase2-vlans/`

---

## Arquitectura

| VLAN | Subnet | Pool | Gateway | Relay Backend |
|------|--------|------|---------|---------------|
| VLAN 10 | 10.25.115.0/26 | .10-.50 | .1 | .100 |
| VLAN 20 | 10.25.115.64/26 | .74-.114 | .65 | .101 |
| VLAN 30 | 10.25.115.128/26 | .138-.178 | .129 | .102 |
| Backend | 10.25.115.192/26 | - | - | .200 (Kea) |

---

## Desplegament Ràpid

### 1. Construir imatge relay (només primera vegada)

```bash
cd ~/Documents/AntiGraviti/Serveis/sessio15
./scripts/build-images.sh
```

### 2. Desplegar lab

```bash
sudo containerlab deploy -t fase2-vlans/topology.clab.yml
```

### 3. Executar proves automàtiques

```bash
chmod +x scripts/test-fase2-vlans.sh
./scripts/test-fase2-vlans.sh
```

---

## Proves Manuals

### Sol·licitar IPs

```bash
# VLAN 10
docker exec clab-kea-lab-vlans-client-vlan10 dhclient -v eth1

# VLAN 20
docker exec clab-kea-lab-vlans-client-vlan20 dhclient -v eth1

# VLAN 30
docker exec clab-kea-lab-vlans-client-vlan30 dhclient -v eth1
```

### Verificar IPs i Gateways

```bash
# Veure IP assignada VLAN 10
docker exec clab-kea-lab-vlans-client-vlan10 ip addr show eth1 | grep "inet "

# Veure gateway VLAN 10
docker exec clab-kea-lab-vlans-client-vlan10 ip route | grep default
```

### Consultar Leases al Servidor

```bash
docker exec clab-kea-lab-vlans-kea cat /var/lib/kea/kea-leases4.csv | grep "10.25.115" | grep -v "^#"
```

### Alliberar IPs

```bash
docker exec clab-kea-lab-vlans-client-vlan10 dhclient -r eth1
docker exec clab-kea-lab-vlans-client-vlan20 dhclient -r eth1
docker exec clab-kea-lab-vlans-client-vlan30 dhclient -r eth1
```

---

## Capturar Tràfic DHCP

**Terminal 1** (captura):
```bash
docker exec clab-kea-lab-vlans-relay-vlan10 tcpdump -i any -n port 67 or port 68 -v
```

**Terminal 2** (client):
```bash
docker exec clab-kea-lab-vlans-client-vlan10 dhclient -v eth1
```

**Observar**: DISCOVER, OFFER, REQUEST, ACK i el camp `giaddr=10.25.115.1`

---

## Afegir Nova VLAN (VLAN 40)

### 1. Editar `fase2-vlans/configs/kea/kea-dhcp4.conf`

Afegir subnet:
```json
{
    "id": 40,
    "subnet": "10.25.115.192/27",
    "pools": [{"pool": "10.25.115.200 - 10.25.115.220"}],
    "option-data": [{"name": "routers", "data": "10.25.115.193"}]
}
```

### 2. Editar `fase2-vlans/topology.clab.yml`

Afegir nodes i links (veure LAB02-GUIA-VLANS.md per detalls)

### 3. Redesplegar

```bash
sudo containerlab destroy --name kea-lab-vlans
sudo containerlab deploy -t fase2-vlans/topology.clab.yml
```

---

## Destruir Lab

```bash
sudo containerlab destroy --name kea-lab-vlans
```

---

## Documentació Completa

Per més detalls, consulta: [LAB02-GUIA-VLANS.md](LAB02-GUIA-VLANS.md)
