Je vais préparer une explication détaillée pour chaque étape du processus de gestion du noyau Linux, avec des exemples concrets et des commandes précises. 

D'abord, j'expliquerai la procédure **générale** applicable à toutes les distributions Linux :
- Téléchargement des sources et des outils nécessaires.
- Paramétrage avancé du noyau.
- Compilation et installation en suivant la méthode classique.
- Intégration des drivers et outils spécifiques.

Ensuite, j'ajouterai une section détaillée **spécifique à Debian**, en expliquant comment Debian gère la compilation et l'installation du noyau avec ses propres outils (tels que `make-kpkg`).

Je vais inclure des commandes pratiques, des précisions sur les options de configuration, et je fournirai des schémas si nécessaire pour visualiser les concepts.

## Partie 1 : Approche Générale

### 1. Téléchargement des sources et des outils nécessaires

Pour compiler le noyau Linux, il faut d’abord récupérer son **code source officiel** et installer les **outils de compilation** requis. Le code source du noyau Linux est disponible sur le site officiel **kernel.org**, qui répertorie les versions *mainline* (développement), *stables* et *LTS* (support long terme). On peut soit cloner le dépôt Git de Linus Torvalds, soit télécharger l’archive de la version stable souhaitée (fichiers `.tar.xz`) depuis kernel.org ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=Dans%20un%20premier%20temps%20il,org)). Par exemple, pour télécharger la version 6.1.8, on utiliserait : 

```bash
wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.1.8.tar.xz 
tar -xvf linux-6.1.8.tar.xz && cd linux-6.1.8
``` 

Une autre option sur Debian est d’**installer le paquet source** correspondant (`apt install linux-source-version`), qui place une archive du code source (ex: `/usr/src/linux-source-5.10.tar.xz`) qu’il suffit d’extraire dans un répertoire de travail utilisateur ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/jessie/sect.kernel-compilation.html#:~:text=Ainsi%20donc%2C%20le%20paquet%20linux,kernel%2F%60%20conviendra)). Il est conseillé de *ne pas compiler en root* ni dans `/usr/src` directement, mais dans un dossier de son *HOME* (par ex. `~/kernel/`), pour éviter tout problème de permission ou de conflit avec le système ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/wheezy/sect.kernel-compilation.html#:~:text=Ainsi%20donc%2C%20le%20paquet%20linux,kernel%2F%60%20conviendra)) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/wheezy/sect.kernel-compilation.html#:~:text=Traditionnellement%2C%20les%20sources%20du%20noyau,risque%20d%27induire%20en%20erreur%20les)).

Ensuite, installez les **outils de build** nécessaires. Sur Debian/Ubuntu, le paquet meta `build-essential` fournit le compilateur C (GCC) et make. Il faut également les bibliothèques de développement Ncurses (pour l’interface menuconfig), et d’autres utilitaires. Par exemple : 

```bash
sudo apt install build-essential libncurses-dev bison flex libssl-dev libelf-dev bc
``` 

Cette commande installe GCC, Make, les bibliothèques Ncurses, Bison, Flex, OpenSSL (pour certaines options cryptographiques) et libelf (pour la génération de BPF, etc.) ([Configuring the Linux Kernel: Mastering make menuconfig - Shapehost](https://shape.host/resources/configuring-the-linux-kernel-mastering-make-menuconfig#:~:text=,dev%60%20%28for%20Debian%2FUbuntu)). D’autres distributions ont des noms de paquets légèrement différents, mais ces composants sont généralement requis. Il peut être utile aussi d’installer `git` (si on souhaite cloner la dernière version du code source) et `fakeroot` (pour créer des paquets sans privilèges root, utile en méthode Debian).

Enfin, regardons **l’organisation des fichiers source du noyau** pour mieux s’y repérer. Une fois l’archive extraite, on obtient un répertoire (ex: `linux-6.1.8/`) contenant de nombreux sous-dossiers. Les principaux sont :

- `arch/` – code spécifique à chaque architecture processeur (x86, ARM, etc.) ([linux kernel - Study device driver source files? - Stack Overflow](https://stackoverflow.com/questions/37680905/study-device-driver-source-files#:~:text=Linux%20Source%20directory%20and%20description,)). Par exemple, `arch/x86` contient le code propre aux PC 32/64 bits.
- `drivers/` – l’ensemble des pilotes de périphériques du noyau, classés par type de matériel (son, réseau, USB, etc.) ([linux kernel - Study device driver source files? - Stack Overflow](https://stackoverflow.com/questions/37680905/study-device-driver-source-files#:~:text=%2A%20drivers%2F%20,into%20classes%20of%20device%20driver)).
- `fs/` – implémentations des systèmes de fichiers (ext4, NTFS, FAT, etc.), chaque sous-dossier correspondant à un FS supporté ([linux kernel - Study device driver source files? - Stack Overflow](https://stackoverflow.com/questions/37680905/study-device-driver-source-files#:~:text=sending%20the%20computer)).
- `kernel/` – le cœur du noyau (ordonnanceur, gestion du temps, synchronisation, etc.).
- `mm/` – la gestion de la mémoire (avec des parties spécifiques par archi dans `arch/*/mm/`).
- `net/` – la pile réseau du noyau (protocoles, sockets...).
- `include/` – fichiers d’en-tête (.h) partagés.
- `scripts/` – scripts utilitaires pour la configuration et la compilation.

*(Ce ne sont que quelques exemples ; on trouve aussi `crypto/` (algos de chiffrement), `sound/` (pilotes audio), `Documentation/` (guides et docs du noyau), etc.)*

### 2. Paramétrage du noyau avancé

Avant de compiler, il faut **configurer le noyau** selon vos besoins matériels et fonctionnels. La configuration détermine quels pilotes et options seront compilés (intégrés ou en modules). La méthode classique est d’utiliser l’interface semi-graphique **`make menuconfig`**. Positionnez-vous dans le répertoire des sources du noyau extrait, puis lancez :

```bash
make menuconfig
``` 

 ([image]()) **Figure :** Interface de configuration du noyau via `make menuconfig`. Cet utilitaire en mode texte (basé sur ncurses) affiche une arborescence de menus et sous-menus pour activer/désactiver les fonctionnalités du noyau. On y voit par exemple les catégories principales *General setup*, *Processor type and features*, *Power management*, *Device Drivers*, etc. La navigation se fait avec les flèches directionnelles, Entrée pour entrer dans un sous-menu, et *Esc* (ou sélectionner “Exit”) pour remonter ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/wheezy/sect.kernel-compilation.html#:~:text=,Le)). La barre d’état indique les raccourcis (touche **Y** pour inclure une option, **N** pour l’exclure, **M** pour la mettre en module). Un `[ * ]` devant une option signifie qu’elle sera **compilée en dur** dans le noyau, `[ M ]` indique qu’elle sera compilée sous forme de **module chargeable dynamiquement**, et `[ ]` qu’elle est **désactivée** (non compilée) ([Configurer, Compiler et Installer un noyau Linux personnalisé — openSUSE Wiki](https://fr.opensuse.org/Configurer,_Compiler_et_Installer_un_noyau_Linux_personnalis%C3%A9#:~:text=Il%20y%20a%20typiquement%202,un%20driver%20dans%20votre%20syst%C3%A8me)). Il est recommandé de n’inclure en dur que les éléments indispensables au démarrage ou au fonctionnement critique, et de mettre en modules les pilotes optionnels pour charger ceux-ci à la demande (ce qui allège le noyau et la consommation mémoire) ([Configurer, Compiler et Installer un noyau Linux personnalisé — openSUSE Wiki](https://fr.opensuse.org/Configurer,_Compiler_et_Installer_un_noyau_Linux_personnalis%C3%A9#:~:text=Il%20y%20a%20typiquement%202,un%20driver%20dans%20votre%20syst%C3%A8me)).

L’interface de menuconfig est organisée par **grandes sections** thématiques. Parmi les principales options de configuration, on retrouve par exemple : 

- **General setup** – options générales du noyau (ex. définir une **version locale** personnalisée qui s’ajoutera au numéro de version du noyau, utile pour distinguer votre build) ([Configuring the Linux Kernel: Mastering make menuconfig - Shapehost](https://shape.host/resources/configuring-the-linux-kernel-mastering-make-menuconfig#:~:text=,%E2%80%93%20append%20to%20kernel%20release)).
- **Processor type and features** – options liées au processeur et à l’architecture (optimiser le noyau pour un type de CPU spécifique, activer/désactiver le support de SMP, de l’hyperthreading, etc.) ([Configuring the Linux Kernel: Mastering make menuconfig - Shapehost](https://shape.host/resources/configuring-the-linux-kernel-mastering-make-menuconfig#:~:text=,%E2%80%93%20append%20to%20kernel%20release)).
- **Power management and ACPI options** – gestion de l’énergie, suspendre/réveil, ACPI… (particulièrement important pour les portables) ([Configuring the Linux Kernel: Mastering make menuconfig - Shapehost](https://shape.host/resources/configuring-the-linux-kernel-mastering-make-menuconfig#:~:text=Tailor%20your%20kernel%20to%20specific,CPU%20types%20for%20better%20performance)).
- **Networking support** – prise en charge des protocoles réseau (IPv6, IPsec, Bluetooth, etc.) et des options de sécurité réseau ([Configuring the Linux Kernel: Mastering make menuconfig - Shapehost](https://shape.host/resources/configuring-the-linux-kernel-mastering-make-menuconfig#:~:text=,devices%20to%20optimize%20power%20usage)).
- **Device Drivers** – configuration des pilotes de périphériques : carte graphique, adaptateurs réseau, stockage, USB... On peut y activer ou non le support de certains matériels en fonction de son PC ([Configuring the Linux Kernel: Mastering make menuconfig - Shapehost](https://shape.host/resources/configuring-the-linux-kernel-mastering-make-menuconfig#:~:text=,protocols%20as%20per%20your%20requirements)).
- **File systems** – support des systèmes de fichiers (ext4, Btrfs, NFS, etc.) qu’on souhaite inclure ([Configuring the Linux Kernel: Mastering make menuconfig - Shapehost](https://shape.host/resources/configuring-the-linux-kernel-mastering-make-menuconfig#:~:text=Enable%20or%20disable%20network%20protocols,as%20per%20your%20requirements)).
- *(Et ainsi de suite : options de sécurité (SELinux, AppArmor…), cryptographie, virtualisation, « Kernel hacking » pour le debug, etc.)*

Chaque option est accompagnée d’une aide (touche **H** ou **?** sur l’élément sélectionné) qui explique sa fonction plus en détail. N’hésitez pas à consulter ces aides pour les options avancées afin de faire des choix éclairés. 

**Personnalisation avancée :** Vous pouvez charger une base de configuration existante pour ne pas repartir de zéro. Par exemple, il est courant de **réutiliser la configuration du noyau actuellement installé** sur votre système comme point de départ. Sur Debian/Ubuntu, le fichier de config du noyau courant se trouve dans `/boot` (ex: `config-5.10.0-17-amd64`). Copiez-le dans le répertoire des sources sous le nom `.config` avant de lancer menuconfig : 

```bash
cp /boot/config-$(uname -r) .config
``` 

Ainsi, vous partez d’une config connue (généralement celle du noyau générique de la distribution) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/wheezy/sect.kernel-compilation.html#:~:text=possible%20de%20la%20configuration%20standard,r%C3%A9pertoire%20des%20sources%20du%20noyau)). Ensuite, exécutez `make menuconfig` et ne modifiez que ce qui vous intéresse. Si le noyau que vous compilez est d’une version différente de celui d’origine, utilisez la cible **`make oldconfig`** pour mettre à jour la config : elle vous posera des questions seulement pour les nouvelles options apparues depuis ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/wheezy/sect.kernel-compilation.html#:~:text=ASTUCE%20Que%20faire%20d%27un%20,obsol%C3%A8te)) (vous pouvez aussi faire `make olddefconfig` pour accepter les options par défaut sans interactivité). 

Parmi les **options avancées**, on peut citer la personnalisation de la chaîne de version locale du noyau (option “Local Version” dans *General setup* – par exemple ajouter “-custom” au nom du kernel), l’activation de fonctionnalités expérimentales (en activant “Prompt for development and/or incomplete drivers” dans *General setup*), ou encore le choix de compiler ou non certaines options de debug du noyau (dans *Kernel hacking*). Ces réglages peuvent aider à identifier votre noyau custom et ajuster son comportement. 

En résumé, prenez le temps nécessaire pour configurer le noyau selon vos besoins. Une configuration minimaliste ciblée sur votre matériel permettra un noyau plus léger et performant, tandis qu’une configuration large (proche de celle des distributions) assure une compatibilité maximale. **Sauvegardez** votre configuration (`Save an Alternate Configuration File`) si vous souhaitez la réutiliser plus tard. Toutes les options choisies sont enregistrées dans le fichier caché `.config` à la racine des sources ([How to Compile the Linux Kernel : 7 Steps - Instructables](https://www.instructables.com/How-to-Compile-the-Linux-Kernel/#:~:text=Configuring%20the%20kernel%20can%20be,root%20directory%20of%20the%20kernel)) ([How to Compile the Linux Kernel : 7 Steps - Instructables](https://www.instructables.com/How-to-Compile-the-Linux-Kernel/#:~:text=The%20kernel%20can%20be%20configured,ncurses%20interface%20with%20the%20command)).

### 3. Compilation et installation du noyau (méthode classique)

Une fois la configuration prête, passons aux **étapes de compilation et d’installation** du noyau. La méthode « classique » consiste à utiliser directement Make pour construire le noyau et ses modules, puis à installer le tout manuellement. Voici les étapes détaillées :

**Étape 1 : Compilation du noyau** – On lance la compilation à proprement parler via la commande `make`. Il est recommandé d’utiliser l’option `-j` pour paralléliser la compilation en fonction du nombre de cœurs CPU disponibles (par ex. `make -j$(nproc)` utilise tous les cœurs) ([How to Compile the Linux Kernel : 7 Steps - Instructables](https://www.instructables.com/How-to-Compile-the-Linux-Kernel/#:~:text=Step%206%3A%20Compiling%20the%20Kernel)). Depuis le répertoire racine des sources du noyau :

```bash
make -j$(nproc)
``` 

Cette commande va compiler l’image du noyau (généralement un fichier binaire compressé appelé **bzImage**) ainsi que tous les modules configurés. La durée peut varier de quelques minutes à plus d’une heure selon la taille du noyau et la puissance de la machine. À la fin, on doit voir un message indiquant que le **bzImage** du noyau est prêt (par exemple : *“Kernel: arch/x86/boot/bzImage is ready”* ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=,1))). Si des erreurs surviennent, il faudra les corriger (souvent il manque un paquet de développement requis, ou une option de config incompatible). 

**Étape 2 : Installation des modules** – Une fois le noyau compilé, il faut installer les modules du noyau (les pilotes compilés en module “[M]”). Cette étape copie tous les fichiers `.ko` (kernel objects) générés vers le répertoire système approprié (`/lib/modules/<version-du-noyau>/`). On l’exécute avec les privilèges root :

```bash
sudo make modules_install
``` 

Cette commande va installer chaque module au bon endroit et mettre à jour l’index des modules (via `depmod`) pour le noyau cible ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=INSTALL%20net%2Fnetfilter%2Fxt_mark,8)). Par exemple, on verra défiler la liste des modules installés (pilotes divers) et un message **DEPMOD** en fin de processus ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=%24%20sudo%20make%20modules_install%20INSTALL,t.ko)) ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=INSTALL%20net%2Fnetfilter%2Fxt_mark,8)). Après cela, le répertoire `/lib/modules/$(make kernelrelease)` contient tous les modules du nouveau noyau. À noter : si vous recompilez un noyau avec *exactement la même version* qu’un noyau déjà installé, `make modules_install` risque d’écraser le répertoire de modules existant. Pour éviter tout conflit, assurez-vous que le *EXTRAVERSION* (ou LOCALVERSION) diffère, ou déplacez/renommez l’ancien dossier de modules avant d’installer (par exemple, sauvegarde en `.old`). Dans le cas général (noyau de version unique), cela ne pose pas de problème car la version du nouveau noyau est différente de l’ancien, donc le répertoire de modules est distinct.

**Étape 3 : Installation de l’image du noyau** – Ensuite, on installe le noyau lui-même ainsi que les fichiers associés dans **`/boot`**. Si votre distribution utilise un initramfs, il faut également générer cette image de démarrage. La manière la plus simple d’effectuer ces opérations est d’utiliser la cible Make **`make install`**, qui copie le noyau compilé et lance les hooks nécessaires : 

```bash
sudo make install
``` 

Cette commande copie le fichier du noyau (bzImage) vers `/boot/vmlinuz-<version>`, installe également le fichier **System.map** correspondant (table des symboles du noyau) et parfois le fichier de config utilisé (`/boot/config-<version>`). Sur les systèmes modernes (Debian/Ubuntu par exemple), `make install` va automatiquement déclencher la génération de l’**initramfs** et la mise à jour du chargeur de démarrage via des scripts post-install ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=Nous%20avons%20install%C3%A9%20les%20nouveaux,)) ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=run,4.9.0)). En effet, on voit dans la sortie qu’il exécute des scripts comme **`/etc/kernel/postinst.d/initramfs-tools`** (qui lance `update-initramfs` pour créer l’initrd) et **`.../zz-update-grub`** (qui lance `update-grub`) ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=%2Fboot%2Fvmlinuz,notifier%204.11.8)) ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=run,4.11.8)). L’**initrd** (ou **initramfs**) est un disque mémoire initial contenant les modules nécessaires au montage des systèmes de fichiers importants au démarrage (par ex. pilotes du contrôleur de disques, du système de fichiers racine, etc.). Il se retrouve généralement sous `/boot/initrd.img-<version>` ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=run,4.11.8)). Le fichier **System.map** est la table des symboles du noyau, utile pour le débogage et pour les utilitaires comme klogd ([Configurer, Compiler et Installer un noyau Linux personnalisé — openSUSE Wiki](https://fr.opensuse.org/Configurer,_Compiler_et_Installer_un_noyau_Linux_personnalis%C3%A9#:~:text=,n%C3%A9cessaire%20au%20d%C3%A9marrage%20du%20noyau)).

Si votre distribution n’automatise pas ces étapes, il faudra peut-être créer l’initramfs manuellement avec l’outil approprié (`mkinitramfs` sur Debian, `mkinitcpio` sur Arch, etc.) et mettre à jour le chargeur d’amorçage. Pour **GRUB**, la commande suivante régénère le menu en détectant les noyaux présents dans `/boot` :

```bash
sudo update-grub
``` 

(ou `sudo grub-mkconfig -o /boot/grub/grub.cfg` selon les distributions). Sur les distributions Debian/Ubuntu, ce n’est généralement pas nécessaire de le faire à la main car, comme vu plus haut, l’installation du noyau l’a déjà fait automatiquement ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=run,4.9.0)). Vérifiez néanmoins qu’une entrée pour votre nouveau noyau apparaît bien dans `/boot/grub/grub.cfg`. Si vous utilisez un autre chargeur comme **LILO**, il faudra éditer `/etc/lilo.conf` pour ajouter le nouveau noyau et lancer `sudo lilo` pour mettre à jour le MBR ([Compilation du noyau sous Debian - Lea Linux](https://lea-linux.org/documentations/Compilation_du_noyau_sous_Debian#:~:text=Si%20vous%20utilisez%20%27,2.0.36%27%60%20par%20exemple)).

Après ces étapes, votre nouveau noyau est installé. On peut vérifier que tout est en place dans `/boot` : on doit y voir `vmlinuz-<version>` (l’image binaire du noyau), `initrd.img-<version>` (si votre config nécessite un initrd), et `System.map-<version>` ([Configurer, Compiler et Installer un noyau Linux personnalisé — openSUSE Wiki](https://fr.opensuse.org/Configurer,_Compiler_et_Installer_un_noyau_Linux_personnalis%C3%A9#:~:text=Le%20noyau%20est%20compos%C3%A9%20de,3%20parties)). Par exemple : 

```bash
ls -l /boot
# ... vmlinuz-5.15.8, initrd.img-5.15.8, System.map-5.15.8, config-5.15.8 ...
``` 

Il ne reste plus qu’à **redémarrer** sur le nouveau noyau. Au menu de GRUB, choisissez la nouvelle entrée (généralement sélectionnée par défaut si c’est le noyau le plus récent). Une fois le système démarré, confirmez que c’est bien le bon noyau qui tourne avec `uname -r` (qui doit afficher la version que vous avez compilée). Par exemple, après l’installation réussie du noyau 4.11.8 dans un système, `uname -a` affiche bien la nouvelle version et la date de compilation correspondante ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=Pour%20v%C3%A9rifier%20l%E2%80%99application%20du%20nouveau,comme%20ceci)) ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=%24%20date%20Sun%20Jul%20,2%2012%3A12%3A32%20EDT%202017)). Félicitations, vous avez compilé et démarré sur votre propre noyau Linux !

**Gestion des modules et firmwares :** les modules du noyau ont été installés dans `/lib/modules/<version>/`. Vous pouvez à tout moment activer un module (pilote optionnel) en utilisant `modprobe <nom_du_module>` ou le désactiver avec `rmmod`. Pensez à ajouter les modules importants à charger au démarrage (ex: via `/etc/modules` sur Debian) si vous avez compilé en module des éléments nécessaires dès l’amorçage. Concernant les **firmwares** (microcodes nécessaires à certains périphériques comme les cartes Wi-Fi, GPU, etc.), notez qu’ils ne sont généralement **pas inclus** dans le code source du noyau pour des raisons de licence. Beaucoup de pilotes prévoient le chargement d’un fichier firmware depuis `/lib/firmware` au moment de l’initialisation du matériel. Assurez-vous donc d’installer les paquets de firmware adéquats de votre distribution le cas échéant (ex: `firmware-linux-nonfree` sur Debian pour les firmwares propriétaires courants). Il est aussi possible d’inclure certains firmwares directement dans l’image du noyau en activant l’option **CONFIG_FIRMWARE_IN_KERNEL** et en spécifiant lesquels, mais la méthode la plus simple reste de copier les fichiers firmwares requis dans `/lib/firmware` (ou de passer par les paquets officiels). Si un firmware manque, le pilote concerné le signalera dans les logs (dmesg) lors du chargement du module : vous verrez une erreur du type “`firmware: failed to load ...`”.

### 4. Intégration de drivers et outils spécifiques

Dans certains cas, vous aurez besoin d’ajouter au noyau des éléments supplémentaires : par exemple un pilote matériel **externe** (qui n’est pas inclus dans les sources officielles) ou un **module tiers** (module externe au noyau, comme les pilotes NVIDIA propriétaires, VirtualBox, etc.). Voici comment intégrer ces composants spécifiques :

- **Compilation de modules externes avec DKMS :** L’outil **DKMS (Dynamic Kernel Module Support)** facilite grandement la gestion des modules hors arbre (*out-of-tree*). Il permet de compiler automatiquement un module tiers pour chaque version de noyau installée, et de le recompiler en cas de mise à jour du noyau. Sur Debian, de nombreux pilotes externes sont fournis sous forme de paquets se terminant par `-dkms`. Par exemple, pour ajouter des modules iptables supplémentaires, il suffit d’installer `xtables-addons-dkms` : l’installation du paquet va automatiquement compiler et installer le module pour le noyau courant (à condition que les en-têtes du noyau correspondant soient présents) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/jessie/sect.kernel-compilation.html#:~:text=pourrions%20extraire%20cette%20archive%20et,amd64)) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/jessie/sect.kernel-compilation.html#:~:text=%24%20sudo%20apt%20install%20xtables)). Concrètement, DKMS va récupérer le code source du module (souvent dans `/usr/src/<module>-<version>/`), puis l’intégrer au noyau en cours. On peut vérifier l’état avec `dkms status` (le module apparaît alors “installed” pour la version du noyau) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/jessie/sect.kernel-compilation.html#:~:text=,ipt_ACCOUNT)) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/jessie/sect.kernel-compilation.html#:~:text=DKMS%3A%20install%20completed,IP%20accounting%20for%20large%20prefixes)). **Avantage :** à chaque installation d’un nouveau noyau, DKMS recompilera automatiquement les modules externes enregistrés, ce qui évite de le faire manuellement. Si vous avez un pilote propriétaire (ex: NVIDIA), son installeur peut utiliser DKMS pour automatiser la recompilation à chaque changement de noyau.

- **Ajout de pilotes non inclus par défaut :** Si le pilote que vous souhaitez ajouter n’existe pas en paquet DKMS, vous avez deux approches. **(1)** *Compilation externe simple:* Si vous disposez des sources du module (par ex. un fichier driver.c + Makefile fournis par le fabricant), vous pouvez le compiler en utilisant les en-têtes du noyau que vous avez installés. Il suffit d’installer le paquet `linux-headers-<version>` correspondant à votre noyau (si vous avez compilé manuellement, vous pouvez générer et installer ces en-têtes avec `make headers_install`). Ensuite, depuis le dossier du module, une commande du type `make -C /usr/src/linux-headers-<version> M=$(pwd) modules` lancera la compilation du module avec le bon contexte. Vous obtiendrez un fichier .ko que vous pourrez charger avec `insmod` ou installer dans `/lib/modules/<version>/extra` puis charger via modprobe. **(2)** *Recompiler un noyau patché :* c’est la méthode à utiliser si le pilote nécessite des modifications profondes ou un patch du noyau. De nombreux projets fournissent des *patches* à appliquer au code source du noyau vanilla. Par exemple, Debian fournit des paquets `linux-patch-*` contenant des ensembles de patches (sécurité GrSecurity, RT pour temps réel, etc.) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/jessie/sect.kernel-compilation.html#:~:text=soient%20diffus%C3%A9es%20sous%20la%20forme,sur%20les%20sources%20du%20noyau)). Pour appliquer un patch, on place généralement le fichier patch (.patch ou .diff) dans le répertoire des sources et on exécute la commande `patch -p1 < mon_patch.diff` (ou équivalent). Sous Debian, les patches des paquets sont souvent compressés (fichiers `.gz` dans `/usr/src/kernel-patches/`), on peut les appliquer avec zcat comme dans l’exemple ci-dessous : 

    ```bash
    cd ~/kernel/linux-5.10.8
    make clean            # nettoyage de l'ancienne compilation
    zcat /usr/src/kernel-patches/diffs/monpatch/patchfile.gz | patch -p1
    ``` 

    (Ici on nettoie d’abord l’arbre des sources, puis on applique le patch) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/jessie/sect.kernel-compilation.html#:~:text=Pour%20appliquer%20un%20ou%20plusieurs,compilation%20du%20noyau%20comme%20pr%C3%A9c%C3%A9demment)). Après application, on recompilera le noyau comme vu précédemment. Le nouveau pilote patché sera alors inclus dans le noyau ou disponible en module. *Remarque :* l’application de patches du noyau peut provoquer des rejets si le patch ne correspond pas exactement à la version des sources, il faut donc idéalement partir de la version de noyau cible préconisée par le fournisseur du patch.

- **Test et validation des nouveaux modules :** Une fois un module externe compilé (que ce soit via DKMS ou manuellement), il convient de le tester. Assurez-vous que le module apparaît dans la liste avec `modinfo <module.ko>` ou `modprobe -n <nom>` (pour une simulation de chargement). Chargez-le avec `sudo modprobe <nom_du_module>` puis vérifiez avec `lsmod` qu’il est bien listé comme chargé. Surveillez `dmesg` ou `/var/log/kern.log` pour voir les messages du noyau relatifs au chargement du module : le pilote y logge souvent des informations, ou d’éventuelles erreurs (symboles inconnus, firmware manquant, etc.). Si le module remplace une version existante du noyau (par ex. vous testez une version plus récente d’un pilote réseau déjà présent dans le noyau), il peut être nécessaire de *blacklister* l’ancien module ou de démarrer avec l’option modprobe adéquate. En cas de succès, testez la fonctionnalité apportée par le module : par exemple, si c’est un pilote de périphérique, vérifiez que le matériel est bien reconnu (apparition d’une interface réseau, montage d’un système de fichiers, etc. selon le cas). Pour que le module soit disponible à chaque redémarrage, installez-le au besoin (copie du .ko dans `/lib/modules/<ver>/...` suivie d’un `depmod -a` si ce n’était pas déjà fait) et ajoutez-le dans l’initramfs ou les fichiers de config de modules à charger au boot si nécessaire.

En somme, l’intégration de pilotes et outils supplémentaires peut se faire sans recompiler entièrement le noyau grâce aux modules dynamiques. **DKMS** est votre allié pour automatiser cela sur le long terme, tandis que l’application de **patches** permet d’étendre les capacités du noyau lui-même lorsque requis. N’oubliez pas de bien tester en situation réelle et de conserver une sauvegarde de votre ancien noyau en cas de problème.

## Partie 2 : Méthode Spécifique à Debian

Les distributions Debian et dérivées proposent des outils pour faciliter la compilation du noyau en en faisant un paquet `.deb` gérable par le système. Cela permet d’installer/désinstaller proprement le noyau comme n’importe quel paquet, et d’automatiser certaines étapes (initramfs, bootloader). Nous allons détailler la méthode traditionnelle utilisant **`make-kpkg`** (fournie par le paquet *kernel-package*), ainsi que les particularités de la gestion Debian.

### 1. Méthode Debian avec `make-kpkg`

**Installation des outils Debian :** Assurez-vous d’abord d’installer les paquets spécifiques Debian nécessaires. Il vous faut le paquet **`kernel-package`** (qui fournit la commande `make-kpkg`), ainsi que les outils de compilation usuels et quelques dépendances : 

```bash
sudo apt install build-essential kernel-package libncurses5-dev fakeroot
``` 

- `build-essential` fournit gcc, make, etc. ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/wheezy/sect.kernel-compilation.html#:~:text=Les%20sources%20amont%20du%20noyau,utiliser%20les%20droits%20de%20l%27administrateur)).
- `kernel-package` fournit *make-kpkg* (utilitaire pour construire des paquets Debian du noyau).
- `libncurses5-dev` est requis pour `make menuconfig` ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/wheezy/sect.kernel-compilation.html#:~:text=Les%20sources%20amont%20du%20noyau,utiliser%20les%20droits%20de%20l%27administrateur)).
- `fakeroot` permet de construire le paquet sans être root (il simule les privilèges root pendant la création des fichiers du paquet) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/wheezy/sect.kernel-compilation.html#:~:text=Les%20sources%20amont%20du%20noyau,utiliser%20les%20droits%20de%20l%27administrateur)).

**Récupération des sources :** Vous pouvez utiliser soit les sources *officielles* du noyau (tarball de kernel.org), soit les sources *Debian*. Pour la méthode Debian, il est souvent pratique d’installer le paquet source Debian correspondant, par exemple : 

```bash
sudo apt install linux-source-5.10
``` 

Cela place une archive dans `/usr/src` (ex: `/usr/src/linux-source-5.10.tar.xz`) qu’il faut extraire dans un répertoire de travail (non root, par ex `~/kernel/`) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/jessie/sect.kernel-compilation.html#:~:text=Ainsi%20donc%2C%20le%20paquet%20linux,kernel%2F%60%20conviendra)). L’avantage des sources Debian est qu’elles incluent déjà les correctifs appliqués par Debian (nous y reviendrons). Vous pouvez sinon utiliser l’archive vanilla de kernel.org si vous le préférez – la méthode fonctionnera tout de même.

**Configuration du noyau :** Placez-vous dans le répertoire des sources du noyau extrait. Vous pouvez copier la config existante de Debian pour avoir une base (cf. Partie 1) puis lancer `make menuconfig` pour ajuster les options comme souhaité. À ce stade, assurez-vous que le fichier `/etc/kernel-pkg.conf` (fourni par kernel-package) est correctement configuré si vous voulez personnaliser le nom de mainteneur ou d’autres champs du paquet (ce n’est pas obligatoire de le toucher). 

**Compilation et création du paquet `.deb` :** Avant de lancer la construction du paquet Debian, il est recommandé de nettoyer les éventuels résidus de compilations précédentes dans les sources :

```bash
make clean
``` 

Ensuite, on utilise la commande **`make-kpkg`** pour compiler **et empaqueter** le noyau. Cet outil va appeler en interne `make` avec les bonnes options, puis construire jusqu’à 2 paquets `.deb` principaux : l’image du noyau et les en-têtes (headers). La commande de base est :

```bash
fakeroot make-kpkg --initrd --revision=Custom.1.0 kernel_image kernel_headers
``` 

- L’option `--initrd` indique que le noyau que l’on compile nécessitera un initrd au boot (ce qui est le cas général sur Debian, car de nombreux drivers essentiels sont en module) – cela aura pour effet de générer un initramfs lors de l’installation du paquet.
- `--revision=Custom.1.0` définit le suffixe de version Debian du paquet (vous pouvez mettre ce que vous voulez à la place de "Custom.1.0" pour identifier votre build) ([Compilation du noyau sous Debian - Lea Linux](https://lea-linux.org/documentations/Compilation_du_noyau_sous_Debian#:~:text=%5Broot%40localhost%20linux%5D%23%20make,revision%3DCUSTOM.1.0%20kernel_image)). Ce suffixe évite de confondre avec un paquet officiel et permet d’installer plusieurs versions côte-à-côte.
- `kernel_image` et `kernel_headers` spécifient les cibles à construire : l’image du noyau et les fichiers d’en-tête (nécessaires pour compiler des modules externes contre ce noyau).

Pendant l’exécution, *make-kpkg* va compiler le noyau et les modules (similaire au `make` normal), puis emballer le tout. En sortie, vous obtiendrez dans le répertoire parent (.. ou `/usr/src` si vous avez compilé depuis `/usr/src/linux` par exemple) des fichiers `.deb` du type : 

- `linux-image-5.10.8_Custom.1.0_amd64.deb` – le paquet Debian contenant le noyau et ses modules ([Compilation du noyau sous Debian - Lea Linux](https://lea-linux.org/documentations/Compilation_du_noyau_sous_Debian#:~:text=%5Broot%40localhost%20linux%5D%23%20make,revision%3DCUSTOM.1.0%20kernel_image)).
- `linux-headers-5.10.8_Custom.1.0_amd64.deb` – le paquet contenant les en-têtes du noyau (pour compiler d’éventuels modules additionnels).

*(Remarque : selon la version de kernel-package, il peut générer aussi un paquet debug symboles et un paquet libc-dev, mais ce n’est pas systématique. Les principaux sont image et headers.)*

**Installation du noyau Debian personnalisé :** Une fois ces paquets créés, on les installe via l’outil de gestion de paquets Debian. Utilisez `dpkg -i` sur le paquet de l’image du noyau (et sur les headers si vous en avez besoin) :

```bash
sudo dpkg -i ../linux-image-5.10.8_Custom.1.0_amd64.deb 
sudo dpkg -i ../linux-headers-5.10.8_Custom.1.0_amd64.deb
``` 

(dpkg acceptera aussi plusieurs fichiers en même temps). L’installation du paquet va copier le noyau dans `/boot` (sous le nom `vmlinuz-5.10.8Custom.1.0` par ex), installer les modules dans `/lib/modules/5.10.8-...`, générer l’initramfs automatiquement et mettre à jour GRUB, exactement comme pour un noyau officiel ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=%2Fboot%2Fvmlinuz,notifier%204.11.8)) ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=run,4.9.0)). En effet, les scripts post-inst des paquets Debian (dans `/etc/kernel/postinst.d/`) se chargent de ces tâches. Vous verrez par exemple lors de l’installation des messages de `update-initramfs` puis `update-grub`. À l’issue de cette étape, votre noyau custom est “installé” du point de vue du système de paquet.

Il ne reste qu’à redémarrer sur le nouveau noyau, comme précédemment. La grande différence est que maintenant le noyau est géré via le système de paquets : on peut le retrouver avec `dpkg -l "linux-*"` comme tout paquet Debian.

**Avantages de la méthode make-kpkg :** Vous bénéficiez de l’intégration native Debian – le noyau s’installe proprement, et vous pouvez le désinstaller tout aussi proprement. C’est très pratique pour déployer le noyau compilé sur plusieurs machines : il suffit de transférer le .deb et de l’installer. De plus, cela évite d’éparpiller des fichiers non suivis par dpkg dans le système. Cette méthode était la recommandation officielle avant que les makefiles du noyau incluent une cible deb-pkg équivalente ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/wheezy/sect.kernel-compilation.html#:~:text=CULTURE%20Le%20bon%20vieux%20temps,package)). À noter qu’aujourd’hui, on peut aussi utiliser directement `make deb-pkg` depuis les sources du noyau pour obtenir les .deb sans passer par make-kpkg ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/wheezy/sect.kernel-compilation.html#:~:text=Une%20fois%20que%20la%20configuration,glibc)) – mais l’esprit reste le même.

### 2. Personnalisation des options spécifiques à Debian

Debian applique traditionnellement un certain nombre de **patches** et de configurations spécifiques à ses noyaux. Comprendre cela aide à reproduire un noyau “façon Debian” ou à adapter des fonctionnalités propres.

- **Patches Debian intégrés :** Lorsque vous utilisez les sources fournies par Debian (`linux-source-*`), sachez qu’elles incluent déjà des correctifs par rapport aux sources *vanilla* de kernel.org ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/jessie/sect.kernel-compilation.html#:~:text=sources%20contenus%20dans%20ces%20paquets,quelques%20fonctionnalit%C3%A9s%20sp%C3%A9cifiques%20%C3%A0%20Debian)). Ces patchs couvrent des correctifs de sécurité, des fonctionnalités backportées ou des adaptations à Debian. Par conséquent, un noyau compilé depuis les sources Debian aura par défaut un comportement proche du noyau officiel Debian. Si vous utilisez les sources vanilla, vous n’aurez pas ces patches – sauf à les appliquer vous-même. Debian distribue certains patches sous forme de paquets nommés `linux-patch-*` ou `kernel-patch-*` (par exemple `linux-patch-grsecurity2` pour ajouter GrSecurity) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/jessie/sect.kernel-compilation.html#:~:text=soient%20diffus%C3%A9es%20sous%20la%20forme,sur%20les%20sources%20du%20noyau)) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/jessie/sect.kernel-compilation.html#:~:text=Debian%20diffuse%20certains%20de%20ces,patches)). Après installation de tels paquets, les patches (souvent compressés) résident dans `/usr/src/kernel-patches/`. Vous pouvez les appliquer manuellement comme vu en Partie 1 (commande patch). Dans le cadre de make-kpkg, il est aussi possible de configurer l’application automatique de patches en définissant certaines variables dans `/etc/kernel-pkg.conf` (section **patch**). Consultez la documentation de kernel-package pour en savoir plus sur l’automatisation des patches. En résumé, Debian facilite l’ajout de correctifs connus, mais c’est à vous de les activer au besoin.

- **Configuration Debian par défaut :** Un noyau Debian standard est compilé avec une configuration très large pour supporter un maximum de matériels génériques. Si vous souhaitez conserver cette couverture tout en mettant à jour la version, il est judicieux de repartir du fichier de config Debian par défaut (comme on l’a fait en copiant depuis `/boot`). Cela vous évitera de manquer une option importante. Debian a tendance à modulariser le plus de composants possible (presque tout est en module sauf le strict nécessaire au boot). Si vous suivez cette approche, assurez-vous d’inclure l’initramfs (option `--initrd` déjà utilisée) afin que les modules nécessaires au démarrage soient pris en charge. 

  Debian fournit par ailleurs des *méta-paquets* comme `linux-image-amd64` qui dépendent de la dernière version de noyau disponible dans la distribution. Avec un noyau personnalisé, ces méta-paquets ne vous concernent plus, mais vous pouvez créer quelque chose d’analogue via la `LOCALVERSION` ou `--revision` pour que vos paquets customs suivent une numérotation particulière.

- **Outils automatiques (update-initramfs, update-grub) :** Comme mentionné, lorsque vous installez un noyau via un paquet Debian, vous n’avez normalement pas à appeler vous-même `update-initramfs` ou `update-grub` – tout est géré. Le script post-install du paquet *linux-image* va appeler `initramfs-tools` pour générer l’initrd (selon que `/etc/initramfs-tools/initramfs.conf` l’indique, en général oui) ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=%2Fboot%2Fvmlinuz,notifier%204.11.8)), puis il exécutera `/etc/kernel/postinst.d/zz-update-grub` qui met à jour la config GRUB ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=run,4.11.8)). On voit ainsi dans la sortie d’installation la détection de tous les noyaux installés pour regénérer le menu ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=Generating%20grub%20configuration%20file%20,4.9.0)). Si vous installez un noyau custom sur un système UEFI utilisant **Secure Boot**, notez que le paquet Debian va également tenter d’enregistrer le noyau pour qu’il soit bootable (signature DKMS, etc., selon la config Shim/SB). Sur une Debian Buster/Stretch, l’outil `debconf` pouvait poser la question d’ajouter une entrée de boot. Sur les versions récentes avec GRUB, ce n’est plus interactif, tout est automatique.

En somme, utiliser la méthode Debian revient à profiter de **l’infrastructure Debian** : patches faciles à appliquer, scripts d’installation rodés, et intégration transparente avec l’amorçage du système.

### 3. Gestion des mises à jour et maintenance

Maintenant que vous avez votre noyau personnalisé installé en paquet, comment gérer les évolutions et la maintenance ? Voici quelques conseils :

- **Coexistence de plusieurs versions de noyaux :** Il est tout à fait possible (et recommandé) de conserver **plusieurs noyaux installés** simultanément sur le système. Par exemple, garder l’ancien noyau fonctionnel en parallèle du nouveau, afin de pouvoir redémarrer dessus en cas de problème avec le noyau fraîchement compilé. GRUB va lister tous les noyaux présents dans `/boot`. Dans notre exemple de tout à l’heure, on voyait GRUB détecter plusieurs images (`5.9.0`, `4.11.8`, `4.9.0`, etc.) ([Compilation et installation du noyau Linux | matteyeux's blog](https://matteyeux.github.io/posts/compile-&-install-linux-krnl/#:~:text=Generating%20grub%20configuration%20file%20,4.9.0)). Le noyau par défaut au boot est généralement le plus récent (à moins de configurer le contraire). Debian a un mécanisme d’auto-nettoyage (**`apt autoremove`**) qui peut supprimer les vieux noyaux marqués comme obsolètes, mais il garde en principe au moins le dernier noyau actif. Si vous souhaitez empêcher la suppression automatique d’un noyau custom, faites attention à la configuration d’apt (les noyaux installés manuellement ne sont pas « automatiquement installés », donc apt ne devrait pas les enlever tout seul). En résumé, vous pouvez avoir par exemple un noyau officiels Debian (de secours) et votre noyau custom installés en parallèle sans conflit (leurs noms de fichiers incluent leurs versions spécifiques). 

- **Mise à jour du noyau personnalisé :** Contrairement aux noyaux des dépôts, votre noyau custom ne recevra pas de mises à jour de sécurité automatiques. C’est à vous de recompiler une nouvelle version quand nécessaire (par exemple si une faille critique est annoncée ou simplement pour passer à une version supérieure). Pour mettre à jour, vous pouvez reprendre le même processus : télécharger la nouvelle version des sources, recopier votre `.config` précédent (n’oubliez pas `make oldconfig` pour ajuster les nouvelles options), puis recompiler et générer un nouveau paquet `.deb`. Vous pouvez incrementer le `--revision` (ex: passer à Custom.1.1) pour que dpkg considère qu’il s’agit d’une version plus récente du paquet. **Important :** n’oubliez pas de garder au moins un noyau fonctionnel dans GRUB lors de vos tests de mise à jour, au cas où le nouveau pose problème. 

- **Désinstallation d’un noyau compilé manuellement :** Si vous souhaitez supprimer un ancien noyau, la procédure dépend de la méthode d’installation. S’il s’agit d’un noyau installé via un paquet Debian (make-kpkg ou deb-pkg), la **désinstallation propre** se fait avec les outils de paquet : par exemple `sudo apt remove linux-image-5.10.8-Custom.1.0` (ou `dpkg -r linux-image-5.10.8-Custom.1.0`). Cela va enlever les fichiers `/boot/vmlinuz-...`, `/boot/initrd-...` et le répertoire `/lib/modules/...` correspondant, puis mettre à jour GRUB automatiquement pour retirer l’entrée du menu. En revanche, si vous aviez **installé le noyau “à la main”** (via `make install` ou par simple copie) sans paquet, il faudra faire le nettoyage manuellement. Pour cela : 

  1. Éditer (ou générer) la config GRUB pour retirer l’entrée correspondante. Le plus simple est de supprimer les fichiers du noyau puis d’exécuter `update-grub` afin qu’il ne le détecte plus. 
  2. Supprimer les fichiers du noyau : par exemple  
     ```bash
     sudo rm /boot/vmlinuz-5.5.13 /boot/initrd.img-5.5.13 
     sudo rm /boot/System.map-5.5.13 /boot/config-5.5.13
     ``` 
     (le fichier config n’est présent que si vous l’aviez copié). 
  3. Supprimer le répertoire des modules : `sudo rm -rf /lib/modules/5.5.13/` ([Comment supprimer le noyau compilé manuellement : r/archlinux](https://www.reddit.com/r/archlinux/comments/fp557l/how_to_remove_manually_compiled_kernel/?tl=fr#:~:text=rm%20)).
  4. Mettre à jour GRUB : `sudo grub-mkconfig -o /boot/grub/grub.cfg` pour régénérer le menu sans ce noyau ([Comment supprimer le noyau compilé manuellement : r/archlinux](https://www.reddit.com/r/archlinux/comments/fp557l/how_to_remove_manually_compiled_kernel/?tl=fr#:~:text=Je%20suppose%20que%20je%20devrais,le%20faire)).  

  Après cela, vérifiez dans `/boot/grub/grub.cfg` que l’entrée du noyau en question a disparu. Cette procédure est valable pour toute distribution si le noyau n’a pas été empaqueté. *(Attention à ne pas supprimer le noyau sur lequel vous êtes en train de tourner ! vérifiez `uname -r`)*. 

- **Nettoyage des sources :** Après plusieurs compilations, votre répertoire de sources peut contenir des fichiers générés occupant de l’espace. N’hésitez pas à utiliser `make clean` ou même `make distclean` (ce dernier supprime aussi le .config) pour repartir sur une base propre avant une nouvelle compilation ou avant d’appliquer un patch. Vous pouvez aussi supprimer les anciens dossiers de sources si vous avez migré vers de nouvelles versions et que l’espace disque est un enjeu.

- **Maintenance générale :** Sur le long terme, gardez une trace des modifications que vous apportez (config particulière, patches appliqués) afin de pouvoir reproduire votre noyau custom. Pensez également à surveiller les annonces de sécurité du noyau (sur le site kernel.org ou les mailing-lists) puisque vous ne bénéficierez pas des mises à jour automatiques de Debian. Si une faille critique est annoncée dans la version que vous utilisez, il faudra envisager de passer à une version corrigée et recompiler. L’**outil apt-listchanges** peut vous aider à repérer les changements de la version Debian officielle, mais pour un noyau custom vous devrez comparer les changelogs vous-même.

En suivant ces conseils, vous devriez pouvoir gérer sereinement vos noyaux personnalisés sous Debian. Vous profitez ainsi du meilleur des deux mondes : la **personnalisation** fine du noyau Linux et la **stabilité** de la gestion de paquets Debian pour l’installation et la maintenance. Bon courage dans vos expérimentations avec le noyau Linux ! ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/wheezy/sect.kernel-compilation.html#:~:text=L%27%C3%A9quipe%20en%20charge%20du%20noyau,manqueraient%20%C3%A0%20la%20pr%C3%A9sente%20section)) ([8.10. Compilation d'un noyau](https://debian-handbook.info/browse/fr-FR/wheezy/sect.kernel-compilation.html#:~:text=Comme%20on%20peut%20s%27y%20attendre%2C,initrd))

**Sources :** _Compilation du noyau Linux - guide général et spécifique Debian, d’après la documentation Debian, kernel.org et retours d’expérience._