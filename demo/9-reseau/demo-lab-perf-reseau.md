# 🔥 **LAB Vagrant : Optimisation des Performances Réseau sous Debian**
Ce LAB va permettre de **tester et optimiser les performances réseau** en simulant un trafic réseau entre **Client**, **Routeur** et **Serveur**, en appliquant différentes techniques d’optimisation.

📌 **Scénario :**
- **VM-Client** envoie du trafic vers **VM-Serveur** via **VM-Routeur**.
- On applique **BBR pour améliorer la congestion TCP**.
- On **ajuste les buffers TCP** pour optimiser la bande passante.
- On **limite la vitesse de connexion** avec `tc` et on mesure l’impact.

---

## **1️⃣ Installation et Configuration du LAB**
### **📌 Création du Vagrantfile**
On crée un **fichier `Vagrantfile`** pour générer les **3 machines virtuelles** :

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
📌 **Lancer les VMs :**
```bash
vagrant up
```
📌 **Se connecter aux VMs :**
```bash
vagrant ssh router
vagrant ssh client
vagrant ssh server
```
---

## **2️⃣ Configuration du Réseau**
### **🚀 Activer le routage et NAT sur `router`**
📌 **Activer le forwarding des paquets :**
```bash
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
📌 **Ajouter une règle NAT pour que `client` et `server` accèdent à Internet :**
```bash
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```
📌 **Définir `router` comme passerelle sur `client` et `server` :**
```bash
sudo ip route add default via 192.168.56.1
```
📌 **Tester la connectivité depuis `client` vers `server` :**
```bash
ping -c 4 192.168.56.20
```

---

## **3️⃣ Tester la Bande Passante Avant Optimisation**
📌 **Installer `iperf3` sur `client` et `server`**
```bash
sudo apt update && sudo apt install -y iperf3
```
📌 **Démarrer le serveur de test sur `server`**
```bash
iperf3 -s
```
📌 **Exécuter un test de débit depuis `client`**
```bash
iperf3 -c 192.168.56.20
```
📌 **Exemple de résultat avant optimisation :**
```
[ ID] Interval       Transfer     Bandwidth
[  5]  0.0-10.0 sec  112 MBytes  94.1 Mbits/sec
```

---

## **4️⃣ Appliquer des Optimisations Réseau**
### **🔹 Activer BBR pour améliorer la gestion de la congestion TCP**
📌 **Sur `router` et `server`, activer BBR :**
```bash
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
📌 **Vérifier que BBR est bien activé :**
```bash
sysctl net.ipv4.tcp_congestion_control
```
📌 **Sortie attendue :**
```
net.ipv4.tcp_congestion_control = bbr
```

---

### **🔹 Ajuster les Buffers TCP pour améliorer la bande passante**
📌 **Sur `router`, `client` et `server` :**
```bash
sudo sysctl -w net.core.rmem_max=26214400
sudo sysctl -w net.core.wmem_max=26214400
```
📌 **Rendre la modification permanente :**
```bash
echo "net.core.rmem_max=26214400" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max=26214400" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
📌 **Vérifier la valeur appliquée :**
```bash
sysctl net.core.rmem_max
sysctl net.core.wmem_max
```
📌 **Sortie attendue :**
```
net.core.rmem_max = 26214400
net.core.wmem_max = 26214400
```

---

### **🔹 Limiter la bande passante avec `tc`**
📌 **Limiter la bande passante à 100 Mbps sur `router`**
```bash
sudo tc qdisc add dev eth0 root tbf rate 100mbit burst 32kbit latency 400ms
```
📌 **Vérifier la configuration :**
```bash
tc qdisc show dev eth0
```
📌 **Sortie attendue :**
```
qdisc tbf 8001: root refcnt 2 rate 100Mbit burst 32Kb lat 400.0ms
```

---

## **5️⃣ Vérifier l'Amélioration des Performances**
📌 **Relancer le test `iperf3` entre `client` et `server`**
```bash
iperf3 -c 192.168.56.20
```
📌 **Exemple de résultat après optimisation :**
```
[ ID] Interval       Transfer     Bandwidth
[  5]  0.0-10.0 sec  118 MBytes  98.7 Mbits/sec
```
✅ **On constate une amélioration du débit réseau grâce aux optimisations TCP et BBR.**

---

## **6️⃣ Nettoyer et Restaurer les Paramètres**
📌 **Supprimer la limitation de bande passante :**
```bash
sudo tc qdisc del dev eth0 root
```
📌 **Réinitialiser les paramètres TCP :**
```bash
sudo sysctl -w net.ipv4.tcp_congestion_control=cubic
sudo sysctl -w net.core.rmem_max=212992
sudo sysctl -w net.core.wmem_max=212992
```
📌 **Redémarrer le réseau :**
```bash
sudo systemctl restart networking
```

---

## **✅ Résumé**
📌 **Création d’un LAB avec 3 VMs** sous Vagrant.  
📌 **Mise en place du réseau** avec un routeur NAT.  
📌 **Test de débit avec `iperf3` avant optimisation.**  
📌 **Optimisation de la gestion TCP avec BBR et buffers TCP.**  
📌 **Application et test des optimisations.**  
📌 **Restauration des paramètres par défaut.**  

---

🔥 **Ce LAB vous permet d’expérimenter les réglages réseau en conditions réelles.**  
Besoin d’ajouter **d’autres scénarios d’optimisation** ? Dites-moi ! 🚀😊