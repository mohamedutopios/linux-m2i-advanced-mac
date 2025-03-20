### 🔥 **Tester et Résoudre les Problèmes Réseau Courants sur un LAB Multi-VM avec Vagrant**  

Nous allons **simuler des problèmes réseau affectant les 3 VMs** (Client, Routeur, Serveur) et les **résoudre avec des commandes adaptées**.  

📌 **Structure du réseau :**
```
+----------------+        +----------------+        +----------------+
|  VM-Client     |------->|  VM-Router     |------->|  VM-Serveur    |
|  192.168.56.10 |        | 192.168.56.1   |        | 192.168.56.20  |
+----------------+        +----------------+        +----------------+
```
---

## **1️⃣ Installation du LAB avec Vagrant**
📌 **Créer un fichier `Vagrantfile` :**
```ruby
Vagrant.configure("2") do |config|
  # VM Routeur
  config.vm.define "router" do |router|
    router.vm.box = "debian/bookworm64"
    router.vm.network "private_network", ip: "192.168.56.1"
  end

  # VM Client
  config.vm.define "client" do |client|
    client.vm.box = "debian/bookworm64"
    client.vm.network "private_network", ip: "192.168.56.10"
  end

  # VM Serveur
  config.vm.define "server" do |server|
    server.vm.box = "debian/bookworm64"
    server.vm.network "private_network", ip: "192.168.56.20"
  end
end
```
📌 **Démarrer les VMs :**
```bash
vagrant up
```
📌 **Se connecter à une VM (ex: routeur) :**
```bash
vagrant ssh router
```
---

## **2️⃣ Problèmes Multi-VM et Résolutions**

### **🚨 Problème 1 : Le Client ne peut plus atteindre le Serveur**
📌 **Créer le problème** : Supprimer la route sur `router`
```bash
sudo ip route del 192.168.56.0/24
```
📌 **Vérifier la table de routage sur `router` :**
```bash
ip route show
```
📌 **Solution : Ajouter la route statique sur `router`**
```bash
sudo ip route add 192.168.56.0/24 via 192.168.56.1
```
📌 **Tester la connexion depuis `client` vers `server`**
```bash
ping -c 4 192.168.56.20
```
---

### **❌ Problème 2 : Pas de connectivité Internet pour le Client**
📌 **Créer le problème** : Désactiver le NAT sur `router`
```bash
sudo iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE
```
📌 **Tester la connectivité depuis `client` :**
```bash
ping -c 4 8.8.8.8
```
📌 **Solution : Réactiver le NAT sur `router`**
```bash
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```
📌 **Ajouter une passerelle sur `client`**
```bash
sudo ip route add default via 192.168.56.1
```
---

### **🌐 Problème 3 : Le Client ne peut pas résoudre les noms de domaine**
📌 **Créer le problème** : Changer le fichier `resolv.conf` sur `client`
```bash
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
```
📌 **Tester la résolution DNS :**
```bash
dig google.com
```
📌 **Solution : Configurer le bon serveur DNS (`router`)**
```bash
echo "nameserver 192.168.56.1" | sudo tee /etc/resolv.conf
```
📌 **Vérifier que le service DNS `dnsmasq` fonctionne sur `router` :**
```bash
sudo systemctl restart dnsmasq
```
---

### **🛡 Problème 4 : Le Pare-feu du Serveur bloque le Client**
📌 **Créer le problème** : Bloquer les connexions entrantes sur `server`
```bash
sudo iptables -A INPUT -p tcp --dport 80 -j DROP
```
📌 **Tester la connexion depuis `client` :**
```bash
curl -I http://192.168.56.20
```
📌 **Solution : Autoriser les connexions HTTP sur `server`**
```bash
sudo iptables -D INPUT -p tcp --dport 80 -j DROP
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
```
📌 **Sauvegarder la configuration du pare-feu :**
```bash
sudo iptables-save > /etc/iptables/rules.v4
```
---

### **📈 Problème 5 : Le Réseau est très lent entre Client et Serveur**
📌 **Créer le problème** : Limiter la bande passante sur `router`
```bash
sudo tc qdisc add dev eth1 root tbf rate 512kbit burst 32kbit latency 400ms
```
📌 **Tester la bande passante avec `iperf` :**
```bash
iperf -c 192.168.56.20
```
📌 **Solution : Désactiver la limitation**
```bash
sudo tc qdisc del dev eth1 root
```
---

### **🔄 Problème 6 : Un trop grand nombre de connexions simultanées bloque le Serveur**
📌 **Créer le problème** : Simuler un grand nombre de connexions depuis `client`
```bash
for i in {1..100}; do nc -zv 192.168.56.20 80 & done
```
📌 **Vérifier les connexions ouvertes sur `server` :**
```bash
ss -tuna | grep ESTABLISHED
```
📌 **Solution : Limiter les connexions simultanées sur `server`**
```bash
sudo iptables -A INPUT -p tcp --syn --dport 80 -m connlimit --connlimit-above 10 -j DROP
```
---

### **🚀 Problème 7 : Le Serveur ne peut plus envoyer de paquets**
📌 **Créer le problème** : Bloquer le trafic sortant sur `server`
```bash
sudo iptables -P OUTPUT DROP
```
📌 **Vérifier la politique du pare-feu :**
```bash
sudo iptables -L -v -n
```
📌 **Solution : Restaurer le trafic sortant**
```bash
sudo iptables -P OUTPUT ACCEPT
```
---

## **✅ Résumé**
- 📌 **Création d’un LAB avec 3 VMs** sous Vagrant.
- 🚨 **Simulation de problèmes réseau multi-VM**.
- 🛠 **Utilisation des bonnes commandes** pour **diagnostiquer et résoudre**.
- 📊 **Utilisation d’outils réseau** (`ping`, `traceroute`, `iptables`, `tc`, `dig`, `iperf`).

---

🔥 **Vous avez maintenant un LAB complet pour tester et comprendre les problèmes réseau sous Debian !**  
Besoin d’un scénario spécifique ? **Je peux l’ajouter !** 🚀