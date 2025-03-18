Voici une explication complète et détaillée concernant les **Loadable Kernel Modules (LKM)** sous Linux, accompagnée d’exemples pratiques et de commandes pour une compréhension approfondie.

---

# 📌 **Loadable Kernel Modules (LKM)**

Un **Loadable Kernel Module (LKM)** est une extension dynamique du noyau Linux. Il permet d'ajouter ou de retirer des fonctionnalités à chaud, sans nécessiter de recompiler ou de redémarrer le noyau.

---

## 🟢 1. Principe des Loadable Kernel Modules

**Avantages :**

- Modularité : charger uniquement les modules nécessaires.
- Flexibilité : ajouter ou retirer des fonctionnalités à chaud.
- Maintenance simplifiée : pas besoin de recompiler entièrement le noyau pour ajouter un pilote.

---

## 🟢 2. Gestion des modules kernel (commandes principales)

Voici les commandes de base pour la gestion des modules du noyau :

| Commande | Fonction |
|----------|------------|
| `lsmod` | Afficher les modules actuellement chargés |
| `modprobe` | Charger ou décharger des modules en gérant les dépendances |
| `insmod` | Charger un module spécifique (sans gestion automatique des dépendances) |
| `rmmod` | Retirer un module chargé (sans gestion automatique des dépendances) |
| `modinfo` | Afficher des informations détaillées sur un module |

---

## 🟢 2. Compilation et installation d'un module personnalisé (exemple détaillé)

### Exemple simple : module « Hello World » du kernel Linux

**Étape 1 : Installer les outils et dépendances nécessaires**

```bash
sudo apt update
sudo apt install build-essential linux-headers-$(uname -r)
```

---

## 🟢 2.1 Création du code source du module

Créez un fichier nommé `hello_module.c` :

```c
#include <linux/module.h>  // Obligatoire
#include <linux/kernel.h>  // KERN_INFO

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Votre nom");
MODULE_DESCRIPTION("Module Hello World simple");
MODULE_VERSION("0.1");

static int __init hello_init(void) {
    printk(KERN_INFO "Hello World : Module chargé\n");
    return 0;
}

static void __exit hello_exit(void) {
    printk(KERN_INFO "Hello World : Module déchargé\n");
}

module_init(hello_init);
module_exit(hello_exit);
```

**Explications :**
- `__init` : fonction exécutée au chargement du module.
- `__exit` : fonction exécutée lors du déchargement.
- `printk` : affiche un message dans les logs du noyau (`dmesg`).

---

## 🟢 2.2 Création d'un Makefile pour compiler le module

Créer un fichier `Makefile` dans le même dossier :

```makefile
obj-m += hello_module.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

---

## 🟢 2.3 Compilation du module

Exécuter la commande suivante pour compiler :

```bash
make
```

Après compilation, vous obtiendrez `hello_module.ko`.

---

## 🟢 3. Chargement et déchargement d'un module (manuellement)

### Charger un module :

```bash
sudo insmod hello_module.ko
```

### Vérifier qu’il est chargé :

```bash
lsmod | grep hello_module
```

### Vérifier les messages du noyau :

```bash
dmesg | tail
```

### Décharger le module :

```bash
sudo rmmod hello_module
```

Vérifier les logs du noyau après déchargement :

```bash
dmesg | tail
```

---

## 🟢 4. Affichage des informations d'un module

Utilisez `modinfo` pour voir des informations précises sur le module :

```bash
modinfo hello_module.ko
```

---

## 🟢 5. Liste de tous les modules existants (disponibles)

Tous les modules disponibles pour le noyau actuel sont situés dans :

```bash
/lib/modules/$(uname -r)/
```

Lister tous les modules existants :

```bash
find /lib/modules/$(uname -r)/ -name '*.ko*'
```

---

## 🟢 6. Liste des modules actuellement chargés

```bash
lsmod
```

---

## 🟢 7. Gestion des dépendances entre modules

La commande `modprobe` gère automatiquement les dépendances.

**Exemple : Charger un module avec ses dépendances automatiquement :**

```bash
sudo modprobe <nom_module>
```

Vérifier les dépendances d’un module :

```bash
modinfo -F depends <module>
```

---

## 🟢 8. Blocage d’un module (blacklisting)

Pour empêcher le chargement automatique d'un module au démarrage :

Créer un fichier `/etc/modprobe.d/blacklist.conf` :

```bash
echo "blacklist <nom_module>" | sudo tee -a /etc/modprobe.d/blacklist.conf
```

Reconstruire l’initramfs après modification :

```bash
sudo update-initramfs -u
sudo reboot
```

---

## 🟢 9. Création d’un noyau personnalisé (en intégrant des modules)

Lors de la compilation du noyau, vous pouvez choisir :

- D'intégrer directement le module dans le noyau (« built-in »).
- De le compiler comme module chargeable (`M`).

Via `make menuconfig`, sélectionnez :
- `[ * ]` pour intégrer directement.
- `[ M ]` pour avoir un module chargeable.

Après compilation (`make`), installez les modules :

```bash
make modules_install
```

---

## 📌 **Exemple détaillé : TP complet de compilation d’un module**

Voici un **exemple concret de travaux pratiques** :

| Étape | Détail pratique |
|-------|-----------------|
| Préparation | Installer les prérequis :<br>`sudo apt install build-essential linux-headers-$(uname -r)` |
| Code source | Rédiger un module basique (`hello_module.c`) |
| Makefile | Créer le fichier `Makefile` adapté |
| Compilation | `make` |
| Installation | `sudo insmod hello_module.ko` |
| Vérification | `lsmod`, `dmesg | tail` |
| Déchargement | `sudo rmmod hello_module` |
| Nettoyage | `make clean` |

---

## 📌 **Résumé pratique rapide des commandes :**

| Action                     | Commande pratique |
|----------------------------|-------------------|
| **Compiler module**        | `make` |
| **Charger module**         | `sudo insmod module.ko` ou `sudo modprobe module` |
| **Décharger module**       | `sudo rmmod module` ou `sudo modprobe -r module` |
| **Lister modules chargés** | `lsmod` |
| **Infos module**           | `modinfo module` |
| **Blocage (blacklist)**    | `/etc/modprobe.d/blacklist.conf` |

---

✅ **En résumé :**

Les LKM apportent une souplesse considérable au noyau Linux :

- Charger/décharger à chaud sans reboot.
- Faciliter le débogage et les tests.
- Personnaliser un noyau en fonction des besoins matériels précis.

Ce guide détaillé vous permettra de maîtriser entièrement les modules du noyau Linux.