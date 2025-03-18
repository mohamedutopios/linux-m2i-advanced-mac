Sur Linux, les modules du noyau (également appelés **kernel modules**) sont des morceaux de code que vous pouvez charger dynamiquement pour étendre les fonctionnalités du noyau sans devoir recompiler celui-ci. Voici les principales opérations qu'il est possible d'effectuer avec les modules sur Linux :

---

## 1. Afficher les modules chargés

Permet de voir la liste complète des modules actuellement actifs sur votre système :

```bash
lsmod
```

---

## 2. Charger un module

```bash
sudo modprobe nom_module
```

Ou avec `insmod` en précisant le chemin exact du module (plus rare) :

```bash
sudo insmod /lib/modules/$(uname -r)/kernel/drivers/xxx/nom_module.ko
```

**`modprobe`** gère automatiquement les dépendances, alors qu'`insmod` non.

---

## 3. Décharger (décharger/désactiver) un module

```bash
sudo modprobe -r nom_module
```

Ou via `rmmod` (moins recommandé) :

```bash
sudo rmmod nom_module
```

**Remarque :** `modprobe` gère les dépendances automatiquement contrairement à `insmod` et `rmmod`.

---

## Consulter les détails d'un module chargé

```bash
modinfo nom_module
```

---

## Lister les modules actuellement chargés

```bash
lsmod
```

---

## Vérifier si un module est chargé

```bash
lsmod | grep nom_module
```

---

## Voir les messages du noyau liés aux modules

```bash
dmesg | grep nom_module
```

---

## Afficher les dépendances d'un module

```bash
modprobe --show-depends nom_module
```

---

## Gestion du chargement automatique au démarrage

Pour charger un module automatiquement au démarrage :

- Ajouter le nom du module dans `/etc/modules` (selon la distribution) ou créer un fichier de configuration spécifique dans :

```bash
/etc/modprobe.d/nom_module.conf
```

Par exemple :

```
echo "nom_module" | sudo tee -a /etc/modules
```

Ou pour charger avec des paramètres particuliers :

```bash
echo "options nom_module param=valeur" | sudo tee /etc/modprobe.d/nom_module.conf
```

---

## Identifier les modules actuellement chargés par le système

```bash
lsmod
# ou avec grep pour filtrer :
lsmod | grep nom_module
```

---

## Identifier les modules disponibles dans le système

```bash
find /lib/modules/$(uname -r) -type f -name "*.ko"
# ou via :
modprobe -c
```

---

## Vérifier les messages d'événements liés aux modules (logs)

```bash
dmesg | grep nom_module
```

---

## Résumé des commandes les plus importantes

| Commande        | Description rapide                                |
|-----------------|---------------------------------------------------|
| **lsmod**       | Liste les modules actuellement chargés            |
| **modprobe**    | Charge et décharge des modules avec dépendances   |
| **insmod**      | Charge directement un module (sans gestion des dépendances) |
| **rmmod**       | Décharge un module sans gestion des dépendances   |
| **modinfo**     | Affiche des informations détaillées sur un module |
| **dmesg**       | Affiche des informations sur les événements noyau |
| **depmod**      | Génère les dépendances entre modules              |

---

## Cas pratiques courants :

- Activer un périphérique réseau ou une carte Wifi (`iwlwifi`, `e1000e`).
- Ajouter un pilote pour matériel spécifique (carte graphique, périphérique USB).
- Désactiver temporairement un module pour des raisons de diagnostic ou sécurité.

---

Ces opérations couvrent largement les interactions courantes avec les modules sous Linux.