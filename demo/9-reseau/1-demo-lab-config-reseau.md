Oui, nous pouvons tester toutes ces configurations dans des **VM avec Vagrant** pour avoir un **environnement de test réaliste**. 🎯  

## **🔹 Mise en place d'un LAB réseau avec Vagrant**
Nous allons :
1. **Créer plusieurs VM Debian** avec **Vagrant**.
2. **Configurer le réseau** (interfaces statiques, routage, pare-feu, DNS, proxy, VPN).
3. **Tester les performances** en simulant des goulots d’étranglement.
4. **Superviser avec Prometheus et Grafana**.

---

## **1️⃣ Installation de Vagrant et VirtualBox**
Avant de commencer, installez **Vagrant** et **VirtualBox** sur votre machine.

📌 **Sous Debian / Ubuntu :**
```bash
sudo apt update && sudo apt install vagrant virtualbox
```
📌 **Sous Windows (via Chocolately) :**
```powershell
choco install vagrant virtualbox
```
📌 **Sous macOS (via Homebrew) :**
```bash
brew install --cask vagrant virtualbox
```

⚠ **Vérifiez l’installation :**
```bash
vagrant --version
virtualbox --help
```

---

## **2️⃣ Création d’un LAB avec 3 VM (Router, Client, Serveur)**
📌 **Structure du réseau :**
```
+----------------+        +----------------+        +----------------+
|  VM-Client     |------->|  VM-Router     |------->|  VM-Serveur    |
|  192.168.56.10 |        | 192.168.56.1   |        | 192.168.56.20  |
+----------------+        +----------------+        +----------------+
```

📌 **Créer un fichier `Vagrantfile` :**
```ruby
Vagrant.configure("2") do |config|
  # VM Routeur
  config.vm.define "router" do |router|
    router.vm.box = "debian/bookworm64"
    router.vm.network "private_network", ip: "192.168.56.1"
    router.vm.provider "virtualbox" do |vb|
      vb.memory = 512
      vb.cpus = 1
    end
  end

  # VM Client
  config.vm.define "client" do |client|
    client.vm.box = "debian/bookworm64"
    client.vm.network "private_network", ip: "192.168.56.11"
    client.vm.provider "virtualbox" do |vb|
      vb.memory = 512
      vb.cpus = 1
    end
  end

  # VM Serveur
  config.vm.define "server" do |server|
    server.vm.box = "debian/bookworm64"
    server.vm.network "private_network", ip: "192.168.56.20"
    server.vm.provider "virtualbox" do |vb|
      vb.memory = 512
      vb.cpus = 1
    end
  end
end
```

📌 **Démarrer les VMs :**
```bash
vagrant up
```
📌 **Se connecter à une VM (ex: Router) :**
```bash
vagrant ssh router
```

---

Voici une version corrigée et intégrée des étapes pour configurer le réseau sur vos VM :

---

## **3️⃣ Configuration réseau sur les VM**

### **🚀 Sur `router` (Passerelle & NAT)**
1. **Activer le routage IP**  
   Permet de faire transiter le trafic entre les interfaces.
   ```bash
   echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
   sudo sysctl -p
   ```

2. **Ajouter la règle NAT (MASQUERADE)**  
   Cette règle masque le trafic provenant du réseau privé lorsqu’il sort par l’interface NAT (généralement `eth0`) vers Internet.
   ```bash
   sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
   ```

3. **(Vérification / Ajustement de la route par défaut)**  
   Assurez-vous que le routeur utilise bien son interface NAT pour sortir vers Internet. Si la route par défaut n’est pas présente ou correcte, ajoutez-la (par exemple, si la passerelle NAT est `10.0.2.2`) :
   ```bash
   sudo ip route add default via 10.0.2.2 dev eth0
   ```
   *Note :* Dans de nombreuses configurations Vagrant, cette route est déjà présente par défaut.

---

### **🖥 Sur `client` et `server`**
1. **Configurer la passerelle via `router`**  
   Supprimez la route par défaut existante sur l’interface NAT (`eth0`) et ajoutez une nouvelle route par défaut pour utiliser l’interface réseau privé (`eth1`) et passer par `router` (IP `192.168.56.1`) :
   ```bash
   sudo ip route del default via 10.0.2.2 dev eth0
   sudo ip route add default via 192.168.56.1 dev eth1
   ```

2. **Tester la connectivité Internet**  
   Vérifiez que la redirection fonctionne en pingant une adresse externe (ici, Google DNS) :
   ```bash
   ping -c 4 8.8.8.8
   ```

---

### **Points de vérification complémentaires**

- **Sur le routeur**, vous pouvez vérifier le trafic NAT et la transmission des paquets en utilisant :
  ```bash
  sudo iptables -t nat -L -n
  sudo iptables -L FORWARD -n
  ```
- **Utilisez `tcpdump`** sur le routeur pour observer le trafic sur les interfaces, par exemple :
  ```bash
  sudo apt-get update
  sudo apt-get install tcpdump
  sudo tcpdump -i eth0
  ```

Cette configuration permet au routeur de servir de passerelle NAT pour les VMs `client` et `server` et d’assurer que leur trafic Internet passe correctement par le réseau privé vers le routeur, puis vers Internet via l’interface NAT.
---

## **4️⃣ Tester le DNS**
📌 **Sur `router`, installer un serveur DNS `dnsmasq` :**
```bash
sudo apt install dnsmasq -y
```
📌 **Modifier `/etc/dnsmasq.conf` :**
```ini
listen-address=192.168.56.1
bind-interfaces
server=8.8.8.8
```
📌 **Redémarrer `dnsmasq` :**
```bash
sudo systemctl restart dnsmasq
```
📌 **Configurer `client` pour utiliser ce DNS :**
```bash
echo "nameserver 192.168.56.1" | sudo tee /etc/resolv.conf
```
📌 **Tester :**
```bash
dig google.com
```

---

## **5️⃣ Configuration du pare-feu avec `iptables`**
📌 **Sur `router`, bloquer tout sauf le trafic autorisé :**
```bash
# Définir les politiques par défaut sur DROP
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -P OUTPUT ACCEPT

# INPUT et FORWARD sont en DROP, ce qui signifie que tout est bloqué sauf ce qui est explicitement autorisé.
# OUTPUT est mis sur ACCEPT (pour permettre au routeur d'envoyer du trafic sans restriction).

# INPUT : Autoriser les connexions déjà établies ou reliées
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# INPUT : Autoriser les requêtes ICMP (ping) destinées au routeur
sudo iptables -A INPUT -p icmp -j ACCEPT

# INPUT : Autoriser SSH (port 22) vers le routeur
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT

sudo iptables -I INPUT -p udp --dport 53 -j ACCEPT

sudo iptables -I INPUT -p tcp --dport 53 -j ACCEPT

# INPUT (optionnel) : Autoriser HTTP/HTTPS si le routeur doit lui-même servir du contenu web
sudo iptables -A INPUT -p tcp -m multiport --dports 80,443 -j ACCEPT

#Chaîne INPUT :

# On autorise les paquets déjà établis.
# On autorise ICMP et le SSH pour la gestion du routeur.
# On autorise HTTP/HTTPS si le routeur doit recevoir des connexions web.

# FORWARD : Autoriser les connexions déjà établies ou reliées transitant par le routeur
sudo iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# FORWARD : Autoriser le trafic ICMP transitant par le routeur
sudo iptables -A FORWARD -p icmp -j ACCEPT

# FORWARD : Autoriser les nouvelles connexions HTTP et HTTPS initiées depuis le réseau interne
sudo iptables -A FORWARD -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW -j ACCEPT

# Chaîne FORWARD :

# On autorise les paquets établis pour le transit.
# On ajoute une règle explicite pour autoriser les paquets ICMP transitant.
# On autorise les nouvelles connexions TCP destinées aux ports 80 et 443 (HTTP/HTTPS) initiées depuis le réseau interne.

# Pour le NAT, autoriser le masquage du trafic sortant via l'interface NAT (ici eth0)
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# NAT :

# La règle MASQUERADE dans la table NAT permet aux paquets provenant du réseau interne de sortir vers Internet via l'interface eth0 en utilisant l'adresse IP publique du routeur.


```
📌 **Enregistrer la configuration :**
```bash
sudo mkdir -p /etc/iptables
sudo iptables-save | sudo tee /etc/iptables/rules.v4 > /dev/null
```
📌 **Tester depuis `client` :**
```bash
ping 192.168.56.1
telnet 192.168.56.1 22
refus pour :  telnet 192.168.56.1 80

```

📌 **Tester depuis `client` :**
```bash
sudo apt-get update
sudo apt-get install nmap
sudo nmap -p 22,80,443 192.168.56.1
```

---

## **6️⃣ Configuration d'un VPN WireGuard**
📌 **Sur `router` : Installer WireGuard**
```bash
sudo apt install wireguard -y
```
📌 **Générer les clés :**
```bash
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
```
📌 **Configurer `/etc/wireguard/wg0.conf` :**
```ini
[Interface]
Address = 10.0.0.1/24
PrivateKey = <clé privée>
ListenPort = 51820

[Peer]
PublicKey = <clé publique du client>
AllowedIPs = 10.0.0.2/32
```
📌 **Activer WireGuard :**
```bash
sudo wg-quick up wg0
```

---

## **7️⃣ Superviser avec Prometheus et Grafana**
📌 **Sur `router`, installer Prometheus et Node Exporter :**
```bash
sudo apt install prometheus prometheus-node-exporter -y
sudo systemctl enable --now prometheus-node-exporter
```
📌 **Ajouter `router` comme cible dans `/etc/prometheus/prometheus.yml` :**
```yaml
scrape_configs:
  - job_name: 'router'
    static_configs:
      - targets: ['localhost:9100']
```
📌 **Démarrer Prometheus :**
```bash
sudo systemctl restart prometheus
```
📌 **Installer Grafana sur `router` :**
```bash
sudo apt install grafana -y
sudo systemctl enable --now grafana-server
```
📌 **Se connecter à Grafana sur `http://192.168.56.1:3000`** et **ajouter Prometheus** comme source de données.

---

## **✅ Résumé**
- **Création d’un LAB** avec **Vagrant** & **3 VM**.
- **Mise en place du réseau**, **pare-feu** et **routage**.
- **Test du DNS** avec `dnsmasq`.
- **Sécurisation avec iptables** et **VPN WireGuard**.
- **Supervision avec Prometheus & Grafana**.

---

📢 **Vous pouvez maintenant tester et modifier ces configurations en toute sécurité sur vos VM !** 🚀  
Besoin d’un cas particulier supplémentaire ? Je peux l’ajouter ! 😊