# Lab02 - Guia Completa Fase 2: VLANs i DHCP Relay

**IP Assignada**: 10.25.115.0/24  
**Objectiu**: Demostrar i dominar la configuració de VLANs amb DHCP relay

---

## Arquitectura de Xarxa

### Divisió de Subnets

La IP base **10.25.115.0/24** s'ha dividit en 4 subnets utilitzant màscara /26:

| VLAN | Subnet | Rang Utilitzable | Pool DHCP | Gateway | Relay Backend |
|------|--------|------------------|-----------|---------|---------------|
| **VLAN 10** | 10.25.115.0/26 | .1 - .62 | .10 - .50 | .1 | .100 |
| **VLAN 20** | 10.25.115.64/26 | .65 - .126 | .74 - .114 | .65 | .101 |
| **VLAN 30** | 10.25.115.128/26 | .129 - .190 | .138 - .178 | .129 | .102 |
| **Backend** | 10.25.115.192/26 | .193 - .254 | - | - | .200 (Kea) |

### Diagrama de Topologia

```
                    ┌─────────────────┐
                    │   Kea Server    │
                    │  10.25.115.200  │
                    └────────┬────────┘
                             │ Backend (10.25.115.192/26)
          ┌──────────────────┼──────────────────┐
          │                  │                  │
    ┌─────┴──────┐     ┌─────┴──────┐     ┌─────┴──────┐
    │Relay VLAN10│     │Relay VLAN20│     │Relay VLAN30│
    │ .100 / .1  │     │ .101 / .65 │     │ .102 / .129│
    └─────┬──────┘     └─────┬──────┘     └─────┬──────┘
          │                  │                  │
    10.25.115.0/26     10.25.115.64/26    10.25.115.128/26
          │                  │                  │
    ┌─────┴──────┐     ┌─────┴──────┐     ┌─────┴──────┐
    │Client VLAN10│    │Client VLAN20│    │Client VLAN30│
    └────────────┘     └────────────┘     └────────────┘
```

---

## Prerequisits

### 1. Construir la imatge del relay

```bash
cd ~/Documents/AntiGraviti/Serveis/sessio15
./scripts/build-images.sh
```

Això crearà la imatge `kea-relay:latest` necessària per als relays DHCP.

### 2. Verificar imatges disponibles

```bash
docker images | grep -E "kea-dhcp4|kea-relay|netshoot"
```

Hauries de veure:
- `docker.cloudsmith.io/isc/docker/kea-dhcp4:2.6.1`
- `kea-relay:latest`
- `nicolaka/netshoot:latest`

---

## Desplegament del Lab

### 1. Desplegar la topologia

```bash
cd ~/Documents/AntiGraviti/Serveis/sessio15
sudo containerlab deploy -t lab02-vlans/topology.clab.yml
```

### 2. Verificar desplegament

```bash
# Veure tots els contenidors
docker ps --filter "name=clab-kea-lab02"

# Inspeccionar topologia
sudo containerlab inspect --name kea-lab02-vlans
```

Hauries de veure 7 contenidors:
- 1 servidor Kea
- 3 relays (vlan10, vlan20, vlan30)
- 3 clients (vlan10, vlan20, vlan30)

### 3. Verificar connectivitat backend

```bash
# Des del servidor Kea, fer ping als relays
docker exec clab-kea-lab02-vlans-kea ping -c 2 10.25.115.100  # relay-vlan10
docker exec clab-kea-lab02-vlans-kea ping -c 2 10.25.115.101  # relay-vlan20
docker exec clab-kea-lab02-vlans-kea ping -c 2 10.25.115.102  # relay-vlan30
```

---

## Proves i Verificacions

### Opció A: Script Automàtic (Recomanat)

```bash
cd ~/Documents/AntiGraviti/Serveis/sessio15
chmod +x scripts/test-lab02-vlans.sh
./scripts/test-lab02-vlans.sh
```

Aquest script executa automàticament totes les proves següents.

### Opció B: Proves Manuals

#### 1. Sol·licitar IPs dels clients

```bash
# VLAN 10
docker exec clab-kea-lab02-vlans-client-vlan10 dhclient -v eth1

# VLAN 20
docker exec clab-kea-lab02-vlans-client-vlan20 dhclient -v eth1

# VLAN 30
docker exec clab-kea-lab02-vlans-client-vlan30 dhclient -v eth1
```

**Resultat esperat**: Cada client hauria de rebre un missatge `DHCPACK` i `bound to` amb una IP del seu pool corresponent.

#### 2. Verificar IPs assignades

```bash
# Verificar VLAN 10 (esperat: 10.25.115.10-50)
docker exec clab-kea-lab02-vlans-client-vlan10 ip addr show eth1 | grep "inet "

# Verificar VLAN 20 (esperat: 10.25.115.74-114)
docker exec clab-kea-lab02-vlans-client-vlan20 ip addr show eth1 | grep "inet "

# Verificar VLAN 30 (esperat: 10.25.115.138-178)
docker exec clab-kea-lab02-vlans-client-vlan30 ip addr show eth1 | grep "inet "
```

#### 3. Comprovar gateways

```bash
# VLAN 10 (esperat: 10.25.115.1)
docker exec clab-kea-lab02-vlans-client-vlan10 ip route | grep default

# VLAN 20 (esperat: 10.25.115.65)
docker exec clab-kea-lab02-vlans-client-vlan20 ip route | grep default

# VLAN 30 (esperat: 10.25.115.129)
docker exec clab-kea-lab02-vlans-client-vlan30 ip route | grep default
```

#### 4. Consultar leases al servidor

```bash
# Veure tots els leases
docker exec clab-kea-lab02-vlans-kea cat /var/lib/kea/kea-leases4.csv

# Filtrar només les IPs assignades
docker exec clab-kea-lab02-vlans-kea cat /var/lib/kea/kea-leases4.csv | grep "10.25.115" | grep -v "^#"
```

**Format del fitxer CSV**:
```
address,hwaddr,client_id,valid_lifetime,expire,subnet_id,fqdn_fwd,fqdn_rev,hostname,state,user_context
```

#### 5. Alliberar IPs

```bash
# Alliberar VLAN 10
docker exec clab-kea-lab02-vlans-client-vlan10 dhclient -r eth1

# Alliberar VLAN 20
docker exec clab-kea-lab02-vlans-client-vlan20 dhclient -r eth1

# Alliberar VLAN 30
docker exec clab-kea-lab02-vlans-client-vlan30 dhclient -r eth1
```

#### 6. Verificar alliberament

```bash
# Verificar que no tenen IP
docker exec clab-kea-lab02-vlans-client-vlan10 ip addr show eth1 | grep "inet 10.25"
docker exec clab-kea-lab02-vlans-client-vlan20 ip addr show eth1 | grep "inet 10.25"
docker exec clab-kea-lab02-vlans-client-vlan30 ip addr show eth1 | grep "inet 10.25"
```

Si no hi ha output, les IPs s'han alliberat correctament.

---

## Proves Avançades

### Capturar tràfic DHCP amb tcpdump

Aquesta prova permet veure el funcionament del DHCP relay:

**Terminal 1** (captura al relay):
```bash
docker exec clab-kea-lab02-vlans-relay-vlan10 tcpdump -i any -n port 67 or port 68 -v
```

**Terminal 2** (sol·licitar IP):
```bash
docker exec clab-kea-lab02-vlans-client-vlan10 dhclient -v eth1
```

**Què observar**:
1. **DHCP DISCOVER** del client (0.0.0.0 → 255.255.255.255)
2. **DHCP DISCOVER reenviat** pel relay (10.25.115.100 → 10.25.115.200) amb `giaddr=10.25.115.1`
3. **DHCP OFFER** del servidor
4. **DHCP REQUEST** del client
5. **DHCP ACK** del servidor

### Verificar logs del servidor Kea

```bash
docker logs clab-kea-lab02-vlans-kea | tail -50
```

Busca línies com:
```
DHCP4_PACKET_RECEIVED [hwtype=1 ...] from 10.25.115.100:67 to 10.25.115.200:67
DHCP4_LEASE_ALLOC [hwtype=1 ...] lease 10.25.115.10 has been allocated
```

---

## Afegir una Nova VLAN (VLAN 40)

### 1. Modificar configuració Kea

Edita `lab02-vlans/configs/kea/kea-dhcp4.conf` i afegeix:

```json
{
    "id": 40,
    "subnet": "10.25.115.192/27",
    "pools": [
        {
            "pool": "10.25.115.200 - 10.25.115.220"
        }
    ],
    "option-data": [
        {
            "name": "routers",
            "data": "10.25.115.193"
        }
    ]
}
```

> [!WARNING]
> Això utilitzarà part de la xarxa backend. Per un entorn de producció, caldria replantejar l'arquitectura de subnetting.

### 2. Modificar topologia

Edita `lab02-vlans/topology.clab.yml` i afegeix:

```yaml
# A la secció nodes
relay-vlan40:
  kind: linux
  image: kea-relay:latest
  env:
    DHCP_SERVER: "10.25.115.200"
    LISTEN_INTERFACE: "eth2"
  startup-delay: 10
  exec:
    - ip addr add 10.25.115.103/26 dev eth1
    - ip addr add 10.25.115.193/27 dev eth2

client-vlan40:
  kind: linux
  image: nicolaka/netshoot:latest

br-vlan40:
  kind: bridge

# A la secció links
- endpoints: ["relay-vlan40:eth1", "br-backend:be-r40"]
- endpoints: ["relay-vlan40:eth2", "br-vlan40:v40-relay"]
- endpoints: ["client-vlan40:eth1", "br-vlan40:v40-cli"]
```

### 3. Afegir ruta al servidor Kea

A la secció `kea.exec` del topology:

```yaml
- ip route add 10.25.115.192/27 via 10.25.115.103
```

### 4. Redesplegar

```bash
sudo containerlab destroy --name kea-lab02-vlans
sudo containerlab deploy -t lab02-vlans/topology.clab.yml
```

### 5. Provar VLAN 40

```bash
docker exec clab-kea-lab02-vlans-client-vlan40 dhclient -v eth1
docker exec clab-kea-lab02-vlans-client-vlan40 ip addr show eth1
```

---

## Solució de Problemes

### El client no obté IP

1. **Verificar que el relay està executant-se**:
   ```bash
   docker exec clab-kea-lab02-vlans-relay-vlan10 ps aux | grep dhcp
   ```

2. **Verificar connectivitat relay → Kea**:
   ```bash
   docker exec clab-kea-lab02-vlans-relay-vlan10 ping -c 2 10.25.115.200
   ```

3. **Verificar rutes al servidor Kea**:
   ```bash
   docker exec clab-kea-lab02-vlans-kea ip route
   ```

### Error "No DHCPOFFERS received"

- Verificar que el servidor Kea està escoltant:
  ```bash
  docker exec clab-kea-lab02-vlans-kea ss -ulnp | grep 67
  ```

- Verificar configuració JSON:
  ```bash
  docker exec clab-kea-lab02-vlans-kea kea-dhcp4 -t /etc/kea/kea-dhcp4.conf
  ```

### El relay no reenvia paquets

- Verificar configuració del relay:
  ```bash
  docker logs clab-kea-lab02-vlans-relay-vlan10
  ```

- Verificar que té IP a ambdues interfícies:
  ```bash
  docker exec clab-kea-lab02-vlans-relay-vlan10 ip addr
  ```

---

## Netejar el Lab

```bash
sudo containerlab destroy --name kea-lab02-vlans
```

---

## Resum de Comandes Ràpides

```bash
# Desplegar
sudo containerlab deploy -t lab02-vlans/topology.clab.yml

# Provar tot automàticament
./scripts/test-lab02-vlans.sh

# Sol·licitar IP manualment
docker exec clab-kea-lab02-vlans-client-vlan10 dhclient -v eth1

# Veure leases
docker exec clab-kea-lab02-vlans-kea cat /var/lib/kea/kea-leases4.csv | grep -v "^#"

# Alliberar IP
docker exec clab-kea-lab02-vlans-client-vlan10 dhclient -r eth1

# Destruir
sudo containerlab destroy --name kea-lab02-vlans
```

---

## Referències

- [Documentació Kea DHCP](https://kea.readthedocs.io/)
- [Containerlab](https://containerlab.dev/)
- [DHCP Relay RFC 1542](https://tools.ietf.org/html/rfc1542)
