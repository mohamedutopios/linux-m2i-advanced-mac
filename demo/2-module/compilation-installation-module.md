Voici un guide clair et précis, étape par étape, pour créer, compiler, installer, charger, vérifier et décharger proprement un module noyau Linux en C, en évitant toutes les erreurs précédentes :

---

# ✅ Guide complet : Module Linux (kernel module) étape par étape

> **Environnement de test** :
> - **Debian (VM Vagrant ou autre distribution Debian)**
> - **Compte utilisateur avec accès sudo**

---

## 📌 **1. Préparer l’environnement Linux**

### ✅ **Installer les paquets nécessaires**

Lance ces commandes pour être sûr que tous les outils nécessaires sont présents :

```bash
sudo apt update
sudo apt install build-essential linux-headers-$(uname -r)
```

---

## 📌 **2. Créer le dossier pour le projet**

```bash
mkdir ~/module
cd ~/module
```

---

## 📌 **2. Créer le module en C**

Crée le fichier `hello_module.c` avec le contenu exact suivant :

```c
#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ton nom");
MODULE_DESCRIPTION("Un module Linux minimaliste");
MODULE_VERSION("1.0");

static int __init hello_init(void){
    printk(KERN_INFO "hello_module: Hello, module chargé !\n");
    return 0;
}

static void __exit hello_exit(void){
    printk(KERN_INFO "hello_module: Au revoir, module déchargé.\n");
}

module_init(hello_init);
module_exit(hello_exit);
```

**Explications :**  
- Utilise exactement les mêmes noms de fonctions dans les appels `module_init` et `module_exit` que ceux déclarés juste avant (`hello_init` et `hello_exit`).
- `printk` envoie les messages au journal du noyau.

---

## 📌 **2. Créer le Makefile**

Dans le **même dossier** (`~/module`), crée un fichier nommé `Makefile` avec ce contenu exact :

```makefile
obj-m += hello_module.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

> **Note :**  
> Vérifie que tu n’as pas oublié la commande `shell` devant `uname -r` sinon le chemin sera mal formé.

---

## 📌 **3. Compilation du module**

Lance maintenant la compilation :

```bash
make
```

Résultat attendu après cette commande :  
Le fichier **`hello_module.ko`** sera créé dans ton dossier.

Vérifie avec :

```bash
ls *.ko
```

---

## 📌 **4. Installation du module (facultatif, mais conseillé)**

Pour que `modprobe` fonctionne (et gère les dépendances correctement), installe ton module dans le répertoire prévu :

```bash
sudo cp hello_module.ko /lib/modules/$(uname -r)/extra/
sudo depmod -a
```

> Si le dossier `/extra` n'existe pas, crée-le avec :
> ```bash
> sudo mkdir -p /lib/modules/$(uname -r)/extra/
```

---

## 📌 **5. Chargement du module**

### ✅ **Méthode recommandée (modprobe)**

Après installation propre avec `depmod -a` :

```bash
sudo modprobe hello_module
```

Ou directement, avec `insmod` (moins recommandé, car ne gère pas les dépendances) :

```bash
sudo insmod hello_module.ko
```

---

## 📌 **6. Vérifier le chargement du module**

Vérifie que ton module est correctement chargé avec :

```bash
lsmod | grep hello_module
```

Tu obtiendras quelque chose comme :

```
hello_module      16384  0
```

Vérifie les messages dans les logs du noyau :

```bash
dmesg | grep hello_module
```

Résultat attendu :

```
hello_module: loading out-of-tree module taints kernel.
hello_module: Hello, module chargé !
```

⚠️ **L’avertissement "taints kernel" est normal** pour les modules compilés hors dépôt officiel.

---

## 📌 **7. Vérifier les informations du module (facultatif)**

```bash
modinfo hello_module
```

Tu devrais voir un résultat similaire :

```
filename:       /lib/modules/.../extra/hello_module.ko
license:        GPL
author:         Ton nom
description:    Un module Linux minimaliste
version:        1.0
...
```

---

## 📌 **8. Décharger proprement ton module**

Pour enlever ton module du noyau :

```bash
sudo modprobe -r hello_module
# ou
sudo rmmod hello_module
```

Puis vérifie encore une fois avec :

```bash
lsmod | grep hello_module
```

Résultat attendu : vide (le module n’est plus chargé).

Vérifie aussi les messages de sortie avec :

```bash
dmesg | grep hello_module
```

Résultat attendu (indiquant le déchargement) :

```
hello_module: Au revoir, module déchargé.
```

---

## 📌 **9. Charger automatiquement le module au démarrage (optionnel)**

Pour activer ton module automatiquement :

```bash
echo "hello_module" | sudo tee /etc/modules-load.d/hello_module.conf
```

Pour charger des paramètres particuliers :

```bash
echo "options hello_module param=valeur" | sudo tee /etc/modprobe.d/hello_module.conf
```

---

## 📚 **Synthèse finale des commandes principales**

Voici un rappel rapide des commandes principales à utiliser :

| Action                 | Commande                                            |
|------------------------|-----------------------------------------------------|
| **Compilation**        | `make`                                              |
| **Installation**       | `sudo cp hello_module.ko /lib/modules/$(uname -r)/extra/` |
| **Chargement**         | `sudo modprobe hello_module` ou `sudo insmod hello_module.ko` |
| **Lister chargé**      | `lsmod | grep hello_module`                         |
| **Voir infos**         | `modinfo hello_module`                              |
| **Voir messages noyau**| `dmesg | grep hello_module`                         |
| **Déchargement**       | `sudo modprobe -r hello_module` ou `sudo rmmod hello_module` |

---

🚩 **Important à retenir :**

- Vérifie bien la correspondance des noms des fonctions.
- Vérifie que les paquets nécessaires (`build-essential`, `linux-headers`) sont installés.
- Ne t’inquiète pas du message « kernel taints », il est normal pour les modules personnalisés hors distribution officielle du noyau.

✅ **Maintenant ton module fonctionnera correctement du premier coup !**