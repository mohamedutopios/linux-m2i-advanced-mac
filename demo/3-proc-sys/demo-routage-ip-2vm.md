Voici une démonstration complète, concrète et détaillée, en utilisant **Vagrant**, pour créer une topologie réseau afin d’illustrer clairement la différence avec et sans activation du routage IP (**`ip_forward`**) via `sysctl`.

---

## 🚩 **1. Situation initiale**

Tu disposes déjà d'une VM Linux (« routeur Linux ») avec :

- `lo` : loopback
- `eth0` : `10.0.2.15` (NAT vers Internet)
- `eth1` : `192.168.56.10` (Réseau privé `192.168.56.0/24`)

Tu vas ajouter **2 VMs via Vagrant** :

- **PC1** : connecté sur le réseau `192.168.56.0/24` (côté eth1)
- **PC2** : connecté sur un nouveau réseau privé, par exemple : `192.168.100.0/24`

Ton routeur Linux aura donc 3 interfaces finales :

- `eth0` : 10.0.2.15
- `eth1` : 192.168.56.10 (réseau PC1)
- `eth2` : 192.168.100.1 (réseau PC2)

---

## 🚩 **2. Installer et préparer Vagrant**

Sur ta machine hôte (Windows/Linux) :

- Installe **Vagrant** : [https://developer.hashicorp.com/vagrant/downloads](https://developer.hashicorp.com/vagrant/downloads)
- Installe un hyperviseur : VirtualBox recommandé

---

## 🚩 **3. Fichier `Vagrantfile` complet pour PC1 et PC2**

Crée un dossier dédié (ex. `demo-routing`) :

```bash
mkdir demo-routing
cd demo-routing
```

Crée le fichier `Vagrantfile` avec ce contenu précis :

```ruby
Vagrant.configure("2") do |config|
  
  config.vm.box = "debian/bookworm64"

  # PC1 connecté au réseau 192.168.56.0 (même réseau que eth1 du routeur)
  config.vm.define "pc1" do |pc1|
    pc1.vm.hostname = "pc1"
    pc1.vm.network "private_network", ip: "192.168.56.20"
  end

  # PC2 connecté au réseau privé 192.168.100.0
  config.vm.define "pc2" do |pc2|
    pc2.vm.hostname = "pc2"
    pc2.vm.network "private_network", ip: "192.168.100.20"
  end
end
```

**Explication des IP choisies :**

- PC1 : IP `192.168.56.20` (connecté sur ton eth1 `192.168.56.10`)
- PC2 : IP `192.168.100.20` (tu devras créer `eth2` sur ta VM Linux existante)

---

## 🚩 **4. Lancer les deux VM via Vagrant**

Démarre les deux VMs simplement :

```bash
vagrant up
```

Vérifie que les machines sont bien actives :

```bash
vagrant status
```

---

## 🚩 **5. Ajouter l’interface eth2 (réseau 192.168.100.x) à ton Linux routeur existant**

Sur ta VM Linux actuelle (**routeur Linux**), ajoute une carte réseau VirtualBox supplémentaire (adaptateur 3) :

- Choisis : Réseau privé hôte (Host-only)
- Associe-la au réseau : `vboxnet1` (qui correspondra à `192.168.100.x`).

Redémarre ensuite ta VM Linux existante, puis configure la nouvelle interface réseau eth2 :

```bash
sudo ip addr add 192.168.100.1/24 dev eth2
sudo ip link set eth2 up
```

Vérifie ensuite tes interfaces réseau :

```bash
ip addr show
```

Tu dois avoir :
- eth1 → `192.168.56.10`
- eth2 → `192.168.100.1`

---

## 🚩 **6. Configuration des routes statiques sur PC1 et PC2**

### ▶️ **Connexion à PC1 :**
```bash
vagrant ssh pc1
```

Configure une route vers le réseau de PC2 (`192.168.100.0/24`) via ton Linux routeur (`192.168.56.10`) :

```bash
sudo ip route add 192.168.100.0/24 via 192.168.56.10
```

### ▶️ **Connexion à PC2 :**
```bash
vagrant ssh pc2
```

Configure une route vers le réseau de PC1 (`192.168.56.0/24`) via ton Linux routeur (`192.168.100.1`) :

```bash
sudo ip route add 192.168.56.0/24 via 192.168.100.1
```

---

## 🚩 **7. Démonstration AVANT activation du routage (ip_forward = 0)**

Vérifie l'état de `ip_forward` sur ton Linux routeur existant :

```bash
cat /proc/sys/net/ipv4/ip_forward
# Résultat attendu : 0
```

Depuis **PC1**, teste la communication vers **PC2** :

```bash
ping 192.168.100.20
# Attendu : Destination Host Unreachable (échec)
```

---

## 🚩 **8. Démonstration APRÈS activation du routage (ip_forward = 1)**

Active temporairement sur le Linux routeur :

```bash
sudo sysctl -w net.ipv4.ip_forward=1
```

Vérifie l'activation :

```bash
sysctl net.ipv4.ip_forward
# Résultat attendu : 1
```

Depuis **PC1**, refais le test vers **PC2** :

```bash
ping 192.168.100.20
# Attendu : Communication réussie !
```

---

## 🚩 **9. Rendre l’activation permanente (optionnel)**

Édite sur ta VM Linux routeur :

```bash
sudo nano /etc/sysctl.conf
```

Ajoute à la fin :

```bash
net.ipv4.ip_forward=1
```

Recharge définitivement :

```bash
sudo sysctl -p
```

---

## 🚩 **10. Schéma récapitulatif**

```
PC1 (192.168.56.20) ──┐
                      ├── (192.168.56.10) Linux Routeur (192.168.100.1) ── PC2 (192.168.100.20)
PC2 (192.168.100.20) ─┘
```

| Routage IP (`ip_forward`) | Résultat ping PC1 → PC2 |
|---------------------------|-------------------------|
| Désactivé (`0`)           | ❌ Impossible           |
| Activé (`1`)              | ✅ Possible             |

---

## ✅ **Conclusion :**

Tu disposes ainsi d'une démo complète, prête à être testée, pour illustrer clairement la différence concrète avec et sans activation du routage IP sous Linux via Vagrant, VirtualBox et une topologie réseau simple mais réaliste.

Je reste disponible si tu rencontres des difficultés dans ces étapes.