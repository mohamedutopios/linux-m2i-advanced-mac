Voici une présentation détaillée du système de fichiers Btrfs, organisée selon les points que vous avez mentionnés :

---

## 1. Présentation de Btrfs : Historique et caractéristiques générales

**Historique :**
- Btrfs (B-Tree File System) a été initié par Oracle en 2007, avec Chris Mason comme principal développeur au départ.  
- Son développement est motivé par le besoin d’un système de fichiers de nouvelle génération, adapté aux grandes volumétries, à la vérification de l’intégrité des données et à des fonctionnalités avancées (telles que le Copy-on-Write et les snapshots).  
- Il a été progressivement intégré au noyau Linux (première inclusion officielle dans Linux 2.6.29 en 2009). Aujourd’hui, il est maintenu par plusieurs contributeurs du noyau Linux et grandes entreprises (Oracle, Facebook/Meta, SUSE, etc.).  

**Caractéristiques générales :**
- **Copy-on-Write (CoW)** : Chaque modification de fichier crée de nouvelles métadonnées et blocs de données au lieu d’écraser ceux existants, ce qui facilite notamment la création de snapshots.  
- **Snapshots et subvolumes** : Btrfs introduit la notion de subvolumes, qui sont des unités logiques pouvant être “photographiées” (snapshottées) à un instant donné.  
- **Vérification d’intégrité** : Btrfs gère des checksums sur les données et les métadonnées, permettant de détecter et éventuellement de corriger des corruptions.  
- **RAID natif** : Btrfs permet de configurer des niveaux de RAID (0, 1, 10, 5, 6) directement au niveau du système de fichiers.  
- **Compression transparente** : Btrfs propose différents algorithmes de compression (zlib, lzo, zstd) activables à la volée.  
- **Évolutivité** : Conçu pour gérer de très grands volumes de données (à terme jusqu’à 16 exaoctets).

---

## 2. Volumes et Subvolumes : Création, gestion et différences avec les partitions classiques

### Différences avec les partitions classiques
- Dans un schéma classique (ext4, xfs, etc.), on crée une **partition** ou un **volume logique** (LVM) pour chaque point de montage.  
- Btrfs gère un **pool** de stockage dans lequel on peut créer plusieurs **subvolumes**.  
- Les subvolumes fonctionnent comme des “répertoires spéciaux” qui peuvent être montés indépendamment, mais ils partagent l’espace de stockage sous-jacent du volume Btrfs.  

### Création d’un système de fichiers Btrfs
1. **Partitionnement initial** : on crée généralement une partition dédiée (de type `btrfs`) ou on utilise un disque entier.  
2. **Formatage** :  
   ```bash
   mkfs.btrfs /dev/sdX  # ou sur un ensemble de disques
   ```
3. **Montage** :  
   ```bash
   mkdir /mnt/btrfs
   mount -t btrfs /dev/sdX /mnt/btrfs
   ```
   
### Création et gestion de subvolumes
- **Création d’un subvolume** :  
  ```bash
  btrfs subvolume create /mnt/btrfs/mon_subvolume
  ```
- **Lister les subvolumes** :  
  ```bash
  btrfs subvolume list /mnt/btrfs
  ```
- **Supprimer un subvolume** :  
  ```bash
  btrfs subvolume delete /mnt/btrfs/mon_subvolume
  ```
- **Montage d’un subvolume spécifique** :  
  ```bash
  mount -t btrfs -o subvol=mon_subvolume /dev/sdX /mnt/btrfs_sub
  ```

> **Note** : Contrairement à une partition classique, l’espace n’est pas strictement cloisonné. Tous les subvolumes d’un même pool se partagent la même capacité, tant qu’il y a de l’espace disponible sur le disque ou le groupe de disques.

---

## 3. Snapshots : Création, gestion et restauration d’instantanés

### Création d’un snapshot
- Les snapshots Btrfs peuvent être **en lecture-écriture** ou **en lecture seule**.  
- Exemple de création d’un snapshot en lecture-écriture :  
  ```bash
  btrfs subvolume snapshot /mnt/btrfs/mon_subvolume /mnt/btrfs/mon_subvolume_snapshot
  ```
- Pour un snapshot en lecture seule, on ajoute l’option `-r` :  
  ```bash
  btrfs subvolume snapshot -r /mnt/btrfs/mon_subvolume /mnt/btrfs/mon_subvolume_snapshot_ro
  ```

### Gestion des snapshots
- **Lister tous les snapshots** :  
  ```bash
  btrfs subvolume list /mnt/btrfs
  ```
  Vous verrez chaque snapshot listé comme un subvolume supplémentaire.  
- **Supprimer un snapshot** :  
  ```bash
  btrfs subvolume delete /mnt/btrfs/mon_subvolume_snapshot
  ```
  
### Restauration à partir d’un snapshot
- La restauration peut se faire de différentes manières :  
  1. **Copier manuellement** les données du snapshot vers le subvolume source.  
  2. **Renommer** le subvolume original et **renommer** le snapshot pour qu’il devienne la nouvelle référence.  
  3. Utiliser des scripts ou outils dédiés (par exemple `snapper`, `timeshift` ou des outils maison).  

Exemple simplifié :  
```bash
# On démonte le subvolume actuel
umount /mnt/btrfs

# On renomme l'ancien subvolume
btrfs subvolume snapshot -r /mnt/btrfs/mon_subvolume_snapshot /mnt/btrfs/mon_subvolume_restored

# On monte le subvolume restauré
mount -t btrfs -o subvol=mon_subvolume_restored /dev/sdX /mnt/btrfs
```

---

## 4. Copy-on-Write (CoW) : Explication et impact sur les performances et la gestion des fichiers

**Principe du CoW :**
- Lorsque vous modifiez un fichier sur Btrfs, au lieu d’écraser les blocs originaux, le système de fichiers écrit les nouvelles données dans d’autres blocs et met à jour les métadonnées pour pointer vers ces nouveaux blocs.  
- Avantage : la création de snapshots est très rapide et peu coûteuse en espace (initialement, un snapshot ne stocke que les métadonnées).  
- Inconvénient : la fragmentation peut augmenter avec le temps, ce qui peut affecter les performances d’IO, particulièrement sur les charges d’écriture intensive (bases de données, VM).  

**Gestion des performances :**
- **Autodefragmentation** : Btrfs propose l’option de montage `autodefrag`, qui tente de limiter la fragmentation pour les fichiers de taille modérée.  
- **NoCoW** : Pour les répertoires contenant des fichiers très sollicités (notamment des images de machines virtuelles ou des bases de données), on peut paramétrer le bit “NOCOW” (via l’attribut `chattr +C /mon/dossier`) pour désactiver le CoW sur ces fichiers. (À noter : cela doit être fait sur un dossier vide avant d’y placer des fichiers.)

---

## 5. Compression : Activation et types de compression supportés (zlib, lzo, zstd)

Btrfs propose plusieurs algorithmes de compression :

- **zlib** : Compression relativement lente, mais taux de compression élevé.  
- **lzo** : Plus rapide que zlib, mais avec un taux de compression généralement plus faible.  
- **zstd** : Un bon compromis entre vitesse et taux de compression, avec différents niveaux de compression (`zstd:1`, `zstd:3`, etc.).  

### Activation de la compression
- Au montage du système de fichiers, on peut spécifier l’option :  
  ```bash
  mount -o compress=zstd /dev/sdX /mnt/btrfs
  ```
- On peut aussi préciser :  
  ```bash
  mount -o compress=zstd:3 /dev/sdX /mnt/btrfs
  ```
  pour définir un niveau.  
- **compress-force** : Force la compression même si Btrfs détecte que les données ne sont pas compressibles.  
  ```bash
  mount -o compress-force=zstd /dev/sdX /mnt/btrfs
  ```

> **Note** : La compression s’applique aux nouveaux fichiers écrits après l’activation de l’option. Les fichiers existants ne sont pas re-compressés automatiquement (sauf si l’option `autodefrag` est activée et en partie seulement).

---

## 6. Redondance et RAID : Gestion des modes RAID intégrés à Btrfs

Btrfs propose différents modes RAID (0, 1, 10, 5, 6) au niveau du système de fichiers.  
- **RAID 0** : Aucune redondance, performance accrue.  
- **RAID 1** : Miroir des données, tolérance à la panne d’un disque.  
- **RAID 10** : Combinaison de striping et mirroring (4 disques minimum).  
- **RAID 5/6** : Parité, permet la tolérance à la panne de 1 disque (RAID5) ou 2 disques (RAID6). Toutefois, RAID 5/6 sur Btrfs est historiquement considéré comme moins stable que les autres niveaux, bien que la situation s’améliore au fil des versions.

### Création d’un volume Btrfs en RAID
```bash
mkfs.btrfs -d raid1 -m raid1 /dev/sdX /dev/sdY
```
- `-d` spécifie le mode RAID pour les données.  
- `-m` spécifie le mode RAID pour les métadonnées.  

### Conversion d’un RAID
- On peut ajouter/supprimer des disques et convertir un volume Btrfs d’un mode RAID à un autre via la commande `btrfs balance` :  
  ```bash
  btrfs device add /dev/sdZ /mnt/btrfs
  btrfs balance start -dconvert=raid1 -mconvert=raid1 /mnt/btrfs
  ```
  
---

## 7. Outils et bonnes pratiques : Commandes utiles pour l’administration et la maintenance

### Commandes clés
1. **`btrfs fi df`** : Pour visualiser l’espace disque utilisé et la distribution (data, metadata).  
2. **`btrfs fi usage`** : Donne une vue d’ensemble de l’utilisation du système de fichiers.  
3. **`btrfs subvolume create|list|delete|snapshot`** : Gestion des subvolumes et snapshots.  
4. **`btrfs balance`** : Redistribution (rebalance) des données à travers les disques (utile après ajout/retrait d’un disque ou changement de RAID).  
5. **`btrfs scrub`** : Permet de vérifier l’intégrité des données et de détecter/corriger les corruptions (avec RAID redondant).  
6. **`btrfs check`** : Outil de vérification/réparation hors-ligne du système de fichiers (à n’utiliser qu’en dernier recours ou dans un environnement de maintenance).  
7. **`snapper` ou `timeshift`** : Outils externes pour la gestion automatisée des snapshots (planification, rotation, restauration).  

### Bonnes pratiques
- **Effectuer régulièrement des scrubs** (via un cron ou systemd timer) pour détecter tôt les corruptions.  
- **Mettre à jour son noyau** : de nombreux correctifs et améliorations Btrfs sont intégrés à chaque nouvelle version du noyau.  
- **Planifier des snapshots réguliers** : Permet la restauration rapide en cas d’erreur.  
- **Séparer des subvolumes** pour `/root`, `/home`, `/var`, etc. Cela facilite la gestion des sauvegardes et snapshots sélectifs.  
- **Surveiller l’espace libre** : Btrfs nécessite de l’espace libre pour les réallocations. Il est recommandé de ne pas remplir un volume Btrfs à ras-bord afin d’éviter des ralentissements ou des blocages.  
- **Éviter RAID5/6** en production critique (ou le tester soigneusement) en raison d’historiques problèmes de stabilité, bien que ces niveaux s’améliorent avec les mises à jour récentes.  
- **Défragmentation (autodefrag)** : Utile sur des workloads de bureau, moins recommandé pour des bases de données volumineuses (préférer NOCOW selon les cas).

---

## Conclusion

Btrfs est un système de fichiers moderne et riche en fonctionnalités (subvolumes, snapshots, compression, RAID natif, CoW, etc.). Il offre une flexibilité importante en matière d’organisation, de sauvegarde et de tolérance aux pannes. Cependant, pour bénéficier pleinement de ses avantages, il convient de bien comprendre ses principes de fonctionnement (particulièrement la gestion des subvolumes et le Copy-on-Write) et de suivre les bonnes pratiques d’administration (scrub régulier, snapshots programmés, gestion soignée de l’espace, choix judicieux du RAID).  

Grâce à ces recommandations et à une connaissance des outils essentiels (`btrfs subvolume`, `btrfs balance`, `btrfs scrub`, etc.), l’exploitation de Btrfs peut s’avérer extrêmement puissante dans un environnement Linux moderne.