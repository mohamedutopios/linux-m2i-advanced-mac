#!/bin/bash
# Script de configuration NAT pour le routeur

# Masquer le trafic sortant via l'interface NAT (souvent eth0)
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# DNAT : Rediriger le trafic TCP entrant sur le port 80 du routeur vers le serveur web (192.168.56.20:80)
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.56.20:80

# Hairpin NAT : Pour que le trafic provenant du réseau interne (192.168.56.0/24) et destiné au serveur
# soit NATé pour que la source apparaisse comme celle du routeur sur le réseau privé.
# Remplacez "eth1" par l'interface du réseau privé si nécessaire (souvent vboxnet0 dans VirtualBox).
iptables -t nat -A POSTROUTING -s 192.168.56.0/24 -d 192.168.56.20 -o eth1 -j MASQUERADE

echo "Configuration NAT appliquée."
