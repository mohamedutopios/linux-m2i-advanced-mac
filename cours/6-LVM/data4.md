Dans le contexte de LVM (Logical Volume Manager), on distingue plusieurs zones de métadonnées sur chaque *Physical Volume* (PV). La documentation et certains supports de formation les désignent souvent par des noms du type **PVRA**, **VGRA**, voire **BBRA**. Ces acronymes peuvent varier selon les versions ou les éditeurs (certaines viennent de l’historique d’HP-UX LVM ou d’autres implémentations), mais l’idée générale reste la même : il s’agit d’espaces réservés sur le disque (ou la partition) pour stocker les informations critiques sur le PV lui-même, le Volume Group, et éventuellement d’autres données (comme un bloc de boot ou la gestion des blocs défectueux).

Voici un aperçu de ce que recouvrent ces différentes zones :

---

## 1. PVRA (Physical Volume Reserved Area)

1. **Rôle principal**  
   - La *Physical Volume Reserved Area* correspond à la zone de métadonnées réservée au tout début (ou parfois la fin) d’un disque ou d’une partition lorsqu’on en fait un Physical Volume.  
   - Elle contient notamment :
     - Le *label* LVM (signature qui identifie ce disque comme un PV).  
     - Les informations de base sur le PV : son UUID, la taille de ses extents, etc.

2. **Localisation et taille**  
   - Généralement, il s’agit de quelques secteurs ou blocs réservés, typiquement au début du PV (lorsque vous faites un `pvcreate`, LVM y inscrit sa signature et des informations de base).  
   - Cette zone est minuscule par rapport au disque (quelques kilo-octets), mais critique car elle permet de reconnaître le disque comme un PV et d’y accéder correctement.

3. **Historique et nommage**  
   - On parle parfois de “PV label” ou “entête LVM” (LVM header) dans la documentation plus récente.  
   - Sur des systèmes historiques (HP-UX LVM, etc.), on utilisait le terme “Physical Volume Reserved Area” pour englober toutes les métadonnées du disque en lien avec le statut de PV.

---

## 2. VGRA (Volume Group Reserved Area)

1. **Rôle principal**  
   - La *Volume Group Reserved Area* est la zone de métadonnées où sont stockées les informations relatives à la configuration du *Volume Group* (VG).  
   - Concrètement, c’est là que LVM enregistre la liste des Logical Volumes, leur taille, leur mapping vers les Physical Extents, etc.  
   - Elle peut également contenir des informations de “journalisation” pour garder une cohérence en cas de panne.

2. **Copie redondante**  
   - Quand vous avez plusieurs disques dans un même VG, LVM peut conserver plusieurs copies des métadonnées du VG (une sur chaque PV). Cela permet de survivre à la perte d’un disque unique si ces métadonnées sont dupliquées.  
   - Le nombre de copies dépend de la configuration (paramètre `metadata copies`).

3. **Flexibilité d’emplacement**  
   - Selon la version de LVM et la configuration, cette zone peut être positionnée au début ou à la fin du PV.  
   - Par défaut, LVM place souvent la métadonnée (VG metadata) vers le début, mais on peut spécifier `--metadataarea` ou `--metadataignore` pour changer cette organisation.

---

## 3. BBRA (Boot Block ou Bad Block Reserved Area)

Cet acronyme est moins standard dans la documentation LVM officielle, mais on peut le rencontrer dans des documentations plus anciennes ou spécifiques à certains OS (HP-UX, AIX, etc.) ou formations. Deux interprétations principales reviennent :

1. **Boot Block Reserved Area**  
   - Sur certaines implémentations, c’est une zone réservée pour stocker des informations de boot ou un chargeur d’amorçage (en conjonction avec LVM).  
   - Dans le cas de boot direct sur un volume LVM (peu fréquent sans /boot séparé), il peut exister un espace réservé pour le chargeur ou pour des informations nécessaires à l’amorçage.

2. **Bad Block Relocation Area**  
   - Sur de vieux systèmes ou anciens disques, on réservait parfois une zone pour “relocaliser” les blocs défectueux (bad blocks).  
   - LVM ou l’OS pouvaient marquer ces blocs comme inutilisables et utiliser cette zone pour remapper ces blocs ou stocker la table des blocs défectueux.  
   - Aujourd’hui, les disques modernes (SSD ou HDD avec firmware interne) gèrent souvent eux-mêmes la remap de secteurs défaillants, rendant cette fonctionnalité moins cruciale côté LVM.

Selon la distribution Linux ou la formation, vous verrez parfois **BBRA** mentionné en complément de **PVRA** et **VGRA** pour faire référence à une autre zone de stockage réservée. Dans les faits, sous Linux, la gestion concrète de ces zones est souvent encapsulée par :

- Le *label* LVM (PV label) et la zone de métadonnées LVM (VG metadata area).
- Les éventuelles superblocks d’autres formats (mdadm, etc.) si c’est combiné avec du RAID logiciel.

---

## 4. Comment tout cela se traduit concrètement

- Quand vous exécutez un `pvcreate /dev/sdb` :  
  1. LVM écrit le PV label + la PVRA en début (ou fin) de `/dev/sdb`.  
  2. Il réserve également un espace pour stocker la VGRA (même si vous n’avez pas encore créé le Volume Group).  

- Quand vous exécutez un `vgcreate myVG /dev/sdb` :  
  1. LVM initialise la partie “Volume Group metadata” (VGRA) dans l’espace réservé.  
  2. Il y place des informations sur le nouveau VG (nom, UUID, etc.).  

- Si la notion de **BBRA** est gérée sur votre OS ou distribution (peu fréquent désormais), elle sera aussi mise en place lors du `pvcreate` ou via des outils spécifiques.

En pratique, la plupart des utilisateurs LVM n’ont pas à manipuler directement ces trois zones :  
- On sait qu’un **PV** contient un label + métadonnées au début (et parfois en fin).  
- On sait que la **VG metadata** (qui décrit LV, PV, etc.) est stockée dans une zone spéciale.  
- Le reste du disque est découpé en *Physical Extents* (PE) pour y placer les données utilisateur.  

---

## 5. En résumé

- **PVRA (Physical Volume Reserved Area)**  
  Désigne le bloc de métadonnées marquant un disque/partition comme Physical Volume et contenant les infos d’identification de base (signature LVM, UUID, taille d’extent, etc.).

- **VGRA (Volume Group Reserved Area)**  
  Zone de métadonnées qui décrit la configuration complète du Volume Group : liste des LV, attributs, mapping, journal, etc.  
  Peut être répliquée sur plusieurs PV du même VG pour la résilience.

- **BBRA (Boot Block/Bad Block Reserved Area)**  
  Un espace qui *pouvait* être dédié à l’amorçage ou à la relocalisation de blocs défectueux, surtout sur des implémentations LVM plus anciennes ou propres à certains UNIX. Sous Linux moderne, cette notion est rarement mise en avant ou utilisée.

Au final, ces différentes zones assurent qu’un **Physical Volume** est correctement identifié et qu’il embarque toutes les informations nécessaires pour reconstruire la carte des *Logical Volumes* et du *Volume Group* auquel il appartient, même en cas de perte partielle ou de panne.