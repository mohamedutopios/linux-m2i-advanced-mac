Voici une démonstration **complète, réaliste, et pratique** d'une démarche de dépannage matériel sur une VM Debian (Vagrant), en provoquant volontairement **un problème réaliste**, puis en suivant une méthodologie structurée pour analyser, identifier et corriger l’incident.

---

# 🔖 **Scénario complet de la démonstration :**

**Incident matériel choisi :**  
> 🖴 **Saturation complète de l’espace disque du système Linux.**

Ce scénario est courant, réaliste, facile à provoquer, à diagnostiquer, puis à corriger. 

---

## 🎯 **Étape 1 : Préparer ta machine Vagrant**

Voici un `Vagrantfile` simple pour créer une machine Debian :

**`Vagrantfile` :**
```ruby
Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"
  config.vm.hostname = "linux-demo"
  config.vm.network "private_network", ip: "192.168.56.20"
end
```

Lance ta VM :

```bash
vagrant up
vagrant ssh
```

---

## 🚩 **Étape 2 : Provoquer volontairement un problème matériel (disque plein)**

Pour remplir rapidement le disque :

- Connecte-toi sur la VM :

```bash
vagrant ssh
```

- Remplis rapidement le disque en créant un gros fichier :

```bash
dd if=/dev/zero of=/tmp/fichier_gros.img bs=1M status=progress
```

- À un moment, la commande échoue avec le message d'erreur classique :

```
dd: error writing 'fichier': No space left on device
```

**Résultat :**  
Tu viens de provoquer un problème matériel réaliste : disque dur saturé.

---

## 🎯 **Étape 3 : Analyser et diagnostiquer l'incident**

La machine devient instable (impossible de créer des fichiers, logiciels ne fonctionnant plus correctement).

**Diagnostic :**

### ▶️ Vérification rapide de l’espace disque :

```bash
df -h /
```

Tu verras clairement l’espace saturé :

```bash
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       9.6G  9.9G     0  100% /
```

### ▶️ Vérifier les erreurs dans les logs du noyau :

```bash
dmesg | grep -i "No space"
```

Résultat concret (exemple) :
```
[234.56789] EXT4-fs warning (device sda1): ext4_da_write_end: ENOSPC: disk full...
```

### ▶️ Identifier précisément quel dossier prend de l'espace (`du`) :

```bash
sudo du -h / --max-depth=1 | sort -hr | head
```

Exemple de résultat clair :
```
9.5G   /home
```

- Tu comprends clairement que le problème est dû à un gros fichier créé récemment dans `/home` ou `/root`.

### ▶️ Identifier précisément le fichier problématique :

```bash
sudo find / -type f -size +500M -exec ls -lh {} \; 2>/dev/null
```

Résultat réaliste attendu :
```
-rw-r--r-- 1 root root 4.0G Mar 16 16:42 /home/vagrant/fichier.test
```

---

## 🎯 **Étape 4 : Corriger définitivement l'incident**

Après avoir identifié précisément le fichier saturant ton disque, corrige le problème :

**Solution : supprimer le fichier problématique**

```bash
sudo rm /home/vagrant/fichier_rempli.img
```

**Vérification finale :**

```bash
df -h
```

Résultat attendu après correction :
```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1        20G  3.5G   16G   5% /
```

---

## 🎯 **Étape 4 : Mettre en place des solutions préventives**

Pour éviter à l’avenir ce problème, tu peux configurer une alerte avec un outil de surveillance, exemple avec un script simple :

### ▶️ Script Bash simple de monitoring (préventif) :

`disk_alert.sh` :
```bash
#!/bin/bash
# Alerte si espace disque utilisé > 80%

ALERT=80
usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ "$usage" -gt "$ALERT" ]; then
  echo "⚠️ Alerte : utilisation du disque à $usage%" 
fi
```

Rendre exécutable :
```bash
chmod +x disk_alert.sh
```

Automatise avec un cron (optionnel) :
```bash
sudo crontab -e
```

Ajoute à la fin :
```cron
*/10 * * * * /home/vagrant/disk_alert.sh >> /var/log/disk_alert.log 2>&1
```

---

## 🎯 **Étape 4 (Alternative) : Autre méthode de résolution (Extension disque)**

Si tu souhaites plutôt **étendre l’espace disque** (alternative réaliste) :

1. Arrête la VM
```bash
vagrant halt
```

2. Augmente la taille du disque via VirtualBox (manuellement).

3. Redémarre la VM puis agrandis la partition :

- Installer les outils :
```bash
sudo apt install cloud-guest-utils
```

- Étends la partition automatiquement :
```bash
sudo growpart /dev/sda 1
sudo resize2fs /dev/sda1
```

---

## 🎯 **Synthèse rapide des étapes réalisées (démonstration) :**

| Étape | Action réalisée                         | Commandes utilisées                             |
|-------|-----------------------------------------|---------------------------------------------------|
| 1     | Préparer VM Debian via Vagrant          | `vagrant up`                                   |
| 2     | Provoquer l’incident (remplir disque)   | `dd if=/dev/zero of=fichier bs=1M`              |
| 3     | Diagnostiquer précisément               | `df -h`, `dmesg`, `find`                        |
| 4     | Corriger l’incident (suppression)       | `rm fichier`, vérification avec `df -h`         |
| 5     | Solution préventive : Monitoring simple | Script Bash + cron                             |

---

## 🎯 **Synthèse finale de l’exercice (Tableau récapitulatif)**

| Incident provoqué    | Outil de diagnostic                  | Solution corrective               |
|----------------------|--------------------------------------|-----------------------------------|
| Disque dur saturé    | `df -h`, `dmesg`, `find`, `du`, `ls` | Suppression du fichier volumineux |

---

## ✅ **Conclusion (apport de cette démonstration complète)**

Cette démonstration réaliste te permet :

- **Provoquer volontairement un incident matériel réel** (espace disque plein).
- **Diagnostiquer clairement** avec des commandes efficaces et pratiques.
- Mettre en œuvre une solution rapide, concrète et fonctionnelle.
- Implémenter des mécanismes simples mais efficaces de prévention.

Tu disposes désormais d’un cas concret de dépannage matériel **réaliste** en conditions pratiques sur Linux avec Vagrant.

Je reste disponible pour toute précision ou autre scénario !