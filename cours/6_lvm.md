Je vais préparer un guide détaillé sur LVM (Logical Volume Manager) avec des explications approfondies, des commandes pratiques et des mises en situation concrètes. Ce guide couvrira :

- Un rappel des systèmes de fichiers principaux (ext2, ext3, ext4, ZFS, XFS)
- Une description détaillée de LVM et Device Mapper
- La gestion des Physical Volumes (PV), Volume Groups (VG) et Logical Volumes (LV)
- L’explication des Extensions Physiques (PE) et Extensions Logiques (LE)
- Les métadonnées associées (PVRA, VGRA, BBRA)
- La sécurisation des volumes avec des techniques comme les snapshots et les sauvegardes

Je vais structurer ce guide avec des exemples concrets et des mises en application via des commandes Linux. Je vous préviens dès que c'est prêt.

# Guide pratique du Logical Volume Manager (LVM) sous Linux

## Rappel des systèmes de fichiers

Avant de plonger dans LVM, il est utile de rappeler les principaux systèmes de fichiers utilisés sur Linux et compatibles avec LVM, ainsi que leurs caractéristiques :

- **Ext2** – Un des premiers systèmes de fichiers Linux sans journalisation. Il est simple et offre de bonnes performances en écriture (pas de surcharge due à la journalisation), ce qui le rend adapté aux supports flash (moins d’écritures) ([Ext2 vs Ext3 vs Ext4 File System: Which One Should You Use? - MiniTool Partition Wizard](https://www.partitionwizard.com/partitionmanager/ext2-vs-ext3-vs-ext4.html#:~:text=It%20is%20the%20most%20basic,of%20writes%20and%20improve%20performance)). En contrepartie, l’absence de journal accroît les risques de corruption de données en cas de crash ou de coupure de courant ([Ext2 vs Ext3 vs Ext4 File System: Which One Should You Use? - MiniTool Partition Wizard](https://www.partitionwizard.com/partitionmanager/ext2-vs-ext3-vs-ext4.html#:~:text=Well%2C%20the%20Ext2%20file%20system,the%20block%20size%20is%20wasted)).

- **Ext3** – Évolution d’Ext2 avec ajout de la *journalisation*. Le journal permet de tracer les modifications avant écriture, améliorant la fiabilité et accélérant la récupération en cas de panne ([Ext2 vs Ext3 vs Ext4 File System: Which One Should You Use? - MiniTool Partition Wizard](https://www.partitionwizard.com/partitionmanager/ext2-vs-ext3-vs-ext4.html#:~:text=Ext3%20stands%20for%20the%20third,system%20crashes%20or%20power%20failures)). Ext3 a l’avantage de permettre une mise à niveau d’Ext2 sans reformatage (le système de fichiers peut être converti en Ext3 en ajoutant un journal) ([Ext2 vs Ext3 vs Ext4 File System: Which One Should You Use? - MiniTool Partition Wizard](https://www.partitionwizard.com/partitionmanager/ext2-vs-ext3-vs-ext4.html#:~:text=Another%20significant%20advantage%20is%20that,HTree%20indexing%20for%20larger%20directories)). Cependant, Ext3 n’apporte pas d’autres optimisations majeures : il ne gère pas les *extents* (voir plus bas) et reste moins performant qu’Ext4 sur les très gros volumes ([Ext2 vs Ext3 vs Ext4 File System: Which One Should You Use? - MiniTool Partition Wizard](https://www.partitionwizard.com/partitionmanager/ext2-vs-ext3-vs-ext4.html#:~:text=However%2C%20Ext3%20lacks%20advanced%20file,dynamic%20allocation%20inode%2C%20and%20defragmentation)).

- **Ext4** – Dernière version de la famille Ext, largement utilisée par les distributions Linux actuelles. Ext4 apporte de nombreuses améliorations : support de volumes jusqu’à 1 Eio (exbioctet) et fichiers jusqu’à 16 Tio, allocation par *extents* (plages contiguës de blocs) au lieu d’une liste de blocs, ce qui améliore les performances sur les gros fichiers et réduit la fragmentation ([Ext2 vs Ext3 vs Ext4 File System: Which One Should You Use? - MiniTool Partition Wizard](https://www.partitionwizard.com/partitionmanager/ext2-vs-ext3-vs-ext4.html#:~:text=In%20addition%2C%20it%20comes%20with,with%20Ext2%20and%20Ext3%2C%20you)). Ext4 intègre une journalisation optimisée (delayed allocation, checksums de journal, timestamps étendus) et reste **compatible en lecture/écriture** avec Ext2/Ext3 ([SLES 15 SP6 | Storage Administration Guide | Overview of file systems in Linux](https://documentation.suse.com/sles/15-SP6/html/SLES-all/cha-filesystems.html#:~:text=Ext4%20also%20introduces%20several%20performance,to%20Ext2%20and%20Ext3%E2%80%94both%20file)). C’est un système de fichiers performant et stable, mais il n’offre pas les fonctionnalités avancées de type copy-on-write ou compression intégrées par les systèmes plus récents.

- **XFS** – Système de fichiers 64-bit à haute performance, initialement développé par SGI. XFS excelle dans la gestion des *gros fichiers* et des opérations parallèles d’I/O. Il est *journalisé* (journal des métadonnées) et supporte la défragmentation en ligne, ce qui le rend efficace pour les charges intensives (bases de données, vidéo, etc.) ([Understanding Linux File Systems: EXT4, XFS, BTRFS, and ZFS | WriteupDB](https://www.writeup-db.com/understanding-linux-file-systems-ext4-xfs-btrfs-and-zfs/#:~:text=Advantages)). Ses inconvénients incluent une certaine complexité d’administration et l’absence de support natif des snapshots ([Understanding Linux File Systems: EXT4, XFS, BTRFS, and ZFS | WriteupDB](https://www.writeup-db.com/understanding-linux-file-systems-ext4-xfs-btrfs-and-zfs/#:~:text=Disadvantages)). **Important** : XFS ne permet pas la réduction de la taille d’une partition une fois créée – on peut l’agrandir, mais pas la diminuer ([5.2. Shrinking logical volumes | Red Hat Product Documentation](https://docs.redhat.com/fr/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_logical_volumes/shrinking-logical-volumes_modifying-the-size-of-a-logical-volume#:~:text=Shrinking%20is%20not%20supported%20on,GFS2%20or%20XFS%20file%20system)). En cas de besoin, il faut sauvegarder les données, recréer un système de fichiers plus petit, puis restaurer les données.

- **ZFS** – Système de fichiers *et* gestionnaire de volumes développé à l’origine par Sun. Il offre des fonctionnalités avancées d’intégrité et de gestion : vérification systématique par checksum de toutes les données et métadonnées (auto-réparation en cas de corruption), snapshots et clones instantanés, compression et déduplication, et gestion intégrée du RAID et des volumes logiques ([Understanding Linux File Systems: EXT4, XFS, BTRFS, and ZFS | WriteupDB](https://www.writeup-db.com/understanding-linux-file-systems-ext4-xfs-btrfs-and-zfs/#:~:text=ZFS%20is%20a%20combined%20file,data%20integrity%20features%20and%20scalability)) ([Understanding Linux File Systems: EXT4, XFS, BTRFS, and ZFS | WriteupDB](https://www.writeup-db.com/understanding-linux-file-systems-ext4-xfs-btrfs-and-zfs/#:~:text=,efficient%20backup%20and%20recovery%20options)). ZFS est extrêmement fiable (concept de *stockage Copy-on-Write* évitant la corruption en cas de crash) et hautement scalable (conçu pour des stockages de plusieurs pétaoctets). En contrepartie, il est plus **lourd en ressources** – il requiert beaucoup de mémoire RAM pour fonctionner de façon optimale et son administration est plus complexe que celle d’Ext4 ou XFS ([Understanding Linux File Systems: EXT4, XFS, BTRFS, and ZFS | WriteupDB](https://www.writeup-db.com/understanding-linux-file-systems-ext4-xfs-btrfs-and-zfs/#:~:text=,compared%20to%20other%20file%20systems)). Sur Linux, ZFS n’est pas inclus par défaut pour des raisons de licence, mais reste disponible via des modules externes. Il convient surtout aux environnements où la priorité absolue est la **cohérence des données** (serveurs de fichiers, NAS, sauvegardes) plutôt qu’aux simples déploiements LVM classiques.

*(À noter : d’autres systèmes de fichiers existent, ex. Btrfs, mais ceux listés ci-dessus sont les plus couramment rencontrés avec LVM.)*

## Description de LVM et du Device Mapper

Le **Logical Volume Manager (LVM)** est une couche d’abstraction logiciel permettant une gestion flexible des espaces de stockage sous Linux. Au lieu d’utiliser directement des partitions fixes, LVM offre la possibilité d’agréger et de découper l’espace de plusieurs disques de manière dynamique. Concrètement, LVM permet de **regrouper des périphériques de stockage physiques** en un ou plusieurs pools de stockage, puis de créer dessus des volumes logiques de taille ajustable à la volée ([An Introduction to LVM Concepts, Terminology, and Operations | DigitalOcean](https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations#:~:text=LVM%2C%20or%20Logical%20Volume%20Management%2C,the%20combined%20space%20as%20needed)). On peut ainsi redimensionner un volume, l’étendre sur un nouveau disque, ou le déplacer, sans interrompre le service.

LVM s’appuie sur le module noyau appelé **Device Mapper**. Le Device Mapper est une infrastructure du noyau Linux qui assure le mappage de périphériques blocs physiques vers des périphériques virtuels de plus haut niveau ([Device mapper - Wikipedia](https://en.wikipedia.org/wiki/Device_mapper#:~:text=The%20device%20mapper%20is%20a,encryption%2C%20and%20offers%20additional%20features)). Il constitue la fondation de LVM (mais aussi des RAID logiciels Linux et du chiffrement dm-crypt) en offrant un système générique de translation des entrées-sorties. En d’autres termes, LVM utilise le Device Mapper pour présenter aux applications des *volumes logiques* virtuels, lesquels correspondent en coulisse à des zones de un ou plusieurs disques physiques. Grâce à cette couche, les volumes peuvent être manipulés (agrégés, découpés, redimensionnés) indépendamment de la disposition physique réelle des données.

**Pourquoi utiliser LVM ?** Parce qu’il apporte une grande flexibilité d’administration et un meilleur contrôle sur les ressources de stockage. Parmi ses atouts : la possibilité de redimensionner à chaud une partition logique, d’additionner simplement de nouveaux disques à un espace existant, de *prendre des instantanés* (snapshots) pour la sauvegarde, ou encore de configurer du mirroring ou du striping (répartition sur plusieurs disques) pour améliorer la performance ou la redondance ([An Introduction to LVM Concepts, Terminology, and Operations | DigitalOcean](https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations#:~:text=The%20main%20advantages%20of%20LVM,like%20snapshotting%2C%20striping%2C%20and%20mirroring)). Tout cela se fait de manière transparente pour le système de fichiers et les applications, qui continuent d’accéder aux volumes logiques comme s’il s’agissait de disques « classiques ». En résumé, LVM introduit une couche de virtualisation du stockage qui facilite grandement la vie de l’administrateur système.

 ([Logical Volume Manager](https://henzelmoras.github.io/posts/linux-sys-admin/advanced-storage-managment/logical-volume-manager/)) *Illustration de l’organisation LVM : les *Physical Volumes* (jaune) ici sont quatre partitions `/dev/sdb1`, `/dev/sdb2`, `/dev/sdc1` et `/dev/sdc2` sur deux disques durs. Elles sont agrégées dans un *Volume Group* nommé `primary_vg` (bleu). Depuis ce groupe, on a créé deux *Logical Volumes* (rouge) – l’un monté sur `/home` avec un système de fichiers ext3, l’autre monté sur `/data` en XFS (parties violet) ([Logical Volume Manager](https://henzelmoras.github.io/posts/linux-sys-admin/advanced-storage-managment/logical-volume-manager/#:~:text=One%20or%20more%20physical%20volumes,formatted%20to%20contain%20mountable%20filesystems)) ([Logical Volume Manager](https://henzelmoras.github.io/posts/linux-sys-admin/advanced-storage-managment/logical-volume-manager/#:~:text=LVM%20has%20better%20scalability%20than,logical%20volume%20at%20any%20time)).*

## Gestion des Physical Volumes (PV), Volume Groups (VG) et Logical Volumes (LV)

LVM introduit trois abstractions principales : le volume physique, le groupe de volumes, et le volume logique. Cette section décrit leur rôle et les commandes Linux pour les manipuler.

### Physical Volume (PV) – Volume Physique

Un **Physical Volume** est la brique de base de LVM. Il s’agit d’un support de stockage physique initialisé pour être utilisé par LVM. Concrètement, un PV peut être un disque entier (`/dev/sda`, `/dev/sdb`…), ou bien une partition d’un disque (`/dev/sda1`, `/dev/sdb2`…), ou même un volume RAID ou un disque virtuel. LVM va écrire une en-tête (*header*) sur ce périphérique pour le marquer comme volume physique géré ([An Introduction to LVM Concepts, Terminology, and Operations | DigitalOcean](https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations#:~:text=,to%20allocate%20it%20for%20management)). 

Créer un volume physique revient à initialiser un disque ou une partition pour LVM. Sous Linux, la commande `pvcreate` permet d’effectuer cette opération. Par exemple, si l’on ajoute deux nouveaux disques durs destinés à LVM, on peut les initialiser ainsi :

```bash
# pvcreate /dev/sdb /dev/sdc
  Physical volume "/dev/sdb" successfully created.
  Physical volume "/dev/sdc" successfully created.
```

Cette commande écrit les métadonnées LVM nécessaires sur les deux disques. Il est possible de vérifier la prise en compte des PV avec des commandes de listing : 

- `pvs` affiche un résumé des PV (identifiant, volume group associé, taille, espace libre, etc.) ;
- `pvdisplay` donne des détails complets sur les volumes physiques (y compris leur UUID LVM, taille d’extent, etc.).

Par exemple, `sudo pvs` après notre création pourrait lister quelque chose comme :

```
PV         VG      Fmt  Attr PSize   PFree  
/dev/sdb   (inactif) lvm2 --- 200.00g 200.00g
/dev/sdc   (inactif) lvm2 --- 100.00g 100.00g
``` 

Ici, les PV sont indiqués « inactifs » car ils ne font pas encore partie d’un groupe de volumes (champ VG vide). La taille des disques (`PSize`) et l’espace libre (`PFree`) y sont indiqués.

*Remarque :* Si vous utilisez une partition de disque comme PV, assurez-vous que le type de partition est défini sur « Linux LVM » (code 8e) dans la table de partition (via `fdisk` ou `gdisk`). Sur les distributions récentes utilisant GPT, le type de GUID doit être mis à `Linux LVM` également. Cela permet à l’OS et aux outils de reconnaître l’espace comme appartenant à LVM.

### Volume Group (VG) – Groupe de Volumes

Un **Volume Group** est un pool de stockage formé en agrégeant un ou plusieurs PV. C’est la deuxième couche d’abstraction de LVM. Le VG combine la capacité de tous les volumes physiques qui lui sont affectés en un seul espace unifié à partir duquel on pourra allouer des volumes logiques ([An Introduction to LVM Concepts, Terminology, and Operations | DigitalOcean](https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations#:~:text=,of%20the%20component%20physical%20volumes)). On peut voir le VG comme un **réservoir de stockage** flexible : si on lui ajoute un PV (par exemple un nouveau disque), l’espace total disponible augmente ; inversement, on peut retirer un PV d’un VG (à condition qu’il ne contienne pas de données actives, voir commande `pvmove` pour déplacer des données au préalable).

Dans notre exemple, pour utiliser ensemble les deux disques initialisés précédemment, on crée un groupe de volumes. La commande de base est `vgcreate` :

```bash
# vgcreate vg_data /dev/sdb /dev/sdc
  Volume group "vg_data" successfully created
```

Ici, on crée un VG nommé `vg_data` en y incorporant les PV `/dev/sdb` et `/dev/sdc`. On peut choisir n’importe quel nom (respectant la limite de 128 caractères). Désormais, le système considère que `vg_data` est un espace de **300 Go** (200+100) prêt à être découpé en volumes logiques.

Pour vérifier, la commande `vgs` donne un résumé des groupes de volumes, et `vgdisplay` fournit des informations détaillées. Par exemple :

```
# vgs
VG      #PV #LV #SN Attr   VSize   VFree  
vg_data   2   0   0 wz--n- 300.00g 300.00g
```

Ce résultat indique que `vg_data` contient 2 PV, pour le moment 0 LV, et 300 Go dont 300 Go libres (VFree). L’attribut `wz--n-` indique que le VG est activé en lecture/écriture et non verouillé, etc. (les flags complets sont détaillés dans la doc LVM).

On peut à tout moment **étendre** un VG avec un nouveau disque : par exemple `vgextend vg_data /dev/sdd` ajouterait le PV `/dev/sdd` au groupe `vg_data`. De même, pour retirer un PV (après avoir migré ses données), on utiliserait `vgreduce`. Ces opérations permettent d’ajuster la taille du pool de stockage en fonction des besoins, de façon transparente.

### Logical Volume (LV) – Volume Logique

Un **Logical Volume** est une partition logique allouée à partir de l’espace d’un VG. C’est l’équivalent d’une partition « virtuelle » que l’on peut formater avec un système de fichiers et monter dans le système. Les LVs sont la couche qu’utilisent directement les utilisateurs et applications (on y crée les systèmes de fichiers, on les monte sur des points de montage, etc.) ([An Introduction to LVM Concepts, Terminology, and Operations | DigitalOcean](https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations#:~:text=,and%20applications%20will%20interact%20with)). La flexibilité de LVM vient principalement de la gestion des LVs : on peut en créer, supprimer, redimensionner à la volée, sans se soucier de la position physique réelle des données sur les disques.

Pour créer un LV, on utilise la commande `lvcreate`. Par exemple, pour créer un volume logique de 100 Go dans le VG `vg_data` :

```bash
# lvcreate -L 100G -n lv_backup vg_data
  Logical volume "lv_backup" created.
```

Ici on alloue un LV nommé `lv_backup` de taille 100 Gio à partir du VG `vg_data`. LVM se charge de trouver *où* placer ce volume sur les disques (il va allouer l’équivalent de 100 Go en extents physiques, voir section suivante). À ce stade, un périphérique `/dev/vg_data/lv_backup` est apparu. On peut le vérifier avec `lvs` (liste des volumes logiques) ou `lvdisplay` :

```
# lvs
LV        VG      Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
lv_backup vg_data -wi-a----- 100.00g                                                    
```

Le statut `-wi-a-----` indique un volume logique standard (*w*: writable, *i*: non verrouillé, *a*: actif). `LSize` confirme la taille. On voit qu’il n’a pas de pool (ce n’est pas un volume thin par ex) ni d’origine (ce n’est pas un snapshot).

À ce stade, le volume logique est un espace brut. Pour l’utiliser, il faut le formater avec un système de fichiers de votre choix (ext4, xfs, etc.), puis le monter dans l’arborescence. Par exemple :

```bash
# mkfs.ext4 /dev/vg_data/lv_backup   # Création d'un système de fichiers ext4 sur le LV
# mkdir -p /mnt/backup
# mount /dev/vg_data/lv_backup /mnt/backup
```

On dispose maintenant d’un point de montage `/mnt/backup` de 100 Go prêt à l’emploi, qui peut s’étendre sur les deux disques physiques. Si plus tard on manque d’espace, on pourra *agrandir* ce volume logique (voir plus bas la gestion des extents) et ensuite étendre le système de fichiers en ligne. Inversement, on pourrait le réduire (s’il s’agit d’un système de fichiers ext4, en le démontant et en utilisant `resize2fs` puis `lvreduce` – attention à toujours réduire le FS avant le LV pour éviter la perte de données).

Les volumes logiques supportent d’autres fonctionnalités via LVM, comme la création de **volumes en mirroir** (dupliqués sur deux PV distincts), de volumes **stripés** (répartition type RAID0 pour augmenter le débit), ou de **volumes Thin Provisioning** (allocation à la volée). Ces usages avancés sortent du cadre de ce guide, mais reposent sur les mêmes commandes `lvcreate` avec des options spécifiques (`-m` pour mirroring, `-i` pour striping, `-T` pour thin, etc.).

**Récapitulatif** : un ou plusieurs *Physical Volumes* (PV) forment un *Volume Group* (VG), qui constitue un pool de capacité. Dans ce pool, on crée des *Logical Volumes* (LV) qui seront formatés et utilisés comme des partitions classiques.  ([An Introduction to LVM Concepts, Terminology, and Operations | DigitalOcean](https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations#:~:text=,of%20the%20component%20physical%20volumes)) ([An Introduction to LVM Concepts, Terminology, and Operations | DigitalOcean](https://www.digitalocean.com/community/tutorials/an-introduction-to-lvm-concepts-terminology-and-operations#:~:text=,and%20applications%20will%20interact%20with))Les outils LVM (`pv*`, `vg*`, `lv*`) permettent de gérer ces trois niveaux simplement.

## Extensions Physiques (PE) et Extensions Logiques (LE)

Lors de l’initialisation d’un volume group, LVM segmente l’espace en unités de taille fixe appelées **Physical Extents (PE)**. De même, chaque volume logique est découpé en **Logical Extents (LE)** de cette même taille. Par défaut, la taille d’un extent est de 4 MiB (valeur configurable à la création du VG avec l’option `-s`) ([Chapter 3. Managing LVM volume groups | Red Hat Product Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_logical_volumes/managing-lvm-volume-groups_configuring-and-managing-logical-volumes#:~:text=Extents%20are%20the%20smallest%20units,extents%20have%20the%20same%20size)). En interne, LVM n’alloue l’espace que par ces unités entières d’extent.

La correspondance entre extents physiques et logiques est *1 pour 1* : chaque Logical Extent d’un LV est mappé sur un Physical Extent d’un PV appartenant au VG ([Chapter 3. Managing LVM volume groups | Red Hat Product Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/9/html/configuring_and_managing_logical_volumes/managing-lvm-volume-groups_configuring-and-managing-logical-volumes#:~:text=When%20you%20create%20a%20logical,LV%20of%20the%20requested%20size)). En d’autres termes, si un volume logique fait 100 MiB et que l’extent est de 4 MiB, le LV sera composé de 25 extents logiques, chacun associé à un extent physique sur l’un des disques du groupe.

**Pourquoi ces extents ?** Cela facilite grandement la gestion : le système n’a pas à suivre chaque bloc de 4Ko individuellement, il manipule des *groupes* de blocs. Surtout, cela permet de redimensionner ou déplacer les volumes par morceaux de taille connue. Par exemple, pour étendre un LV de 4 MiB, LVM ajoutera simplement un extent logique supplémentaire (qui sera associé à un extent physique libre quelque part dans le VG). Si le VG n’a plus d’extents libres, on devra d’abord l’étendre en ajoutant un nouveau PV ou en libérant de l’espace.

La taille des extents a une influence : un extent plus grand (ex: 64 MiB) réduit le nombre total d’extents à gérer pour de très gros volumes, mais peut entraîner un certain gâchis d’espace si vos volumes ne sont pas un multiple de cette taille. Inversement, un extent très petit (ex: 1 MiB) permet une granularité fine mais augmente le nombre d’entrées de mapping à maintenir. La valeur par défaut de 4 MiB est un équilibre convenant à la majorité des cas, mais pour des stockages énormes (plusieurs dizaines de Tera), on peut augmenter la taille des extents afin d’éviter de dépasser les limites (le nombre maximal d’extents par VG/LV est d’environ 65 000 par PV en LVM2). 

L’important à retenir est que **l’unité minimale d’allocation LVM est l’extent** : toute création/extension de volume allouera un multiple d’extents, et tout espace libre est compté en nombre d’extents disponibles dans le VG.

*(Pour visualiser : si l’on considère un LV comme un puzzle, les pièces seraient les extents logiques. Ces pièces viennent d’une réserve de pièces (extents physiques) disponible dans le VG. Chaque nouvelle pièce ajoutée au puzzle provient de la boîte commune qu’est le VG.)*

## Métadonnées de LVM : PVRA, VGRA, BBRA

LVM stocke des métadonnées sur les disques pour garder la trace de la configuration des volumes. On distingue plusieurs zones de métadonnées importantes, présentes généralement au début des PV :

- **PVRA (Physical Volume Reserved Area)** – Il s’agit de la zone réservée du volume physique qui contient les métadonnées propres au PV lui-même (identifiant unique du PV, numéro de version de l’entête, taille du PV, etc.) ([LVM - Logical Volume Manager Cheat Sheet by Alasta - Download free from Cheatography - Cheatography.com: Cheat Sheets For Every Occasion](https://cheatography.com/alasta/cheat-sheets/lvm-logical-volume-manager/#:~:text=PVRA%20%3A%20Physical%20Volume%20Reserved,Area)). C’est grâce à la PVRA que LVM peut reconnaître un disque comme « Physical Volume » et lire ses informations de base.

- **VGRA (Volume Group Reserved Area)** – Cette zone contient les métadonnées du groupe de volumes auquel appartient le PV, notamment la description du VG et la table des volumes logiques et des extents qui s’y trouvent ([LVM - Logical Volume Manager Cheat Sheet by Alasta - Download free from Cheatography - Cheatography.com: Cheat Sheets For Every Occasion](https://cheatography.com/alasta/cheat-sheets/lvm-logical-volume-manager/#:~:text=VGRA%20%3A%20Volume%20Group%20Reserve,Area)). En fait, chaque PV d’un même VG stocke une copie des métadonnées du VG (nom du VG, liste des PV membres avec leurs tailles, et liste des LV avec l’allocation de leurs extents). Ainsi, si un des disques du VG venait à tomber en panne, on pourrait potentiellement reconstruire la configuration en lisant les VGRA des autres disques.

- **BBRA (Bad Block Relocation Area)** – Zone réservée pour la gestion de la réallocation des blocs défectueux ([LVM - Logical Volume Manager Cheat Sheet by Alasta - Download free from Cheatography - Cheatography.com: Cheat Sheets For Every Occasion](https://cheatography.com/alasta/cheat-sheets/lvm-logical-volume-manager/#:~:text=BBRA%20%3A%20Bad%20Block%20Relocation,Area)). Historiquement, LVM pouvait prendre en charge la relocalisation de blocs défaillants détectés sur le disque (un peu à la manière des secteurs remplacés). Cependant, cette fonctionnalité est aujourd’hui **obsolète** : les disques modernes intègrent eux-mêmes des mécanismes de remplacement des secteurs défectueux au niveau matériel. D’ailleurs, sur certaines implémentations (ex. LVM HP-UX), le bad block relocation a été abandonné depuis des versions récentes et uniquement conservé pour compatibilité ascendante ([PPT - HP-UX Swap and Dump Unleashed By Unix/Linux Apprentice with 26 Years of Experience PowerPoint Presentation - ID:8911029](https://www.slideserve.com/shuman/hp-ux-swap-and-dump-unleashed-by-unix-linux-apprentice-with-26-years-of-experience-powerpoint-ppt-presentation#:~:text=40.%20HP,n%20dump2%20%2Fdev%2Fvgdump)). En général, sous LVM2 Linux, on ne l’utilise pas (les paramètres liés aux bad blocks sont désactivés par défaut lors de `pvcreate` à moins de les spécifier). 

En plus de ces zones, LVM maintient en mémoire (et sur disque dans `/etc/lvm`) des copies de sauvegarde de sa configuration (voir section suivante). Les métadonnées LVM sont cruciales : si elles sont corrompues ou perdues, le système ne saura plus reconstituer l’assemblage des PV/VG/LV. C’est pourquoi LVM duplique ces informations (VGRA recopiée sur tous les PV du VG) et offre des outils de backup.

**Emplacement des métadonnées sur le disque :** Sur un PV, l’entête LVM (PVRA + VGRA + éventuellement BBRA) occupe généralement le début du disque (quelques Mo). Les données utilisateur (extents disponibles pour les LV) commencent après cet espace réservé. Vous pouvez voir la taille de ces métadonnées via `pvdisplay -m` qui indique à quel extent débute l’« area libre » de données.

## Sécurisation des volumes LVM : snapshots, sauvegardes et restauration

La flexibilité de LVM va de pair avec des outils pour sécuriser les données et la configuration. Voici quelques techniques pour protéger vos volumes logiques et prévenir la perte de données.

### Les snapshots LVM (instantanés)

Un **snapshot** LVM est un volume logique spécial qui fige l’état d’un autre volume logique à un instant *T*. C’est en quelque sorte une photo instantanée du volume original, qui permettra plus tard de le lire tel qu’il était au moment du snapshot, même si le volume original est modifié entre temps. LVM implémente cela via la technique du *copy-on-write* : lorsque le volume d’origine subit des modifications après la prise du snapshot, les anciennes données *avant modification* sont copiées dans le volume snapshot, de sorte de pouvoir reconstituer l’état antérieur à tout moment ([3.3.6. Snapshot Volumes | Red Hat Product Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/snapshot_volumes#:~:text=The%20LVM%20snapshot%20feature%20provides,the%20state%20of%20the%20device)) ([3.3.6. Snapshot Volumes | Red Hat Product Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/snapshot_volumes#:~:text=Note)). Tant qu’une zone du volume original n’a pas été modifiée, le snapshot n’occupe pas d’espace pour cette zone (il référence simplement les mêmes blocs). 

L’avantage est qu’on peut créer un snapshot **sans interruption de service** sur le volume original ([3.3.6. Snapshot Volumes | Red Hat Product Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/snapshot_volumes#:~:text=The%20LVM%20snapshot%20feature%20provides,the%20state%20of%20the%20device)). Les écritures continues sur le LV original ne sont pas bloquées ; seules la première écriture sur un bloc donné entraîne une copie du bloc original vers le snapshot (ce qui peut induire une légère dégradation de performance pendant l’opération de copie).

Pour créer un snapshot, on utilise la commande `lvcreate` avec l’option `-s`. Par exemple, supposons un volume logique `/dev/vg_data/lv_backup` de 100 Go que l’on souhaite snapshotter :

```bash
# lvcreate -L 5G -s -n snap_backup /dev/vg_data/lv_backup
  Logical volume "snap_backup" created.
```

Ici on a créé un LV snapshot de 5 Go nommé `snap_backup`. Ce snapshot est un volume logique à part entière (visible dans `lvs` avec l’attribut `s`) qui va contenir les modifications ultérieures. La taille de 5 Go allouée correspond à l’espace maximal de changements qu’on pense devoir conserver. **Important** : si le volume snapshot se remplit (parce qu’il y a eu plus de 5 Go de modifications sur le LV original depuis la capture), alors le snapshot sera marqué comme *invalidé* (il devient inutilisable car incomplet). Il faut donc dimensionner le snapshot en fonction de la durée pendant laquelle on compte le garder et du volume de données modifiées dans cet intervalle – en pratique, on prévoit souvent 10% à 20% de la taille du volume original, selon l’usage ([3.3.6. Snapshot Volumes | Red Hat Product Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/snapshot_volumes#:~:text=Because%20a%20snapshot%20copies%20only,sufficient%20to%20maintain%20the%20snapshot)). On peut monitorer l’usage avec `lvs` (colonne Data%) et étendre le snapshot via `lvextend` s’il menace d’être plein.

Une fois le snapshot créé, on peut l’utiliser comme une copie figée du volume : typiquement, on va le monter ailleurs pour faire une sauvegarde sans geler l’application. Exemple :

```bash
# mkdir -p /mnt/snap_backup
# mount /dev/vg_data/snap_backup /mnt/snap_backup   # monter le snapshot en lecture seule
```

On dispose alors d’une vue lecture-seule (par défaut) du système de fichiers tel qu’il était à la création du snapshot. On peut copier ces données sur un support de sauvegarde, ou opérer des tests sans impacter les données live.

Après usage, le snapshot peut être démonté et supprimé avec `lvremove` comme un volume normal :

```bash
# umount /mnt/snap_backup
# lvremove /dev/vg_data/snap_backup
```

*(Confirmer avec “y” car lvremove détruira l’état snapshot.)*

**Restauration à partir d’un snapshot :** LVM offre la possibilité de *revenir* à l’état du snapshot en cas de besoin, via la fusion du snapshot. Concrètement, si vous souhaitez annuler tous les changements effectués sur le volume original depuis le snapshot, vous pouvez utiliser `lvconvert --merge vg_data/snap_backup`. Cette commande va planifier la fusion du snapshot dans le volume original. Il faut démonter le volume original puis activer la fusion (le processus exact peut varier selon les versions de LVM). Au prochain *activate* du LV (par exemple lors d’un reboot ou via `lvchange -ay`), le volume original sera restauré tel qu’au moment du snapshot. Cette technique équivaut à un rollback complet. **Attention** : le snapshot sera supprimé après la fusion, et toutes les données modifiées après sa création seront perdues (puisque l’on est revenu en arrière). Assurez-vous donc de ne lancer cette fusion qu’en toute connaissance de cause. 

Dans bien des cas, on n’a pas besoin de fusionner automatiquement : il suffit d’utiliser le snapshot pour récupérer quelques fichiers perdus. Par exemple si un utilisateur a supprimé un fichier important par erreur, il suffit d’aller monter le snapshot, récupérer ce fichier et le remettre en place sur le volume courant. C’est plus rapide et plus simple que de restaurer tout le volume.

En résumé, les **snapshots LVM** sont extrêmement utiles pour faire des sauvegardes à chaud ou tester des modifications sans risque. Gardez à l’esprit qu’ils consomment de l’espace uniquement en proportion des changements effectués après leur création ([How to Take 'Snapshot of Logical Volume and Restore' in LVM - Part III](https://www.tecmint.com/take-snapshot-of-logical-volume-and-restore-in-lvm/#:~:text=LVM%20Snapshots%20are%20space,snapshot%20we%20can%20use%20lvreduce)). Ils ne remplacent pas une vraie sauvegarde (si le disque sous-jacent tombe en panne, le snapshot sera perdu avec le volume original), mais facilitent la prise de copies de cohérence à un instant T.

### Sauvegarde et restauration des métadonnées LVM

Outre la protection des données, il est crucial de sauvegarder la configuration LVM elle-même (les tables PV/VG/LV). Sans ces métadonnées, une reconstruction du volume group peut s’avérer compliquée. Heureusement, LVM prévoit un mécanisme de backup automatique : à chaque modification (création ou suppression de VG/LV, extension, etc.), un fichier de backup de la config est généré (dans `/etc/lvm/backup`) et une archive horodatée est conservée (dans `/etc/lvm/archive`) ([3.3. Logical Volume Backup | Red Hat Product Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/logical_volume_manager_administration/backup#:~:text=Metadata%20backups%20and%20archives%20are,directory%20in%20the%20backup)). Il est recommandé d’inclure le dossier `/etc/lvm` dans les sauvegardes système quotidiennes ([3.3. Logical Volume Backup | Red Hat Product Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/logical_volume_manager_administration/backup#:~:text=Metadata%20backups%20and%20archives%20are,directory%20in%20the%20backup)).

Pour une sauvegarde manuelle explicite, utilisez la commande `vgcfgbackup`. Par exemple :

```bash
# vgcfgbackup -f /root/save_vg_data.cfg vg_data
  Volume group "vg_data" successfully backed up.
```

Cette commande extrait les métadonnées du VG `vg_data` et les enregistre dans le fichier spécifié. Si aucun fichier n’est précisé, la sauvegarde est placée dans `/etc/lvm/backup/vg_data`. Ce fichier texte contient toutes les informations pour recréer le VG et ses LVs (mais pas les données des fichiers – seulement la structure).

En cas de problème (par exemple : perte d’un disque, corruption des métadonnées sur un PV, erreur humaine ayant supprimé un VG par mégarde), on peut restaurer la configuration LVM via `vgcfgrestore`. Par exemple :

```bash
# vgcfgrestore -f /root/save_vg_data.cfg vg_data
  Restored volume group vg_data
```

Cette commande va réécrire les métadonnées contenues dans le fichier de sauvegarde sur les PV concernés (ceux listés dans la conf). Il faut s’assurer que les PV originels sont bien présents (ou remplacés par des équivalents de même taille si on reconstruit après un crash disque). Grâce à ce mécanisme, on peut récupérer la définition d’un VG/LV même si la configuration actuelle a été perdue ou altérée ([3.3. Logical Volume Backup | Red Hat Product Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/logical_volume_manager_administration/backup#:~:text=You%20can%20manually%20back%20up,described%20in%20%20204%20Section)). 

**Exemple d’utilisation pratique :** Supposons que vous ayez étendu un LV par erreur et que vous souhaitiez revenir en arrière. Si vous avez une archive LVM datant d’avant l’opération (dans `/etc/lvm/archive/`), vous pourriez tenter un `vgcfgrestore` pour restaurer l’état antérieur de la config (il faudra peut-être réduire le LV pour correspondre). De même, après un crash, si un PV est manquant, vous pouvez éditer le fichier de backup pour supprimer ce PV et restaurer la config sur les PV restants – afin de récupérer un VG fonctionnel (vos LVs seront peut-être incomplets, mais au moins reconnus pour tenter une récupération de données).

Il est bon de noter que `vgcfgrestore` permet de lister les archives disponibles avec l’option `-l` (elle affichera les différents snapshots de config disponibles pour un VG donné, avec date). Conservez toujours vos fichiers de backup LVM en lieu sûr, surtout si vous manipulez des volumes critiques.

### Sauvegarde des données des volumes logiques

Enfin, comme pour toute donnée, **LVM n’exempte pas d’une stratégie de sauvegarde** régulière des fichiers eux-mêmes. Vous pouvez utiliser les snapshots pour faciliter ces sauvegardes à chaud : par exemple, prendre un snapshot d’un LV, monter ce snapshot sur un répertoire temporaire et copier son contenu (sur bande, sur un autre serveur, etc.), puis supprimer le snapshot. De cette façon, vous obtenez une sauvegarde cohérente sans interrompre l’activité sur le volume principal.  

En cas de perte totale (ex: panne simultanée de plusieurs disques d’un VG sans RAID, ou erreur de manipulation détruisant un LV), la restauration se fera à partir des sauvegardes externes des fichiers. Les volumes LVM sont accessibles comme des fichiers de périphérique classiques, donc on peut aussi imaginer les sauvegarder via `dd` (pour une image brute) ou utiliser des outils comme *rsync* au niveau système de fichiers – ces méthodes sortent du cadre de LVM lui-même.

Pour résumer cette section, LVM fournit des fonctionnalités pour **sécuriser vos volumes** : les *snapshots* offrent des points de récupération à court terme et facilitent les sauvegardes à l’instantané, tandis que les commandes de backup de métadonnées (`vgcfgbackup/vgcfgrestore`) protègent la configuration du volume en elle-même. Combinées à des sauvegardes externes régulières des données, ces techniques vous permettront de tirer pleinement parti de LVM en toute sérénité. ([3.3.6. Snapshot Volumes | Red Hat Product Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/6/html/logical_volume_manager_administration/snapshot_volumes#:~:text=The%20LVM%20snapshot%20feature%20provides,the%20state%20of%20the%20device)) ([3.3. Logical Volume Backup | Red Hat Product Documentation](https://docs.redhat.com/en/documentation/red_hat_enterprise_linux/7/html/logical_volume_manager_administration/backup#:~:text=You%20can%20manually%20back%20up,described%20in%20%20204%20Section))

