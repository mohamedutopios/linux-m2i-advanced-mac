Voici des exemples pratiques concrets pour maîtriser les deux opérations suivantes avec **LVM (Logical Volume Manager)** sous Linux :

- **1. Augmentation de la capacité d’un volume logique existant.**
- **2. Création d’un nouveau Volume Group (VG), d'un Logical Volume (LV) formaté en ext4 et monté de manière permanente.**

---

# 🚩 **Travaux Pratiques LVM concrets**

---

## 🟢 TP1 : Augmentation de la capacité d'un volume logique

**Situation initiale :** Vous disposez d’un volume logique existant nommé `lv_data` appartenant au groupe de volumes nommé `vg_data`, monté sur `/mnt/data`. Vous souhaitez ajouter 20 Go d’espace supplémentaire à ce volume.

### 📌 Étape 1 : Vérifier l'espace disponible dans le VG

```bash
sudo vgs
```
_Exemple de sortie :_
```bash
VG        #PV #LV #SN Attr   VSize   VFree
vg_data     1   1   0 wz--n- 100.00g 20.00g
```

On voit ici qu'il reste 20 Go (`VFree`) libres dans le `vg_data`.

### 🔸 **Si le VG n’a pas assez d’espace** : Ajoutez d’abord un nouveau disque physique au VG.

1. Initialiser un nouveau disque physique (`/dev/sdb`) :
```bash
sudo pvcreate /dev/sdb
sudo vgextend vg_data /dev/sdb
```

### 🔸 **Agrandissement du LV existant :**

Augmenter le volume logique `lv_data` de 10 Go supplémentaires :

```bash
sudo lvextend -L +10G /dev/vg_data/lv_data
```

ou pour utiliser tout l’espace libre disponible automatiquement :

```bash
sudo lvextend -l +100%FREE /dev/vg_data/lv_data
```

### 🔸 **Redimensionnement du système de fichiers (en ligne pour ext4) :**

- Pour un système de fichiers ext4, on peut le faire en ligne sans démonter :

```bash
sudo resize2fs /dev/vg_data/lv_data
```

### 🔸 **Vérification finale :**

```bash
sudo df -h | grep lv_data
```

Votre volume logique est maintenant augmenté à chaud, sans interruption de service.

---

## 🟢 TP2 : Création d’un nouveau VG, d'un LV formaté en ext4 et monté de façon permanente

**Cas pratique :** Vous avez ajouté un nouveau disque physique (`/dev/sdb`) et vous souhaitez créer un nouveau groupe de volumes (`vg_backup`), puis créer et monter un volume logique de façon permanente dans `/mnt/sauvegarde`.

### 📌 Étape 1 : Initialiser le disque physique (PV)

```bash
sudo pvcreate /dev/sdb
```

Vérification :

```bash
sudo pvs
```

Exemple de résultat :
```
PV         VG    Fmt  Attr PSize   PFree
/dev/sdb         lvm2 ---  200.00g 200.00g
```

---

## 🟢 Étape 2 : Créer un groupe de volumes (VG)

Créer un groupe nommé `vg_backup` avec `/dev/sdb` :

```bash
sudo vgcreate vg_backup /dev/sdb
```

Vérification :

```bash
sudo vgs
```

Résultat attendu :
```
VG        #PV #LV #SN Attr   VSize   VFree
vg_data     1   1   0 wz--n- 100.00g 10.00g
vg_backup   1   0   0 wz--n- 200.00g 200.00g
```

---

## 🟢 Création du volume logique (LV)

Créons un volume logique `lv_backup` de **50 Go** dans le volume groupe `vg_backup` :

```bash
sudo lvcreate -L 50G -n lv_backup vg_backup
```

- `-L` : taille précise à allouer
- `-n` : nom du Logical Volume

Vérification :

```bash
sudo lvs
```

Résultat attendu :
```
LV          VG        Attr       LSize  Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
lv_data     vg_data   -wi-ao---- 90.00g                                                    
lv_backup   vg_backup -wi-a----- 50.00g
```

---

### 🟢 Formatage du LV en système ext4 :

```bash
sudo mkfs.ext4 /dev/vg_backup/lv_backup
```

---

## 🟢 Montage permanent du volume logique (LV)

### 🔸 Créer un point de montage :

```bash
sudo mkdir -p /mnt/backup
```

### 🔸 Modifier le fichier `/etc/fstab` pour montage permanent :

Ajoutez cette ligne à la fin du fichier `/etc/fstab` :

```bash
/dev/vg_backup/lv_backup /mnt/backup ext4 defaults 0 2
```

- `/dev/vg_backup/lv_backup` : identifiant du volume logique
- `/mnt/backup` : répertoire de montage
- `ext4` : type de système de fichiers
- `defaults` : options de montage standard
- (`0 2`) : valeurs pour `dump` (0 désactivé) et ordre de vérification système (`fsck` au boot).

### 🔸 Monter le volume immédiatement :

```bash
sudo mount -a
```

Vérification immédiate :

```bash
df -h | grep backup
```

Résultat attendu :
```
/dev/mapper/vg_backup-lv_backup   50G  24K  47G   1% /mnt/backup
```

Désormais, le volume est monté automatiquement à chaque redémarrage du système grâce à son entrée dans `/etc/fstab`.

---

✅ **Synthèse des commandes utilisées :**

| Opération                     | Commandes essentielles                                |
|-------------------------------|-------------------------------------------------------|
| Initialiser un PV             | `pvcreate /dev/sdb`                                   |
| Créer un VG                   | `vgcreate vg_name /dev/sdb`                           |
| Créer un LV                   | `lvcreate -L 10G -n lv_name vg_name`                  |
| Formater LV                   | `mkfs.ext4 /dev/VGname/LVname`                        |
| Monter (permanent via fstab)  | `/etc/fstab`                                          |
| Étendre un LV                 | `lvextend -L +sizeG /dev/VGname/LVname && resize2fs`  |
| Vérifier volumes              | `pvs`, `vgs`, `lvs`, `df -h`, `df -h`                 |

---

Ce guide complet permet de maîtriser en pratique LVM, en réalisant simplement des opérations courantes de gestion des volumes logiques sur un système Linux classique.