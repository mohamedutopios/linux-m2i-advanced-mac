Je vais préparer une explication détaillée sur les Loadable Kernel Modules (LKM) sous Debian, en couvrant leur conception, leur compilation, leur gestion et leur personnalisation. Cela inclura des exemples concrets et des commandes spécifiques à Debian.

## 1. Conception d'un module de noyau  
Un **module de noyau** Linux est un morceau de code pouvant être chargé ou déchargé dynamiquement dans le noyau en cours d’exécution. Cela permet d’ajouter ou retirer des fonctionnalités (souvent des pilotes de périphériques) sans recompiler ni redémarrer le noyau ([Using The lsmod and modinfo Commands in Linux |
Linode Docs](https://www.linode.com/docs/guides/lsmod-and-modinfo-commands-in-linux/#:~:text=Linux%20kernel%20modules%20are%20pieces,to%20reboot%20your%20Linux%20system)). À l’inverse des composants compilés *en dur* dans le noyau, les modules chargeables (LKM) peuvent être insérés à la demande et retirés une fois inutilisés, offrant un noyau plus modulable et léger ([Using The lsmod and modinfo Commands in Linux |
Linode Docs](https://www.linode.com/docs/guides/lsmod-and-modinfo-commands-in-linux/#:~:text=Linux%20kernel%20modules%20are%20pieces,to%20reboot%20your%20Linux%20system)).  

Un module comporte au minimum deux fonctions spéciales : une fonction d’initialisation appelée lors du chargement et une fonction de nettoyage appelée juste avant sa désactivation ([Hello, World (part 1): The Simplest Module](https://tldp.org/LDP/lkmpg/2.4/html/x149.html#:~:text=Kernel%20modules%20must%20have%20at,their%20start%20and%20end%20functions)). Historiquement, ces fonctions portent les noms par défaut `init_module` (exécutée par `insmod`) et `cleanup_module` (exécutée par `rmmod`) ([Hello, World (part 1): The Simplest Module](https://tldp.org/LDP/lkmpg/2.4/html/x149.html#:~:text=Kernel%20modules%20must%20have%20at,their%20start%20and%20end%20functions)). Depuis les noyaux 2.4, il est courant d’utiliser les macros `module_init()` et `module_exit()` pour associer des fonctions personnalisées à l’initialisation et la sortie du module (ce qui permet de nommer librement ces fonctions) ([Hello, World (part 1): The Simplest Module](https://tldp.org/LDP/lkmpg/2.4/html/x149.html#:~:text=the%20kernel%2C%20and%20an%20,their%20start%20and%20end%20functions)). La fonction d’init réalise généralement l’enregistrement de ressources ou de gestionnaires au sein du noyau (par ex. enregistrement d’un pilote de périphérique) ([Hello, World (part 1): The Simplest Module](https://tldp.org/LDP/lkmpg/2.4/html/x149.html#:~:text=Typically%2C%20,module%20can%20be%20unloaded%20safely)), tandis que la fonction de cleanup libère ces ressources afin que le module puisse être déchargé proprement ([Hello, World (part 1): The Simplest Module](https://tldp.org/LDP/lkmpg/2.4/html/x149.html#:~:text=Typically%2C%20,module%20can%20be%20unloaded%20safely)).  

Lors de l’implémentation, un module doit inclure les en-têtes kernel nécessaires, en particulier `<linux/module.h>` (obligatoire pour tout module) et souvent `<linux/kernel.h>` (pour les macros de journalisation `KERN_INFO`, etc.) ([Hello, World (part 1): The Simplest Module](https://tldp.org/LDP/lkmpg/2.4/html/x149.html#:~:text=Lastly%2C%20every%20kernel%20module%20needs,1)). On utilise la fonction de log du noyau `printk()` pour émettre des messages (les fonctions d’E/S standard comme `printf` ne sont pas disponibles en espace noyau). Il est également recommandé de définir certaines macro-informations (licence, auteur, description…) qui seront visibles via `modinfo`. Par exemple, voici la structure minimale d’un module simple qui affiche un message lors du chargement et du retrait :  

```c
#include <linux/module.h>
#include <linux/kernel.h>

static int __init hello_init(void) {
    printk(KERN_INFO "Hello, kernel module!\n");
    return 0;  // 0 = succès du chargement
}

static void __exit hello_exit(void) {
    printk(KERN_INFO "Goodbye, kernel module!\n");
}

module_init(hello_init);
module_exit(hello_exit);

MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Exemple de module simple affichant des messages");
```  

Dans cet exemple, le module imprime des messages dans le journal du noyau grâce à `printk`. On peut vérifier ces messages via `dmesg` une fois le module chargé puis déchargé. Les macros `module_init`/`module_exit` enregistrent nos fonctions auprès du noyau, et les macros `MODULE_*` fournissent des métadonnées. Un code de retour 0 indique que l’initialisation s’est bien passée (une valeur non nulle provoquerait l’échec du `insmod`).  

## 2. Compilation et installation d'un module  
Pour compiler un module externe sous Debian, il faut disposer des **en-têtes du noyau** correspondant à la version du noyau en cours, ainsi que des outils de build. Commencez par installer les paquets nécessaires :  

- **Headers du noyau et outils de compilation** – Par exemple, pour le noyau courant :  
  ```bash
  sudo apt update && sudo apt install build-essential linux-headers-$(uname -r)
  ```  
  Le paquet `build-essential` fournit `make` et `gcc` entre autres, et `linux-headers-$(uname -r)` installe les en-têtes de développement du noyau actuellement exécuté. Assurez-vous d’utiliser la version correspondant au noyau cible.  

- **Code source du module** – Placez le code du module (ex. fichier `hello.c` ci-dessus) dans un dossier dédié. Écrivez ensuite un **Makefile** pour automatiser la compilation. Un Makefile minimal pour un module s’appuie sur le système de build du noyau en spécifiant le répertoire des headers du noyau et le fichier objet du module. Par exemple : 

  ```Makefile
  # Makefile de compilation du module hello.ko
  obj-m := hello.o  
  KDIR := /lib/modules/$(shell uname -r)/build  
  PWD  := $(shell pwd)  

  all:
  	$(MAKE) -C $(KDIR) M=$(PWD) modules

  clean:
  	$(MAKE) -C $(KDIR) M=$(PWD) clean
  ```  

  Ici, `obj-m := hello.o` indique que l’on construit un module à partir du code objet `hello.o`. La commande `$(MAKE) -C $(KDIR) M=$(PWD) modules` invoque la compilation des modules en utilisant les makefiles du noyau Linux situés dans `KDIR` (le lien vers les headers du noyau courant). Cette invocation va produire un fichier `hello.ko` (module compilé) si tout se passe bien.  

- **Compilation du module** – Exécutez simplement `make` dans le répertoire contenant votre code et le Makefile. Le système de build du noyau va compiler le module en utilisant la configuration du noyau courant. À l’issue de la compilation, vous devriez obtenir un fichier `hello.ko` (ou similaire) correspondant au module. Vous pouvez vérifier les propriétés de ce module avec l’outil **`modinfo`** avant même de le charger : par exemple `modinfo hello.ko` affichera les informations incorporées (nom du module, version, licence, description, dépendances, auteur, etc.) ([Using The lsmod and modinfo Commands in Linux |
Linode Docs](https://www.linode.com/docs/guides/lsmod-and-modinfo-commands-in-linux/#:~:text=filename%3A%20%2Flib%2Fmodules%2F5.11.0,EFA3D70B6EF087871934E84%20depends)). Par exemple :  

  ```bash
  $ modinfo hello.ko
  filename:       /home/user/hello/hello.ko  
  license:        GPL  
  description:    "Exemple de module simple affichant des messages"  
  depends:        <aucune>  
  ```  

  On voit que les champs reflètent les macros `MODULE_` définies dans le code (licence GPL, description fournie, etc.), et que ce module n’a pas de dépendances.  

- **Installation du module (optionnel)** – Pour que le module soit disponible via `modprobe` et chargé automatiquement si besoin, il faut l’installer dans le système. Cela consiste généralement à copier le fichier `.ko` dans un répertoire approprié sous `/lib/modules/<version_du_noyau>/` (par exemple dans `/lib/modules/$(uname -r)/extra/`) puis de mettre à jour l’index des modules avec `depmod` (voir point 7 sur les dépendances). Alternativement, si le module est destiné à être utilisé temporairement, on peut le charger directement depuis le répertoire courant sans l’installer, comme montré ci-après.  

## 3. Chargement / déchargement d'un module  
Une fois le module compilé, vous pouvez le **charger** dans le noyau ou le **décharger** à chaud à l’aide des outils `kmod`. Les principales commandes sont :  

- **`insmod`** – Insère un module *manuellement*. On doit fournir le chemin vers le fichier `.ko`. Par exemple : `sudo insmod ./hello.ko` va tenter de charger le module `hello.ko` dans le noyau. Si le module n’est pas compilé pour la même version de noyau ou si des symboles manquent, l’insertion échouera. `insmod` ne résout pas automatiquement les dépendances, il charge uniquement le module spécifié et signale une erreur générique en cas d’échec ([insmod(8) — manpages-fr — Debian testing — Debian Manpages](https://manpages.debian.org/testing/manpages-fr/insmod.8.fr.html#:~:text=insmod%20est%20un%20programme%20simple,g%C3%A9rer%20les%20d%C3%A9pendances%20des%20modules)). (En pratique, il faut alors consulter `dmesg` pour obtenir le détail de l’erreur depuis le noyau ([insmod(8) — manpages-fr — Debian testing — Debian Manpages](https://manpages.debian.org/testing/manpages-fr/insmod.8.fr.html#:~:text=Seuls%20les%20messages%20d%E2%80%99erreur%20les,plus%20d%27informations%20sur%20les%20erreurs)).) Cette commande est surtout utile pour tester un module local; dans les autres cas on privilégie `modprobe`.  

- **`modprobe`** – Charge un module en gérant les dépendances. On fournit le nom du module (sans le chemin ni l’extension `.ko`). Par exemple : `sudo modprobe hello` chercherait le module nommé “hello” dans `/lib/modules/<version>/` et le chargerait. Contrairement à `insmod`, `modprobe` va d’abord charger les éventuels modules dont dépend *hello* d’après la liste de dépendances connue (fichier `modules.dep`). En effet, `modprobe` est plus « intelligent » et peut chaîner les insertions de modules liés ([insmod(8) — manpages-fr — Debian testing — Debian Manpages](https://manpages.debian.org/testing/manpages-fr/insmod.8.fr.html#:~:text=insmod%20est%20un%20programme%20simple,g%C3%A9rer%20les%20d%C3%A9pendances%20des%20modules)). S’il manque des dépendances ou si le module est introuvable, `modprobe` retournera une erreur. (Notons que `modprobe` utilise en interne `insmod` pour l’insertion, après avoir résolu les dépendances.)  

- **`lsmod`** – Liste les modules actuellement chargés dans le noyau (voir section 5). On peut utiliser `lsmod` ou lire le contenu de `/proc/modules` pour vérifier qu’un module est bien actif. Par exemple, après un `insmod hello.ko`, la commande `lsmod | grep hello` devrait afficher une ligne avec le nom du module *hello*.  

- **`rmmod`** – Retire (*unload*) un module du noyau. On lui passe le nom du module à retirer (ex: `sudo rmmod hello`). Cette commande échouera si le module est actuellement utilisé (compteur de références non nul). Il est donc important de fermer ou détacher toute ressource liée avant de retirer un module (par ex. démonter un système de fichiers, fermer un périphérique).  

- **`modprobe -r`** – Équivaut à `rmmod`, mais gère aussi les dépendances inverses. Par exemple, si le module A dépend du module B, un `modprobe -r B` retirera d’abord A puis B. Cela facilite le déchargement en chaîne.  

Après chaque insertion ou retrait, on peut consulter `dmesg` pour voir les messages du noyau relatifs aux modules. Un module bien programmé affichera souvent un message à son chargement et à sa suppression (via `printk`), comme dans notre exemple *hello*. Par exemple :  

```bash
# insmod hello.ko          # Chargement du module
# lsmod | head -n5         # Lister les premiers modules actifs
Module                  Size  Used by
hello                  16384  0        # <- Le module 'hello' est chargé
snd_seq                86016  0
snd_seq_device         16384  1 snd_seq
...  
# rmmod hello            # Déchargement du module
# dmesg | tail -n2       # Derniers messages du noyau
[ 1234.567890] hello: module loaded
[ 1240.678901] hello: module unloaded
```  

Ici, `lsmod` confirme que *hello* était chargé (taille ~16 Ko, utilisé par 0 autre module). Le journal noyau (`dmesg`) montre les messages du module lors du chargement puis du déchargement.  

## 4. Liste de tous les modules existants  
Les modules fournis avec le noyau Debian sont stockés dans le répertoire centralisé **`/lib/modules/<version_du_noyau>/`**, organisé par version de noyau ([Using The lsmod and modinfo Commands in Linux |
Linode Docs](https://www.linode.com/docs/guides/lsmod-and-modinfo-commands-in-linux/#:~:text=Linux%20Kernel%20Modules%20are%20all,display%20the%20following%20installed%20kernels)). Chaque sous-dossier correspond à une version installée du noyau, et contient lui-même un arbre de fichiers `.ko` rangés par catégories (drivers, systèmes de fichiers, réseau, etc.). Par exemple, `/lib/modules/$(uname -r)/kernel/` contient les modules pour le noyau courant.  

Pour **lister tous les modules disponibles** pour un noyau donné, on peut parcourir ce répertoire. Par exemple, la commande suivante liste tous les modules (.ko) du noyau en cours :  

```bash
find /lib/modules/$(uname -r) -type f -name "*.ko"
```  

Cette liste peut être très longue (plusieurs centaines de modules). On peut la filtrer avec `grep` pour trouver un module particulier par nom. Par exemple `find /lib/modules/$(uname -r) -name "*usb*ko"` listera les modules dont le nom contient "usb".  

Une autre manière est d’utiliser `modprobe` en mode listing. La commande `modprobe -l` (`--list`) énumère tous les modules disponibles pour le noyau courant (selon l’index de modules.dep). Par exemple, `modprobe -l | grep usbcore` affichera le chemin du module core USB.  

Une fois un fichier module identifié, vous pouvez consulter ses informations détaillées avec **`modinfo`** (voir section 6). Par exemple : `modinfo /lib/modules/$(uname -r)/kernel/drivers/usb/core/usbcore.ko` affichera la description du module USB core, ses dépendances, etc.  

En résumé, le répertoire `/lib/modules` est la **bibliothèque de tous les modules** disponibles localement pour chaque version du noyau ([Using The lsmod and modinfo Commands in Linux |
Linode Docs](https://www.linode.com/docs/guides/lsmod-and-modinfo-commands-in-linux/#:~:text=Linux%20Kernel%20Modules%20are%20all,display%20the%20following%20installed%20kernels)). Il contient notamment des fichiers d’index comme `modules.dep`, `modules.alias`, etc., qui aident `modprobe` à trouver le bon module en fonction d’un nom ou d’un alias. Vous pouvez explorer ces fichiers si besoin, mais les outils haut niveau (`modprobe -l`, `modinfo`…) sont généralement plus pratiques.  

## 5. Liste des modules chargés  
Pour voir la liste des modules **actuellement chargés** dans le noyau, on utilise la commande **`lsmod`**. Celle-ci lit simplement le contenu de `/proc/modules` et l’affiche dans un format tabulaire lisible ([[SOLVED]Lsmod explanation - How it works! - Arch Linux Forums](https://bbs.archlinux.org/viewtopic.php?id=82216#:~:text=lsmod%20does%20very%20little,are%20found%20inside%20the%20kernel)). Chaque ligne correspond à un module actif et comporte généralement trois champs ([Using The lsmod and modinfo Commands in Linux |
Linode Docs](https://www.linode.com/docs/guides/lsmod-and-modinfo-commands-in-linux/#:~:text=%2A%20Module%20,system%20is%20using%20the%20module)) : 

- **Module** – le nom du module chargé.  
- **Size** – la taille en mémoire du module (en octets).  
- **Used by** – le compteur d’utilisation et la liste des autres modules qui l’utilisent. Un compteur à 0 indique que le module n’est pas requis actuellement et peut être déchargé sans risque. S’il est non nul, il liste les noms des modules dépendants.  

Par exemple, un extrait de `lsmod` peut donner : 

```bash
$ lsmod | head -n5
Module                  Size  Used by
lp                     20480  0
ppdev                  24576  0
parport                53248  2 lp,ppdev
usbhid                 57344  0
```  

Ici, on voit que les modules *lp* (pilote d’imprimante parallèle) et *ppdev* sont chargés mais non utilisés (compteur 0). Le module *parport* est utilisé par 2 modules (lp et ppdev), ce qui est indiqué dans la colonne "Used by". De même *usbhid* (pilote générique HID USB) est chargé et pas utilisé par d’autres modules. 

L’affichage `lsmod` permet de vérifier rapidement quels pilotes ou fonctionnalités sont actifs. C’est équivalent à lire le fichier texte `/proc/modules` qui liste les modules chargés avec les mêmes informations ([lsmod shows -2 in the “Used by” column](https://unix.stackexchange.com/questions/269500/lsmod-shows-2-in-the-used-by-column#:~:text=lsmod%20shows%20,Live%200xbf140000%20async_pq%205548)). Notons que cette liste ne comprend que les modules **dynamiques**; les fonctionnalités compilées en dur dans le noyau n’y apparaissent pas (voir point 9 sur les modules intégrés) ([Difference between Linux Loadable and built-in modules - Stack Overflow](https://stackoverflow.com/questions/22929065/difference-between-linux-loadable-and-built-in-modules#:~:text=Note%3A%20,in%60%20ones)).  

## 6. Affichage des informations d'un module  
Pour obtenir des détails sur un module du noyau (qu’il soit déjà chargé ou simplement disponible), on utilise la commande **`modinfo`**. Cet outil extrait les informations intégrées au module, soit à partir du fichier `.ko`, soit à partir de la base des modules installés (il cherche dans `/lib/modules/<version>/` si on lui donne un nom de module sans chemin) ([modinfo(8) — manpages-fr — Debian testing — Debian Manpages](https://manpages.debian.org/testing/manpages-fr/modinfo.8.fr.html#:~:text=modinfo%20extrait%20les%20informations%20des,chargement%20des%20modules%20du%20noyau)). 

La syntaxe est simple : `modinfo <nom_module>` ou `modinfo <chemin/vers/module.ko>`. Par exemple, pour un module déjà présent sur le système comme **`usbcore`**, on peut exécuter : 

```bash
$ modinfo usbcore
filename:       /lib/modules/5.10.0-19-amd64/kernel/drivers/usb/core/usbcore.ko
description:    USB core driver
author:         {See file}
license:        GPL
alias:          usb-host-class-device
srcversion:     5C6FF1234567890ABCDEF
depends:        usb-common
intree:         Y
name:           usbcore
vermagic:       5.10.0-19-amd64 SMP mod_unload modversions 
``` 

On obtient de nombreuses informations utiles : le chemin exact du fichier du module (`filename`), une description textuelle, l’auteur, la licence, d’éventuels alias (noms alternatifs utilisés par le système, par exemple pour l’auto-chargement via udev), la liste des *dépendances* (`depends`) c’est-à-dire les autres modules qui doivent être chargés pour que celui-ci fonctionne, la version magique (`vermagic`) qui doit correspondre à la version du noyau, etc. La plupart de ces champs correspondent à des macros que le développeur du module a insérées (`MODULE_DESCRIPTION`, `MODULE_AUTHOR`, `MODULE_LICENSE`, `MODULE_ALIAS`, etc.).  

On peut utiliser `modinfo` aussi bien sur un module *déjà chargé* que sur un module simplement installé sur le disque. Si le module est chargé, les informations proviennent du fichier sur le disque (il n’interroge pas le noyau en direct). Par exemple, `modinfo hello.ko` (notre module d’exemple) ou `modinfo hello` (si installé dans `/lib/modules`) affichera la licence GPL et la description qu’on avait définies dans le code, confirmant que le module est bien conforme à nos attentes. 

En résumé, `modinfo` est un outil de **documentation des modules** : il permet de vérifier la version, les dépendances et les paramètres d’un module avant de le charger. C’est particulièrement utile pour diagnostiquer les problèmes de compatibilité ou pour s’assurer qu’une fonctionnalité est bien fournie par le bon module. *(Astuce : vous pouvez lister un champ spécifique avec `-F` – par ex. `modinfo -F depends <module>` n’affichera que les dépendances du module.)* ([modinfo(8) — manpages-fr — Debian testing — Debian Manpages](https://manpages.debian.org/testing/manpages-fr/modinfo.8.fr.html#:~:text=)).  

## 7. Gestion des dépendances de modules  
Les modules du noyau peuvent dépendre les uns des autres. Par exemple, le module d’un périphérique réseau sans fil peut dépendre d’un module de pile crypto ou d’un module de bus PCI. Pour gérer automatiquement ces **dépendances**, Linux utilise un fichier d’index appelé **`modules.dep`** qui énumère, pour chaque module, la liste de ses éventuelles dépendances. 

- **Génération de modules.dep (depmod)** – Le fichier `/lib/modules/<version>/modules.dep` est généré par l’utilitaire `depmod`. À chaque installation ou mise à jour de modules (par ex. après l’installation d’un nouveau noyau ou d’un module tiers), on exécute `depmod -a` pour analyser tous les modules disponibles et recalculer leurs dépendances. `depmod` va lire chaque fichier `.ko` et déterminer de quels symboles ou autres modules il a besoin, puis écrire le résultat dans `modules.dep` (et un fichier binaire `modules.dep.bin`). Cela permet à d’autres outils de connaître instantanément les dépendances sans avoir à analyser les fichiers à chaque fois ([linux - Why does modinfo say “could not find module”, yet lsmod claims the module is loaded? - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/70990/why-does-modinfo-say-could-not-find-module-yet-lsmod-claims-the-module-is-loa#:~:text=,depmod)). Par exemple, si le module *abc.ko* a besoin des modules *def.ko* et *ghi.ko*, `modules.dep` contiendra une ligne du type :  
  ```
  /lib/modules/5.10.0-19-amd64/.../abc.ko: /lib/modules/5.10.0-19-amd64/.../def.ko /lib/modules/5.10.0-19-amd64/.../ghi.ko
  ```  
  indiquant à modprobe qu’il faut charger *def* et *ghi* avant *abc*.  

- **Utilisation de `modprobe` vs `insmod`** – Grâce à `modules.dep`, la commande `modprobe` peut automatiquement charger tous les modules dont dépend un module cible. Par exemple, si *foo* dépend de *bar* et *baz*, un simple `modprobe foo` insérera *bar*, *baz* puis *foo* dans le bon ordre. C’est pourquoi il est **recommandé d’utiliser `modprobe`** pour charger les modules plutôt que `insmod` ([insmod(8) — manpages-fr — Debian testing — Debian Manpages](https://manpages.debian.org/testing/manpages-fr/insmod.8.fr.html#:~:text=insmod%20est%20un%20programme%20simple,g%C3%A9rer%20les%20d%C3%A9pendances%20des%20modules)). `insmod` ne fait aucune résolution : si vous insérez *foo.ko* sans avoir préalablement inséré ses dépendances, l’appel échouera (ou le module foo plantera car il ne trouve pas ce dont il a besoin). En pratique, on réserve `insmod` aux tests rapides en connaissant exactement l’ordre de chargement, ou pour des cas très spécifiques. Pour une utilisation courante, `modprobe` gère tout automatiquement en s’appuyant sur `modules.dep`.  

- **Mise à jour des dépendances** – Sur Debian, lors de l’installation d’un nouveau noyau ou module, le script d’installation exécute généralement `depmod -a` automatiquement. Cependant, si vous ajoutez manuellement un fichier `.ko` dans `/lib/modules/...`, pensez à lancer `sudo depmod -a` avant de tenter un `modprobe` ou un `modinfo` sur ce module. Sans cela, `modinfo` ou `modprobe` risquent de ne pas le trouver ou de ne pas connaître ses dépendances, puisque `modules.dep` n’aura pas été mis à jour (d’où des erreurs *"Module not found"* possibles) ([linux - Why does modinfo say “could not find module”, yet lsmod claims the module is loaded? - Unix & Linux Stack Exchange](https://unix.stackexchange.com/questions/70990/why-does-modinfo-say-could-not-find-module-yet-lsmod-claims-the-module-is-loa#:~:text=,depmod)).  

En résumé, `depmod` est l’outil de **gestion des dépendances** entre modules. Il crée une cartographie que `modprobe` utilise pour charger proprement les modules liés. À noter que d’autres fichiers, comme `modules.alias` (généré par depmod), permettent de mapper des alias (par ex. identifiants de matériel PCI/USB) vers des noms de module – ce qui aide udev à auto-charger le bon module pour un périphérique donné.  

## 8. Blocage d'un module  
Il peut arriver que l’on veuille empêcher le chargement d’un module particulier, par exemple pour désactiver un pilote gênant ou qui entre en conflit avec un autre. Deux mécanismes principaux existent pour **blacklister** un module sous Debian : via la configuration de modprobe, ou via les options du noyau au démarrage. 

- **Blacklister via modprobe (fichier de config)** – On peut interdire le chargement automatique d’un module en le listant dans un fichier de configuration de modprobe. Le fichier commun est `/etc/modprobe.d/blacklist.conf` (ou on peut créer un fichier séparé `.conf`). Il suffit d’y ajouter une ligne :  
  ```plaintext
  blacklist <nom_du_module>
  ```  
  Par exemple, pour blacklister le module `nouveau` (pilote libre Nvidia), on ajouterait `blacklist nouveau`. Après cela, il est conseillé d’exécuter `depmod -ae` puis de régénérer l’initramfs : `sudo update-initramfs -u` ([fr/KernelModuleBlacklisting - Debian Wiki](https://wiki.debian.org/fr/KernelModuleBlacklisting#:~:text=1.%20Cr%C3%A9ez%20un%20fichier%20%27%60%2Fetc%2Fmodprobe.d%2F,nom%C2%A0du%C2%A0module)). Ceci assure que lors du prochain démarrage, le module ne sera pas chargé automatiquement, y compris pendant la phase d’initramfs. **Attention** : la blacklist modprobe empêche le chargement *automatique* du module (par udev ou autres mécanismes), mais n’empêche pas un administrateur de le charger manuellement par la suite. En effet, un `sudo modprobe <module>` explicitera forcera le chargement même s’il est blacklisté dans modprobe.d ([How to blacklist kernel modules? - Ask Ubuntu](https://askubuntu.com/questions/110341/how-to-blacklist-kernel-modules#:~:text=4)). Pour réellement bloquer toute insertion, y compris manuelle, on peut utiliser une directive *install* qui redirige l’action vers `/bin/false`. Par exemple, dans `/etc/modprobe.d/blacklist.conf` :  
  ```plaintext
  install <nom_du_module> /bin/false
  ```  
  Ceci aura pour effet de rendre toute tentative de chargement de ce module inactive (modprobe exécutera `/bin/false` à la place). Cette méthode est plus radicale et garantit qu’aucun processus ne puisse charger le module concerné ([How to blacklist kernel modules? - Ask Ubuntu](https://askubuntu.com/questions/110341/how-to-blacklist-kernel-modules#:~:text=4)).  

- **Blacklister via une option du noyau (GRUB)** – L’autre méthode consiste à passer une option au noyau Linux pour qu’il ignore un module. On utilise la syntaxe **`modprobe.blacklist=<nom_module>`** dans la ligne de commande du noyau. Sous Debian, on peut éditer le fichier `/etc/default/grub` et ajouter le ou les modules à blacklister dans la variable `GRUB_CMDLINE_LINUX`. Par exemple :  
  ```plaintext
  GRUB_CMDLINE_LINUX="modprobe.blacklist=nouveau"
  ```  
  (On peut l’ajouter aux autres paramètres existants, séparé par des espaces. Pour plusieurs modules, on peut les lister séparés par des virgules : ex. `modprobe.blacklist=nouveau,firewire_ohci`.) Ensuite, exécutez `sudo update-grub`. Au prochain redémarrage, le noyau ne chargera pas ces modules blacklistés au démarrage ([How to blacklist kernel modules? - Ask Ubuntu](https://askubuntu.com/questions/110341/how-to-blacklist-kernel-modules#:~:text=Another%20way%20to%20blacklist%20modules,to%20the%20kernel%20command%20line)) ([How to blacklist kernel modules? - Ask Ubuntu](https://askubuntu.com/questions/110341/how-to-blacklist-kernel-modules#:~:text=GRUB_CMDLINE_LINUX_DEFAULT%3D)). Cela est équivalent à la méthode précédente, mais agit dès les premiers instants du boot, avant même que l’initramfs ne charge quoi que ce soit. Cette technique est souvent utilisée pour désactiver *nouveau* en vue d’installer le pilote propriétaire Nvidia, par exemple. *(Pour que cette option soit prise en compte pendant l’initramfs, assurez-vous d’avoir recréé l’initrd avec update-initramfs après avoir modifié la blacklist modprobe.d comme indiqué ci-dessus.)*  

En résumé, pour **bloquer un module**, on le place en blacklist modprobe et/ou on indique au noyau de l’ignorer. Préférez la blacklist modprobe pour une solution pérenne et modifiable sans redémarrer (utile si vous gérez via des outils de configuration), et le paramètre kernel `modprobe.blacklist` pour bloquer dès le boot (utile pour les modules problématiques à l’amorçage). Dans les deux cas, vérifiez après reboot avec `lsmod` ou `dmesg` que le module n’apparaît plus. 

## 9. Création d'un noyau personnalisé avec intégration de modules  
Dans certaines situations, on peut souhaiter compiler un noyau personnalisé où certains modules sont directement **intégrés en dur** dans l’image du noyau (plutôt qu’en modules séparés). Sous Debian, il est tout à fait possible de compiler son propre noyau tout en conservant un emballage `.deb` propre pour l’installer. Voici les grandes étapes :  

**1) Préparer l’environnement de compilation** – Installez les outils nécessaires :  
```bash
sudo apt install build-essential kernel-package fakeroot libncurses-dev
```  
- *build-essential* (gcc, make, etc.) et *libncurses-dev* (pour l’interface textuelle de configuration du noyau) sont indispensables.  
- *kernel-package* fournit l’outil `make-kpkg` pour construire des noyaux Debian.  
- *fakeroot* permettra de construire le paquet sans droits root.  

**2) Obtenir les sources du noyau** – Deux approches : soit récupérer les sources fournies par Debian (paquet `linux-source-<version>`), soit télécharger les sources kernel.org de la version souhaitée. Pour un noyau Debian, il est recommandé d’utiliser `apt`: par ex. `sudo apt install linux-source-5.10`. Ceci placera une archive (typiquement dans `/usr/src/`) que vous devrez décompresser :  
```bash
cd /usr/src/  
tar xf linux-source-5.10.tar.xz  
cd linux-source-5.10
```  

**3) Configurer le noyau (make menuconfig)** – Avant de compiler, il faut configurer quels composants seront inclus. Vous pouvez partir de la config actuelle du noyau Debian (fichier `/boot/config-$(uname -r)`) en le copiant dans `.config` puis en lançant `make oldconfig` ou `make menuconfig`. La commande `make menuconfig` ouvre une interface en mode texte qui permet de parcourir toutes les options du noyau. C’est ici que vous pouvez choisir d’intégrer un module en dur. Naviguez jusqu’à l’option correspondant à la fonctionnalité/module désiré et changez son état :  

- `[*]` (Y) = compilé en dur dans le noyau (builtin)  
- `[M]` = compilé en module chargeable  
- `[ ]` (N) = non inclus du tout  

Par exemple, si vous voulez intégrer le module `hello` en dur, il faudrait qu’une option de configuration le concernant soit marquée `[*]` au lieu de `[M]`. Dans la pratique, on fait surtout cela pour des modules critiques (pilotes de disque, systèmes de fichiers racine, etc.) afin qu’ils soient disponibles dès le boot sans initrd. Vous pouvez également désactiver complètement certains modules dont vous n’avez pas besoin (mettre sur `[ ]`). **Enregistrez la configuration** en quittant menuconfig. Cela génère le fichier `.config` final. *(Astuce : utilisez la touche “/” dans menuconfig pour rechercher une option par nom.)*  

**4) Compilation du noyau et des modules** – Utilisez maintenant **`make-kpkg`** pour compiler et empaqueter le noyau. Cet outil va automatiser la compilation (`make`) puis construire un paquet .deb installable. Par exemple :  
```bash
export CONCURRENCY_LEVEL=4    # pour accélérer la compilation sur multi-cœurs (facultatif)
fakeroot make-kpkg --initrd --revision=1.0-custom kernel_image kernel_headers
```  
Cette commande compile le noyau avec génération d’une image initrd (--initrd) et assigne un numéro de révision personnalisé. Elle produira deux fichiers .deb dans le répertoire parent : l’image du noyau (`linux-image-...custom_amd64.deb`) et les en-têtes (`linux-headers-...custom_amd64.deb`). Vous pouvez ajuster `--revision` pour identifier votre build. *(Note: `make-kpkg` doit être lancé depuis la racine des sources du noyau, et il utilise la config définie dans `.config`. Assurez-vous donc que vos changements de configuration (point 3) sont bien effectués avant cette étape.)*  ([Ubuntu Manpage:

       make-kpkg - Construction de paquets Debian du noyau à partir des sources du noyau Linux
    ](https://manpages.ubuntu.com/manpages/trusty/fr/man1/make-kpkg.1.html#:~:text=make)). La compilation peut prendre un certain temps selon la puissance de votre machine et le nombre de modules/niveaux d’optimisation du noyau.  

**5) Installation du noyau personnalisé** – Une fois les paquets `.deb` générés, installez-les via dpkg :  
```bash
sudo dpkg -i ../linux-image-5.10.0-custom_amd64.deb ../linux-headers-5.10.0-custom_amd64.deb
```  
Le paquet `linux-image` va placer le fichier du noyau (`vmlinuz-5.10.0-custom`) dans `/boot` ainsi que les modules compilés dans `/lib/modules/5.10.0-custom/`. Il va également générer un initrd incluant vos modules nécessaires (puisque on avait passé --initrd) et mettre à jour le chargeur **GRUB** automatiquement pour ajouter une entrée pour ce noyau (grâce aux scripts *post-install* Debian) ([8.10. Compiling a Kernel](https://debian-handbook.info/browse/ro-RO/stable/sect.kernel-compilation.html#:~:text=Unsurprisingly%20Debian%20manages%20the%20kernel,bootloader%20and%20the%20initrd%20generator)). Le paquet `linux-headers` n’est pas strictement nécessaire pour le fonctionnement du noyau, mais utile si vous voulez compiler d’autres modules externes pour ce noyau.  

**6) Redémarrage sur le nouveau noyau** – Mettez à jour GRUB le cas échéant (`sudo update-grub`) – normalement fait automatiquement – puis redémarrez en choisissant votre noyau personnalisé. Une fois démarré, vous pouvez vérifier avec `uname -r` que c’est bien la version custom. Vos **modules intégrés** apparaîtront comme faisant partie du noyau : ils **ne figureront pas dans `lsmod`** (puisqu’ils ne sont pas dynamiques) ([Difference between Linux Loadable and built-in modules - Stack Overflow](https://stackoverflow.com/questions/22929065/difference-between-linux-loadable-and-built-in-modules#:~:text=Note%3A%20,in%60%20ones)). Par exemple, si vous aviez intégré un pilote auparavant modulaire, la commande `lsmod` ne le listera plus, mais la fonctionnalité sera bien active (et visible éventuellement via `/proc/devices` ou autres). D’autre part, ces modules intégrés ne pourront pas être retirés à chaud (pas de `rmmod` possible) – il faudrait recompiler un noyau pour les enlever. 

En synthèse, compiler un noyau personnalisé Debian implique de choisir quels composants compiler en module ou en dur, puis d’utiliser les outils Debian (`make-kpkg`) pour produire un noyau installable proprement. Intégrer un module “en dur” (Y) le lie statiquement au noyau : il est chargé dès l’amorçage et occupe la mémoire en permanence ([Difference between Linux Loadable and built-in modules - Stack Overflow](https://stackoverflow.com/questions/22929065/difference-between-linux-loadable-and-built-in-modules#:~:text=Linux%20kernel%20supports%20inserting%20of,in%20two%20ways)) ([Difference between Linux Loadable and built-in modules - Stack Overflow](https://stackoverflow.com/questions/22929065/difference-between-linux-loadable-and-built-in-modules#:~:text=The%20advantage%20the%20loadable%20modules,new%20image%20of%20the%20kernel)), mais offre l’avantage d’être toujours disponible (utile pour les pilotes de démarrage) et d’éviter la surcharge d’un module séparé. À l’inverse, laisser un composant en module (M) permet de le charger uniquement en cas de besoin et de le décharger pour économiser de la mémoire, au prix d’une flexibilité légèrement moindre (il nécessite un initrd ou un chargement explicite) ([Difference between Linux Loadable and built-in modules - Stack Overflow](https://stackoverflow.com/questions/22929065/difference-between-linux-loadable-and-built-in-modules#:~:text=The%20advantage%20the%20loadable%20modules,new%20image%20of%20the%20kernel)). Le choix se fait donc au cas par cas, en fonction de vos besoins en performances, mémoire, et du degré de modularité souhaité. Grâce à la méthode Debian (paquets kernel-image), on bénéficie en plus de la facilité de gestion : vous pouvez toujours revenir à l’ancien noyau en cas de problème, et les mises à jour de sécurité Debian ne s’appliqueront qu’au noyau générique (votre noyau custom étant sous votre responsabilité). 

**Illustration :** si vous intégrez en dur un pilote (par ex. support d’un système de fichiers), celui-ci sera directement initialisé au boot. Si plus tard vous modifiez ce pilote, il faudra recompiler tout le noyau et rebooter. En revanche, s’il reste modulaire, vous pourriez simplement recompiler le module et le recharger à chaud pour tester des changements. C’est le compromis entre *module intégré* et *module chargeable*. En règle générale, on intègre en dur les éléments indispensables au démarrage ou à la sécurité, et on laisse modulaires les composants optionnels ou périphériques. 

**Sources :** La documentation Debian et la communauté fournissent de nombreuses ressources sur ce processus. Le *Debian Kernel Handbook* notamment détaille la procédure de compilation d’un noyau Debian. Les pages de manuel de `make-kpkg` décrivent les options disponibles (par exemple, comment inclure/exclure certains modules) ([Ubuntu Manpage:

       make-kpkg - Construction de paquets Debian du noyau à partir des sources du noyau Linux
    ](https://manpages.ubuntu.com/manpages/trusty/fr/man1/make-kpkg.1.html#:~:text=make)). N’hésitez pas à vous y référer pour des personnalisations plus poussées. Bon courage pour la compilation de votre noyau personnalisé !  

