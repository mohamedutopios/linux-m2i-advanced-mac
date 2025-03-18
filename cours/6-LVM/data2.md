**Description détaillée de LVM (Logical Volume Manager) et Device Mapper sous Linux**

---

## 1. Contexte et définitions générales

### 1.1 Qu’est-ce que LVM ?
Le *Logical Volume Manager (LVM)* est un système de gestion de volumes logiques présent sur les systèmes Linux. Au lieu d’utiliser directement des partitions fixes sur un disque dur (ou des ensembles de disques), LVM permet de créer et d’administrer des volumes logiques plus flexibles, abstraits du matériel sous-jacent. Ainsi, on peut redimensionner, déplacer ou fusionner des volumes avec plus de souplesse qu’avec des partitions classiques.

### 1.2 Qu’est-ce que le Device Mapper ?
Le *Device Mapper* est un composant du noyau Linux (une couche d’abstraction) qui sert de fondation pour créer et gérer divers dispositifs de stockage virtuels. Il fournit un mécanisme générique de “mapping” entre des périphériques bloc virtuels et des périphériques bloc physiques réels. Les outils de LVM s’appuient sur ce Device Mapper pour créer leurs volumes logiques.

En d’autres termes, **le Device Mapper** est la brique de base au niveau du noyau qui permet de :
1. Définir des tables de mapping pour répartir des blocs (secteurs, clusters) réels sur un ou plusieurs périphériques virtuels (ex. un volume logique).
2. Mettre en place des fonctionnalités comme la création de *snapshots*, le chiffrement au niveau bloc (via dm-crypt), la mise en miroir (*mirroring*), etc.

---

## 2. Architecture et fonctionnement de LVM

LVM introduit une couche d’abstraction qui repose sur trois concepts principaux :

1. **Physical Volumes (PV)**  
   - Correspondent aux disques ou partitions physiques (par exemple, `/dev/sda1`, `/dev/sdb`, etc.) marqués pour être gérés par LVM.  
   - Chaque PV est découpé en “Physical Extents” (PE), unités de stockage de taille fixe (par défaut 4 Mo).

2. **Volume Groups (VG)**  
   - Un Volume Group est un regroupement de un ou plusieurs PV.  
   - L’ensemble des Physical Extents (PE) de ces PV constitue une “pool” de stockage commune.  
   - Une fois un VG créé, on peut y créer autant de volumes logiques que l’espace le permet.

3. **Logical Volumes (LV)**  
   - Ce sont les volumes logiques à proprement parler. On peut les considérer comme l’équivalent “virtuel” d’une partition.  
   - Les LV sont eux-mêmes découpés en “Logical Extents” (LE), qui correspondent en pratique aux Physical Extents sous-jacents.  
   - Sur un LV, on installe un système de fichiers (ext4, xfs, btrfs, etc.) ou un autre type de service (swap, etc.).  
   - Les LV bénéficient de la flexibilité d’être redimensionnables, déplacés, clonés, etc.

Grâce à cette organisation, LVM permet de :
- Ajouter à chaud un nouveau disque dans un Volume Group, augmentant ainsi la capacité totale du “pool” de stockage.  
- Redimensionner un volume logique (l’agrandir ou le réduire, selon les contraintes du système de fichiers) sans avoir besoin de restructurer physiquement toutes les partitions sur le disque.  
- Déplacer des extents d’un disque vers un autre, par exemple pour retirer un disque physique d’un groupe, ou pour équilibrer la charge de stockage.  
- Créer des *snapshots* de volumes (copies instantanées *read-only* ou *read-write*), notamment utiles pour la sauvegarde ou la duplication.  

### 2.1 Comment LVM utilise Device Mapper
Au niveau du noyau, chaque Logical Volume géré par LVM est exposé comme un périphérique bloc virtuel dans `/dev/mapper/…` ou parfois `/dev/VGName/LVName`.  
Sous le capot, LVM transmet au *Device Mapper* une table de correspondances qui précise : “tel segment de ce volume logique correspond à telle zone sur le disque `/dev/sdb1`, tel autre segment correspond à `/dev/sdc1`, etc.”.  
Le Device Mapper se charge ensuite d’agréger ces blocs physiques en un seul périphérique bloc virtuel cohérent.

---

## 3. Architecture et fonctionnement du Device Mapper

Le *Device Mapper* est un module central du noyau Linux permettant de créer des *mappings* entre des blocs virtuels et des blocs physiques. Il prend la forme d’un framework : chaque fonctionnalité complémentaire (LVM, chiffrement, RAID logiciel, etc.) se base sur ce framework.

Les points-clés du Device Mapper :

1. **Tables de mapping**  
   - La structure fondamentale est la *table de mapping*, qui décrit comment les secteurs d’un périphérique virtuel sont mappés sur un ou plusieurs périphériques sous-jacents.  
   - Exemple : Vous pouvez dire “les secteurs 0 à 1023 de ce périphérique virtuel se trouvent dans la partition `/dev/sda2` à partir du secteur 2048, les secteurs 1024 à 2047 se trouvent sur `/dev/sdb1`…”, etc.

2. **Cibles (targets) du Device Mapper**  
   - Le Device Mapper prend en charge divers “types” de mapping ou “cibles” (*targets*).  
   - Parmi les cibles les plus connues :  
     - `linear` : mapping linéaire basique de blocs.  
     - `striped` : agrégation en bandes (similaire à RAID 0).  
     - `mirror` : mise en miroir (similaire à RAID 1).  
     - `snapshot` et `snapshot-origin` : gestion de snapshots.  
     - `crypt` : pour le chiffrement de disque (dm-crypt/LUKS).  
     - `thin` : pour le *thin provisioning* (allocation fine).  

3. **Communication avec l’espace utilisateur**  
   - Les utilisateurs ou les scripts interagissent avec le Device Mapper via des utilitaires comme `dmsetup` ou via LVM (qui l’utilise en arrière-plan).  
   - Ces commandes informent le noyau du type de mapping, du nombre de cibles, et des segments de blocs associés. Le noyau crée ensuite un nouveau périphérique bloc virtuel dans `/dev/mapper/…`.

4. **Avantages**  
   - Flexibilité : on peut combiner plusieurs “cibles” et créer ainsi des configurations complexes.  
   - Modularité : LVM, l’outil de chiffrement (LUKS/dm-crypt), ou encore certains RAID logiciels (via mdadm en conjonction) s’appuient sur ce mécanisme.  
   - Performance : le Device Mapper fonctionne dans le noyau, donc au niveau des entrées/sorties bloc, sans nécessiter de copies de données supplémentaires.  

---

## 4. Intégration LVM ↔ Device Mapper

- **Device Mapper** est la brique de base : il crée des périphériques bloc virtuels par assemblage et manipulation de périphériques bloc physiques réels.  
- **LVM** est une surcouche spécialisée utilisant les capacités du Device Mapper pour :  
  1. Définir quels blocs appartiennent à quel Physical Volume.  
  2. Regrouper ces PV dans des Volume Groups (VG).  
  3. Gérer la logique des extents et leur allocation aux différents Logical Volumes (LV).  
  4. Créer une table de mapping associée (ex. cibles `linear`, `snapshot`, etc.) pour que le noyau sache où lire/écrire les blocs de chaque LV.  

De ce fait, quand vous créez un Volume Group et des Logical Volumes via les commandes `pvcreate`, `vgcreate`, `lvcreate`, LVM construit automatiquement la configuration de Device Mapper. Chaque LV apparaît ensuite dans `/dev/mapper/…` et `/dev/<VG>/<LV>`.

---

## 5. Cas d’usage typiques

1. **Ajout à chaud d’espace de stockage**  
   - Vous ajoutez un nouveau disque, le déclarez comme PV via `pvcreate`, l’intégrez au Volume Group via `vgextend`, puis agrandissez le Logical Volume et enfin le système de fichiers. Tout cela, sans interrompre les services en cours d’utilisation (dans la limite des capacités de redimensionnement du système de fichiers).

2. **Snapshots pour sauvegarde ou test**  
   - Création d’un volume LV en tant que *snapshot* d’un volume existant. On peut ainsi réaliser une sauvegarde cohérente des données sans arrêter le service (ou en minimisant la fenêtre de maintenance).

3. **Disposition physique optimisée (RAID ou autres)**  
   - Possibilité d’utiliser des *striped volumes* (cible `striped`) pour répartir l’accès disque et gagner en performance.  
   - Possibilité de mettre en miroir (cible `mirror`) pour la tolérance aux pannes.

4. **Chiffrement au niveau bloc (dm-crypt/LUKS)**  
   - En ajoutant un layer “crypt” via Device Mapper, un Logical Volume peut être chiffré de bout en bout. LVM et Device Mapper sont alors complémentaires.

5. **Thin Provisioning**  
   - Permet de sur-allouer la capacité logique par rapport à la capacité physique réelle, très utile dans des environnements virtualisés ou de stockage partagé.

---

## 6. Conclusion

En résumé :

- **LVM** (Logical Volume Manager) est un ensemble d’outils et de concepts (Physical Volumes, Volume Groups, Logical Volumes) offrant une gestion très flexible du stockage.  
- **Device Mapper** est l’infrastructure dans le noyau Linux permettant de construire des volumes virtuels à partir de multiples périphériques physiques, en gérant divers modes de mapping (lineaire, miroir, snapshot, etc.).  

LVM **s’appuie** donc sur le Device Mapper : ce dernier fournit la mécanique bas niveau de mapping, tandis que LVM apporte la logique de gestion des volumes, les métadonnées et des fonctionnalités avancées de manipulation et de configuration du stockage. L’un ne se substitue pas à l’autre : ils forment un couple essentiel dans la plupart des distributions Linux modernes pour gérer le stockage de façon souple et puissante.