Voici un **résumé des commandes importantes** extraites du guide de maintenance de la configuration réseau sous Debian. Ces commandes couvrent les **interfaces réseau, routage, DNS, pare-feu, proxy, VPN, dépannage, optimisation et sécurité**.

---

## **📌 1. Configuration du réseau**

### **🔹 Gestion des interfaces réseau**
📌 **Lister les interfaces réseau disponibles :**
```bash
ip link show
```
📌 **Afficher les adresses IP des interfaces réseau :**
```bash
ip addr show
```
📌 **Configurer une adresse IP statique sur `eth0` (dans `/etc/network/interfaces`)**
```bash
auto eth0
iface eth0 inet static
    address 192.168.1.10
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4
```
📌 **Appliquer les modifications sans redémarrage :**
```bash
sudo ifdown eth0 && sudo ifup eth0
```
📌 **Activer/Désactiver une interface réseau manuellement :**
```bash
sudo ip link set eth0 up
sudo ip link set eth0 down
```
📌 **Ajouter une adresse IP temporairement :**
```bash
sudo ip addr add 192.168.1.100/24 dev eth0
```

---

## **🌍 2. Configuration du routage**
📌 **Afficher la table de routage :**
```bash
ip route show
```
📌 **Ajouter une passerelle par défaut :**
```bash
sudo ip route add default via 192.168.1.1 dev eth0
```
📌 **Ajouter une route statique :**
```bash
sudo ip route add 10.10.10.0/24 via 192.168.1.254 dev eth0
```
📌 **Supprimer une route statique :**
```bash
sudo ip route del 10.10.10.0/24 via 192.168.1.254 dev eth0
```

---

## **🌐 3. Configuration du DNS**
📌 **Modifier le fichier des résolveurs DNS (`/etc/resolv.conf`) :**
```bash
nameserver 8.8.8.8
nameserver 1.1.1.1
```
📌 **Vérifier la configuration DNS actuelle :**
```bash
cat /etc/resolv.conf
```
📌 **Tester la résolution DNS :**
```bash
dig google.com
nslookup google.com
```
📌 **Forcer la mise à jour de la configuration DNS :**
```bash
sudo systemctl restart systemd-resolved
```

---

## **🛡 4. Gestion du pare-feu (iptables / firewalld)**
📌 **Lister les règles iptables actuelles :**
```bash
sudo iptables -L -v -n
```
📌 **Bloquer toutes les connexions entrantes sauf SSH, HTTP, HTTPS :**
```bash
sudo iptables -P INPUT DROP
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```
📌 **Sauvegarder les règles iptables pour qu'elles persistent après un redémarrage :**
```bash
sudo iptables-save > /etc/iptables/rules.v4
```
📌 **Utiliser UFW pour gérer les règles plus simplement :**
```bash
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
```

---

## **🔁 5. Mise en place d’un Proxy et VPN**
📌 **Configurer Debian pour utiliser un proxy globalement (`/etc/environment`) :**
```bash
export http_proxy="http://proxy:3128"
export https_proxy="http://proxy:3128"
```
📌 **Installer et configurer un proxy Squid :**
```bash
sudo apt install squid
sudo systemctl enable --now squid
```
📌 **Installation d'OpenVPN :**
```bash
sudo apt install openvpn easy-rsa
```
📌 **Activer le forwarding IP pour VPN (dans `/etc/sysctl.conf`) :**
```bash
net.ipv4.ip_forward=1
```
📌 **Installation et configuration de WireGuard :**
```bash
sudo apt install wireguard
sudo wg-quick up wg0
```

---

## **🔍 6. Dépannage des problèmes courants**
📌 **Vérifier si une interface réseau est active :**
```bash
ip link show eth0
```
📌 **Tester la connectivité réseau :**
```bash
ping -c 5 8.8.8.8
```
📌 **Analyser le chemin des paquets avec traceroute :**
```bash
traceroute 8.8.8.8
```
📌 **Lister les connexions ouvertes :**
```bash
ss -tuln
```
📌 **Capturer et analyser le trafic réseau :**
```bash
sudo tcpdump -i eth0 -n port 80
```

---

## **⚡ 7. Optimisation des performances réseau**
📌 **Activer BBR pour améliorer la gestion de la congestion TCP :**
```bash
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
📌 **Ajuster les buffers TCP pour améliorer la bande passante :**
```bash
sudo sysctl -w net.core.rmem_max=26214400
sudo sysctl -w net.core.wmem_max=26214400
```
📌 **Limiter le trafic sortant d’une interface à 100 Mbps :**
```bash
sudo tc qdisc add dev eth0 root tbf rate 100mbit burst 32kbit latency 400ms
```

---

## **🛡 8. Sécurisation et supervision**
📌 **Sécuriser SSH en désactivant l'accès root et le mot de passe :**
```bash
sudo sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```
📌 **Activer Fail2Ban pour protéger SSH contre les attaques bruteforce :**
```bash
sudo apt install fail2ban
sudo systemctl enable --now fail2ban
```
📌 **Superviser l’activité réseau en temps réel :**
```bash
iftop -i eth0
```
📌 **Installer et configurer Prometheus pour la supervision centralisée :**
```bash
sudo apt install prometheus prometheus-node-exporter
sudo systemctl enable --now prometheus-node-exporter
```
📌 **Ajouter une règle d’alerte Prometheus pour le CPU élevé (`/etc/prometheus/alert.rules`) :**
```yaml
groups:
- name: CPU_Alerts
  rules:
  - alert: HighCpuLoad
    expr: avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) > 0.9
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "CPU load élevé"
```
📌 **Importer un tableau de bord Grafana pour surveiller un serveur Debian :**
1. Accéder à **Grafana**.
2. Aller dans **Dashboards > Import**.
3. Entrer **l’ID 1860** pour importer **Node Exporter Full**.

---

## ✅ **Conclusion**
Avec ces **commandes essentielles**, vous pouvez configurer, optimiser et sécuriser un serveur Debian pour la gestion du réseau. 🎯  

Besoin d’explications sur un point particulier ? N’hésitez pas ! 🚀