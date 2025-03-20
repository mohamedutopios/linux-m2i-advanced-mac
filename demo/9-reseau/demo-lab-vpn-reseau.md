Voici une **mise en place complète** de WireGuard entre **router** et **client**, avec toutes les étapes détaillées pour assurer une connexion sécurisée.

---

## 🔗 **Architecture du VPN**
Nous avons **deux machines** configurées dans Vagrant :
1. **`router` (Serveur VPN WireGuard)**
   - Adresse réseau privée : `192.168.56.1`
   - Adresse VPN WireGuard : `10.0.0.1`
   - Port WireGuard : `51820`
   
2. **`client` (Client VPN)**
   - Adresse réseau privée : `192.168.56.10`
   - Adresse VPN WireGuard : `10.0.0.2`
   
Les deux machines seront connectées via un **VPN WireGuard**.

---

## 🚀 **1️⃣ Déployer les machines avec Vagrant**
Crée un fichier `Vagrantfile` :

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
end
```
Lance les machines :
```bash
vagrant up
```

Accède aux machines :
```bash
vagrant ssh router
```
et
```bash
vagrant ssh client
```

---

## 🔧 **2️⃣ Installation de WireGuard sur `router` et `client`**
Sur **les deux machines** (`router` et `client`), exécute :
```bash
sudo apt update
sudo apt install wireguard -y
```

Vérifie que WireGuard est bien installé :
```bash
wg --version
```

---

## 🔑 **3️⃣ Génération des clés cryptographiques**
Sur **router** :
```bash
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
```
Sur **client** :
```bash
wg genkey | tee /etc/wireguard/privatekey | wg pubkey > /etc/wireguard/publickey
```

Récupère les clés :
```bash
cat /etc/wireguard/privatekey  # Clé privée
cat /etc/wireguard/publickey   # Clé publique
```

Note :
- La **clé publique du router** devra être ajoutée au client.
- La **clé publique du client** devra être ajoutée au router.

---

## 🖥 **4️⃣ Configuration du Serveur WireGuard (`router`)**
Édite le fichier de configuration sur `router` :
```bash
sudo nano /etc/wireguard/wg0.conf
```

Ajoute la configuration :
```ini
[Interface]
Address = 10.0.0.1/24
PrivateKey = <clé privée de router>
ListenPort = 51820

[Peer]
PublicKey = <clé publique du client>
AllowedIPs = 10.0.0.2/32
```
Remplace `<clé privée de router>` et `<clé publique du client>` par les vraies clés.

Active WireGuard :
```bash
sudo wg-quick up wg0
```
Vérifie l’état :
```bash
sudo wg show
```

---

## 🖥 **5️⃣ Configuration du Client WireGuard (`client`)**
Édite le fichier de configuration sur `client` :
```bash
sudo nano /etc/wireguard/wg0.conf
```

Ajoute :
```ini
[Interface]
Address = 10.0.0.2/24
PrivateKey = <clé privée du client>

[Peer]
PublicKey = <clé publique du router>
Endpoint = 192.168.56.1:51820
AllowedIPs = 10.0.0.0/24
PersistentKeepalive = 25
```
Remplace `<clé privée du client>` et `<clé publique du router>` par les vraies clés.

Active WireGuard :
```bash
sudo wg-quick up wg0
```
Vérifie :
```bash
sudo wg show
```

---

## 🎯 **6️⃣ Test de la connexion VPN**
Depuis `client`, teste la connexion au `router` :
```bash
ping 10.0.0.1
```
Si tout fonctionne, tu devrais voir une réponse.

Depuis `router`, teste la connexion à `client` :
```bash
ping 10.0.0.2
```

---

## 🛠 **7️⃣ Configuration pour rendre le VPN persistant**
Ajoute les services WireGuard au démarrage :

Sur `router` et `client` :
```bash
sudo systemctl enable wg-quick@wg0
```
Cela garantit que le VPN démarre automatiquement à chaque redémarrage.

---

## 🌐 **8️⃣ Activer le routage (Si `router` doit fournir Internet)**
Sur `router`, active le **transfert de paquets** :
```bash
sudo sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
```

Ajoute une règle NAT pour router le trafic VPN :
```bash
sudo iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
```
Sauvegarde les règles iptables :
```bash
sudo apt install iptables-persistent -y
sudo netfilter-persistent save
```

Sur `client`, ajoute une route pour passer par `router` :
```bash
sudo ip route add 0.0.0.0/0 via 10.0.0.1
```

---

## ✅ **Résumé des étapes**
1. **Déployer les machines (`router` et `client`) avec Vagrant.**
2. **Installer WireGuard** sur les deux machines.
3. **Générer les clés privées et publiques** sur chaque machine.
4. **Configurer le serveur VPN WireGuard (`router`).**
5. **Configurer le client VPN WireGuard (`client`).**
6. **Tester la connexion entre `router` et `client`.**
7. **Activer le VPN au démarrage.**
8. **(Optionnel) Activer le routage pour permettre à `router` de fournir Internet.**

---

## 🏆 **Résultat attendu**
- **`router` et `client` sont connectés via WireGuard.**
- **Le trafic entre eux est chiffré.**
- **(Optionnel) `client` peut utiliser `router` pour accéder à Internet.**

---

🎯 **Prochaines étapes ?**
- Tester le **transfert de fichiers** entre `router` et `client`.
- Ajouter une **authentification supplémentaire** avec des **clés PSK**.
- Monitorer le VPN avec `wg show`.

💡 **WireGuard est rapide, sécurisé et simple à gérer ! 🚀**