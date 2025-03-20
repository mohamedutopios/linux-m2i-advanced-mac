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
    client.vm.network "private_network", ip: "192.168.56.10"
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

## **3️⃣ Configuration réseau sur les VM**
**🚀 Sur `router` (Passerelle & NAT)**
📌 **Activer le routage :**
```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
📌 **Ajouter une règle NAT pour permettre l’accès Internet aux autres VMs :**
```bash
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

**🖥 Sur `client` et `server`**
📌 **Configurer la passerelle pour qu’ils passent par `router` :**
```bash
sudo ip route add default via 192.168.56.1
```
📌 **Tester la connectivité Internet :**
```bash
ping -c 4 8.8.8.8
```

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
sudo iptables -P INPUT DROP
sudo iptables -P FORWARD DROP
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
sudo iptables -A INPUT -p icmp -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```
📌 **Enregistrer la configuration :**
```bash
sudo iptables-save > /etc/iptables/rules.v4
```
📌 **Tester depuis `client` :**
```bash
ping 192.168.56.1
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