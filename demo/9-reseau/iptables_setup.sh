#!/bin/bash
# Script de configuration d'iptables pour le routeur

# Définir les politiques par défaut sur DROP pour INPUT et FORWARD, et sur ACCEPT pour OUTPUT
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# INPUT : Autoriser les connexions déjà établies ou reliées
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# INPUT : Autoriser les requêtes ICMP (ping) destinées au routeur
iptables -A INPUT -p icmp -j ACCEPT

# INPUT : Autoriser SSH (port 22) vers le routeur
iptables -A INPUT -p tcp --dport 22 -j ACCEPT

# INPUT (optionnel) : Autoriser HTTP/HTTPS si le routeur doit lui-même servir du contenu web
iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

# FORWARD : Autoriser les connexions déjà établies ou reliées transitant par le routeur
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# FORWARD : Autoriser le trafic ICMP transitant par le routeur
iptables -A FORWARD -p icmp -j ACCEPT

# FORWARD : Autoriser les nouvelles connexions HTTP et HTTPS initiées depuis le réseau interne
iptables -A FORWARD -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW -j ACCEPT

echo "Configuration iptables appliquée."
