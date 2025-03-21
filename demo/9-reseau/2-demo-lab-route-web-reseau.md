Pour réaliser cette redirection, vous allez configurer le routeur pour que toute connexion arrivant sur le port 8080 soit redirigée (DNAT) vers la machine « server » à l'adresse 192.168.56.20 sur le port 80 (le port habituel d'un serveur web). Voici comment procéder :

---

### 1. Configuration de la redirection de port sur le routeur

Sur la machine « router », ajoutez la règle suivante dans la table NAT :

```bash
# DNAT : Rediriger le trafic TCP entrant sur le port 80 du routeur vers le serveur web (192.168.56.20:80)
iptables -t nat -A PREROUTING -p tcp --dport 80 -j DNAT --to-destination 192.168.56.20:80
# Hairpin NAT : Pour que le trafic provenant du réseau interne (192.168.56.0/24) et destiné au serveur
# soit NATé pour que la source apparaisse comme celle du routeur sur le réseau privé.
# Remplacez "eth1" par l'interface du réseau privé si nécessaire (souvent vboxnet0 dans VirtualBox).
iptables -t nat -A POSTROUTING -s 192.168.56.0/24 -d 192.168.56.20 -o eth1 -j MASQUERADE
```

Cette commande signifie :

- **-t nat** : Appliquer la règle dans la table NAT.
- **-A PREROUTING** : Ajouter la règle dans la chaîne PREROUTING (avant le routage).
- **-p tcp --dport 8080** : Pour tout paquet TCP destiné au port 8080.
- **-j DNAT --to-destination 192.168.56.20:80** : Modifier la destination pour pointer vers l'adresse IP de la machine server sur le port 80.

---

### 2. Vérifier que la règle NAT est bien appliquée

Vous pouvez vérifier la règle ajoutée avec :

```bash
sudo iptables -t nat -L PREROUTING -n -v
```

---

### 3. Test depuis le client

Sur la machine « client », ouvrez un navigateur web ou utilisez une commande comme curl pour tester la redirection :

```bash
curl http://192.168.56.1:80
```

ou simplement, dans un navigateur, tapez :

```
http://192.168.56.1:8080
```

Si tout est correctement configuré, le routeur redirigera la connexion vers la machine server (192.168.56.20 sur le port 80) et vous devriez récupérer le contenu du site web hébergé sur « server ».

---

### 4. Rappel sur le NAT général

Assurez-vous également que le NAT de sortie (MASQUERADE) est configuré sur le routeur pour permettre aux paquets de sortir vers Internet, même si dans ce cas-ci la redirection concerne uniquement le trafic interne :

```bash
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

---

### En résumé

- **Redirection de port (DNAT) :** La règle PREROUTING redirige le trafic entrant sur le port 8080 du routeur vers le port 80 de la machine server.
- **Test de la redirection :** Depuis le client, accéder à `http://192.168.56.1:8080` devrait renvoyer le contenu du serveur web hébergé sur server (192.168.56.20).

Cette configuration permet de simuler un scénario courant dans lequel un routeur offre un accès externe à un service interne en redirigeant un port non standard (ici 8080) vers le port habituel du service (ici 80 pour HTTP).