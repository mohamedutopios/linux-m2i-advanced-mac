## 📚 Guide complet sur LVM (Logical Volume Manager)

### 1. **Rappel des principaux systèmes de fichiers**

- **ext2** : Ancien système sans journalisation, peu fiable en cas de crash, rarement utilisé aujourd'hui.
- **ext3** : Ajoute la journalisation à ext2, permettant une récupération plus rapide après un crash.
- **ext4** : Système moderne, rapide, fiable, supportant de grandes tailles de fichiers (jusqu'à 1 EiB).
- **XFS** : Optimisé pour la gestion des grands fichiers et systèmes de stockage massifs, performant pour les serveurs.
- **ZFS** : Système avancé avec intégrité des données, gestion RAID intégrée, et snapshots intégrés.

### 2. **Description détaillée de LVM et Device Mapper**

LVM (Logical Volume Manager) est une méthode avancée pour gérer les disques sous Linux, permettant la flexibilité dans la gestion des partitions. Le Device Mapper est la technologie sous-jacente utilisée par LVM pour gérer dynamiquement l'accès aux périphériques.

### 3. **Concepts fondamentaux : VG, PV, LV**

- **Physical Volume (PV)** : Un disque physique ou une partition qui rejoint LVM après initialisation avec `pvcreate`.
- **Volume Group (VG)** : Regroupe plusieurs PV pour créer un espace de stockage commun.
- **Logical Volume (LV)** : Partition virtuelle créée depuis un VG, modifiable dynamiquement.

### 4. **Extensions Physiques (PE) et Extensions Logiques (LE)**

Les données dans LVM sont divisées en blocs fixes appelés PE (Physical Extent, sur PV) et LE (Logical Extent, sur LV). La taille standard d'une PE est généralement de 4 Mo.

### 5. **Métadonnées LVM : PVRA, VGRA, BBRA**

- **PVRA** : Stockée sur chaque Physical Volume, contient les informations essentielles sur le PV.
- **VGRA** : Stockée dans chaque PV appartenant au même VG, contient les informations globales du Volume Group.
- **BBRA** : Historiquement utilisée pour la gestion des blocs défectueux, rarement utilisée aujourd'hui grâce aux disques modernes.

### 6. **Commandes essentielles pour gérer LVM**

- **Créer un PV** : `sudo pvcreate /dev/sdb`
- **Créer un VG** : `sudo vgcreate vg_donnees /dev/sdb`
- **Créer un LV** : `sudo lvcreate -L 20G -n lv_projets vg_donnees`
- **Formater un LV** : `sudo mkfs.ext4 /dev/vg_donnees/lv_projets`
- **Redimensionner un LV** :
  - Étendre : `sudo lvextend -L +10G /dev/vg_donnees/lv_projets && sudo resize2fs /dev/vg_donnees/lv_projets`
  - Réduire (attention aux données !) : `sudo lvreduce -L -5G /dev/vg_donnees/lv_projets && sudo resize2fs /dev/vg_donnees/lv_projets`

### 7. **Sécurisation des volumes avec LUKS**

Chiffrer un volume logique avec LUKS :

```bash
sudo apt install cryptsetup
sudo cryptsetup luksFormat /dev/vg_donnees/lv_projets
sudo cryptsetup luksOpen /dev/vg_donnees/lv_projets projets_secure
sudo mkfs.ext4 /dev/mapper/projets_secure
sudo mount /dev/mapper/projets_secure /mnt/projets
```

### 8. **Vérification et gestion au quotidien**

- Vérifier l'état des PV : `pvdisplay`
- Vérifier l'état des VG : `vgdisplay`
- Vérifier l'état des LV : `lvdisplay`

### Conclusion

LVM offre une solution flexible et puissante pour gérer le stockage sous Linux. Il simplifie les tâches administratives, améliore la sécurité et la disponibilité des données, tout en offrant une gestion optimisée et sécurisée des ressources de stockage.

