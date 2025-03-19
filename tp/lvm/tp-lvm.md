

### TP : Gestion de LVM 

---

#### Contexte et Pré-requis

- **Matériel dédié :**
  - **Disque 1 :** `/dev/sdb` – 10 Go
  - **Disque 2 :** `/dev/sdc` – 15 Go

---

#### Étapes du TP

1. **Préparation des disques :**
   - Convertir `/dev/sdb` (10 Go) et `/dev/sdc` (15 Go) en Physical Volumes destinés à LVM.
   - Vérifier l’absence de données critiques sur ces disques avant transformation.

2. **Création du Volume Group (VG) :**
   - Regrouper les deux Physical Volumes dans un Volume Group nommé **`vg_tp_lvm`**.

3. **Création des Logical Volumes (LV) :**
   - Créer trois Logical Volumes à partir du VG **`vg_tp_lvm`** :
     - **LV 1 :** Nom **`lv_system`** – 6 Go (destiné au système)
     - **LV 2 :** Nom **`lv_data`** – 10 Go (destiné aux données)
     - **LV 3 :** Nom **`lv_backup`** – 5 Go (destiné aux backups ou à d’autres usages)
   - S’assurer que la somme des tailles utilisées ne dépasse pas l’espace total du VG.

4. **Extension d’un Logical Volume :**
   - Choisir le Logical Volume **`lv_data`** pour démontrer la flexibilité de LVM.
   - Procéder à son extension (augmentation de la taille) en s’assurant que l'espace libre dans le VG le permet.
   - Vérifier que l’extension est correctement prise en compte par le système.

5. **Nettoyage et Suppression :**
   - Supprimer les trois Logical Volumes créés (**`lv_system`**, **`lv_data`**, **`lv_backup`**).
   - Supprimer le Volume Group **`vg_tp_lvm`**.
   - Reconvertir les disques `/dev/sdb` et `/dev/sdc` en supprimant les métadonnées LVM, afin de remettre les disques dans leur état d’origine.

---
