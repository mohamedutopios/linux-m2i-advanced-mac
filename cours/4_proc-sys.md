Je vais préparer une explication détaillée sur les pseudo-systèmes de fichiers `/proc` et `/sys` sous Debian, avec des exemples pratiques et des commandes spécifiques. J'ajouterai également des comparaisons avec d'autres systèmes Linux lorsque pertinent.

## 1. Présentation du pseudo-système de fichiers `/proc`  
Le répertoire `/proc` est un **pseudo-système de fichiers** exposant des informations du noyau. On parle de *pseudo*-système car son contenu est généré dynamiquement en mémoire par le noyau, et non stocké de façon permanente sur le disque ([procfs — Wikipédia](https://fr.wikipedia.org/wiki/Procfs#:~:text=Sur%20les%20syst%C3%A8mes%20%20du,proc)). En pratique, cela signifie que lire un fichier dans `/proc` interroge directement le noyau pour obtenir la donnée demandée. Ces fichiers apparaissent vides (`0` octet) si on liste leur taille avec `ls`, ce qui illustre qu’ils n’occupent pas d’espace disque réel (seule une petite quantité de mémoire vive est utilisée) ([procfs — Wikipédia](https://fr.wikipedia.org/wiki/Procfs#:~:text=est%20souvent%20mont%C3%A9%20sur%20le,proc)).  

Le pseudo-filesystem `/proc` joue un rôle d’**interface entre l’utilisateur et les structures de données du noyau** ([proc: process information, system information, and sysctl pseudo-filesystem | File Formats | Man Pages | ManKier](https://www.mankier.com/5/proc#:~:text=The%20proc%20filesystem%20is%20a,using%20a%20command%20such%20as)). Il a initialement été conçu pour fournir des infos sur les processus en cours d’exécution, d’où son nom *proc* (processus), mais il englobe aujourd’hui bien d’autres informations système. Sur Debian (comme sur la plupart des distributions Linux), `/proc` est **monté automatiquement** au démarrage par le système (généralement par le noyau ou le programme d’initialisation) ([proc: process information, system information, and sysctl pseudo-filesystem | File Formats | Man Pages | ManKier](https://www.mankier.com/5/proc#:~:text=The%20proc%20filesystem%20is%20a,using%20a%20command%20such%20as)). Il est normalement toujours disponible, sans intervention manuelle. À titre indicatif, on pourrait le monter soi-même via `mount -t proc proc /proc`, mais cela n’est généralement pas nécessaire puisque le boot s’en occupe. Notons que toutes les distributions Linux courantes (Debian, Ubuntu, Arch, Fedora, etc.) utilisent `/proc` de la même manière, puisque c’est une fonctionnalité standard du noyau Linux.

## 2. Informations contenues dans `/proc`  
Le contenu de `/proc` est organisé sous forme de fichiers et de répertoires virtuels reflétant l’état du système. On y trouve à la fois des **fichiers globaux** décrivant le système et des **répertoires par processus**. La plupart de ces fichiers sont en lecture seule (pour consulter des informations), mais certains sont modifiables pour ajuster des paramètres du noyau (voir section sysctl). Voici quelques exemples de fichiers importants sous `/proc` :  

- **`/proc/cpuinfo`** – Détails sur les processeurs : modèle, fréquence, nombre de cœurs, fonctionnalités, etc. En affichant ce fichier (`cat /proc/cpuinfo`), on peut identifier le CPU présent et ses caractéristiques.  
- **`/proc/meminfo`** – Informations sur la mémoire vive et le swap : quantités totales, libres, en cache, tampon, etc. Ce fichier est utilisé par des outils comme la commande `free` pour résumer l’utilisation mémoire du système ([procfs — Wikipédia](https://fr.wikipedia.org/wiki/Procfs#:~:text=%2A%20%60swapon%20,des%20informations%20sur%20les%20bus)).  
- **`/proc/uptime`** – Données sur le temps d’activité du système. Les deux nombres qu’il contient correspondent respectivement au nombre de secondes écoulées depuis le dernier démarrage et au temps total d’inactivité des processeurs (somme des temps idle) ([procfs — Wikipédia](https://fr.wikipedia.org/wiki/Procfs#:~:text=,des%20informations%20sur%20les%20bus)).  
- **`/proc/version`** – Version du noyau et informations sur la compilation de celui-ci. Par exemple, il indique la version exacte de Linux en cours d’exécution.  
- **`/proc/filesystems`** – Liste des systèmes de fichiers pris en charge par le noyau.  
- **`/proc/interrupts`** – Compteurs d’interruptions matériel par processeur (permet de voir l’utilisation des IRQ par les périphériques).  
- **`/proc/swaps`** – Liste des espaces de swap utilisés et leur utilisation ([procfs — Wikipédia](https://fr.wikipedia.org/wiki/Procfs#:~:text=syst%C3%A8me%20d%27exploitation%20et%20le%20nom,Elle%20utilise)).  
- **`/proc/loadavg`** – Charge moyenne du système (moyennes sur 1, 5 et 15 minutes, nombre de processus en cours, PID récent).  

*(Etc. – `/proc` contient de nombreux autres fichiers, par exemple `cmdline`, `diskstats`, `mounts`, `partitions`, `net/`... qui apportent d’autres informations sur l’état du système ([procfs — Wikipédia](https://fr.wikipedia.org/wiki/Procfs#:~:text=,%60%2Fproc%2Fmeminfo)) ([procfs — Wikipédia](https://fr.wikipedia.org/wiki/Procfs#:~:text=,%60%2Fproc%2Fswaps)).)*  

Pour **consulter ces fichiers**, on utilise les commandes shell classiques. Par exemple, `cat /proc/cpuinfo` affichera le détail des processeurs. On peut combiner avec `grep` pour filtrer une information précise :  

```bash
$ grep "model name" /proc/cpuinfo
```  

Cette commande retournera la ligne du modèle de chaque CPU (pratique pour repérer le modèle du processeur). De même, `grep MemTotal /proc/meminfo` donnera la quantité de RAM totale. On peut aussi utiliser `find` pour parcourir l’arborescence de `/proc`. Par exemple, `find /proc -maxdepth 1 -name "*meminfo*"` permettrait de vérifier l’existence du fichier `meminfo` (ici au niveau 1). En pratique, on connaît généralement le chemin exact des infos recherchées, mais `find` peut aider à découvrir des fichiers moins courants.  

### Fichiers par processus (`/proc/<PID>/` et `/proc/self/`)  
Chaque processus actif dans le système possède un répertoire dédié sous `/proc`, nommé d’après son identifiant de processus (PID) ([procfs — Wikipédia](https://fr.wikipedia.org/wiki/Procfs#:~:text=,%60%2Fproc%2FPID%2Ftask)). Par exemple, le processus ayant PID 1234 aura un répertoire `/proc/1234`. Ce répertoire contient de nombreux fichiers fournissant des renseignements sur le processus en question :  

- **`/proc/<PID>/cmdline`** – La ligne de commande ayant lancé le processus (y compris les arguments).  
- **`/proc/<PID>/status`** – Un résumé en texte lisible de l’état du processus : utilisateur propriétaire, utilisation mémoire, état (actif, suspendu…), PID parent, etc.  
- **`/proc/<PID>/cwd`** – Lien symbolique vers le *current working directory* (répertoire courant) du processus ([procfs — Wikipédia](https://fr.wikipedia.org/wiki/Procfs#:~:text=,pour%20d%C3%A9crire%20les%20%20105)). La commande utilitaire `pwdx <PID>` exploite ce lien pour afficher le répertoire courant d’un processus ([procfs — Wikipédia](https://fr.wikipedia.org/wiki/Procfs#:~:text=,pid%5D%2Fcwd%60%20qui%20est%20un%20lien)).  
- **`/proc/<PID>/exe`** – Lien vers l’exécutable en cours d’utilisation pour ce processus.  
- **`/proc/<PID>/fd/`** – Répertoire contenant les descripteurs de fichiers ouverts par le processus (chaque entrée est un lien vers les fichiers ou ressources que le processus a ouverts).  
- **`/proc/<PID>/maps`**, **`/proc/<PID>/smaps`** – Détails sur la mémoire virtuelle allouée (segments mémoire).  
- **`/proc/<PID>/task/`** – Sous-répertoire listant les threads du processus (chaque thread ayant un sous-répertoire par TID).  

Il existe de nombreux autres fichiers (par exemple `envIRON` pour les variables d’environnement, `stack` pour la pile, etc.), mais les principaux listés ci-dessus sont les plus utiles pour l’administration système. À noter le répertoire spécial **`/proc/self/`** : il s’agit d’un lien symbolique qui pointe vers le répertoire du processus courant qui effectue l’appel. Ainsi, si votre shell tente d’accéder à `/proc/self/cmdline`, il obtiendra la ligne de commande de **son propre** processus. Cela permet d’écrire des commandes génériques s’appliquant au processus appelant sans connaître son PID à l’avance.  

**Droits d’accès :** la plupart des informations de `/proc` sont lisibles par tous les utilisateurs, mais certaines sont restreintes. Par exemple, un utilisateur ne peut normalement pas lire les détails d’un processus appartenant à un autre utilisateur (surtout sur les systèmes configurés avec l’option de montage `hidepid` pour `/proc` ([proc: process information, system information, and sysctl pseudo-filesystem | File Formats | Man Pages | ManKier](https://www.mankier.com/5/proc#:~:text=hidepid%3Dn%20%28since%20Linux%203))). De même, la modification des fichiers (dans `/proc/sys` notamment) requiert les privilèges super-utilisateur.  

## 3. Modification des paramètres du noyau avec `sysctl`  
Le noyau Linux expose un certain nombre de paramètres modifiables à chaud via l’espace `/proc/sys/`. Ces paramètres, aussi appelés *variables sysctl*, peuvent être consultés et ajustés au vol grâce à la commande **`sysctl`** ([procfs — Wikipédia](https://fr.wikipedia.org/wiki/Procfs#:~:text=,pid%5D%2Fcwd%60%20qui%20est%20un%20lien)). L’utilitaire `sysctl` fournit une interface en ligne de commande plus conviviale que la manipulation manuelle des fichiers dans `/proc/sys`. En arrière-plan, `sysctl` lit et écrit justement dans ces fichiers du pseudo-fichier système procfs ([sysctl - ArchWiki](https://wiki.archlinux.org/title/Sysctl#:~:text=sysctl%20is%20a%20tool%20for,proc)) ([Sysctl - Linux Audit](https://linux-audit.com/kernel/sysctl/#:~:text=The%20actual%20kernel%20settings%20are,all%20all%20values%2C%20consult%20%2Fproc%2Fsys)).  

### Lecture des paramètres du noyau  
On peut lister **tous les paramètres disponibles** avec :  

```bash
$ sysctl -a
```  

Cette commande affiche la totalité des clés sysctl et leurs valeurs actuelles. La liste est longue (des centaines de paramètres) couvrant divers sous-systèmes : noyau pur (`kernel.*`), réseau (`net.*`), mémoire virtuelle (`vm.*`), sécurité (`fs.*` pour filesystems, etc.) ([Sysctl - Linux Audit](https://linux-audit.com/kernel/sysctl/#:~:text=The%20sysctl%20tool%20allows%20configuring,or%20system%20hardening%20in%20general)). On peut filtrer l’affichage, par exemple ne montrer que les paramètres réseau : `sysctl -a | grep '^net.'` ou utiliser l’option intégrée `sysctl --pattern '^net.'` ([Sysctl - Linux Audit](https://linux-audit.com/kernel/sysctl/#:~:text=%60sysctl%20)). Pour **consulter une clé spécifique**, on utilise son nom complet, par exemple :  

```bash
$ sysctl net.ipv4.ip_forward
net.ipv4.ip_forward = 0
```  

Ce paramètre `net.ipv4.ip_forward` indique si le routage IP est activé (0 = désactivé, 1 = activé). L’exemple ci-dessus montre une sortie typique : par défaut la plupart des distributions mettent `ip_forward` à 0 (la machine ne fait pas office de routeur). À noter qu’on obtiendrait le même résultat en affichant directement le fichier correspondant : `cat /proc/sys/net/ipv4/ip_forward` – les deux méthodes sont interchangeables.  

### Modification à la volée d’un paramètre  
Pour **modifier un paramètre noyau en cours de fonctionnement**, on utilise `sysctl` avec la syntaxe `clé=valeur`. Par exemple, pour activer le routage IP :  

```bash
$ sudo sysctl net.ipv4.ip_forward=1
net.ipv4.ip_forward = 1
```  

Une fois exécutée, cette commande a **immédiatement effet** – le noyau a mis à jour la valeur et commence à appliquer ce nouveau réglage. Dans notre exemple, la machine va maintenant transmettre les paquets IP d’une interface réseau à l’autre, ce qui est nécessaire si on souhaite qu’elle fasse office de routeur ou de passerelle NAT. La plupart des clés sysctl prennent effet dès le changement, sans redémarrage. On pourrait alternativement écrire directement la valeur dans le fichier pseudo-système : `echo "1" | sudo tee /proc/sys/net/ipv4/ip_forward`. Derrière les coulisses, c’est exactement ce que fait `sysctl` pour nous simplifier la tâche.  

Plusieurs paramètres du noyau peuvent être ajustés de la sorte pour affiner le comportement du système. Voici quelques **exemples courants** de réglages via `sysctl` :  

- **Paramètre réseau (performance) :** `net.core.somaxconn` – Taille maximale de la file d’attente des connexions TCP en attente (backlog). En augmentant cette valeur, on peut améliorer la tolérance aux pics de connexions entrantes (utile pour un serveur web à fort trafic).  
- **Paramètre réseau (fonctionnalité) :** `net.ipv4.ip_forward` – Comme vu plus haut, activer le routage IPv4 (0 ou 1). Utile pour les routeurs, partages de connexion Internet, VPN, etc.  
- **Paramètre sécurité :** `net.ipv4.tcp_syncookies` – Active les *SYN cookies* TCP (0 ou 1). Lorsqu’activé, le noyau atténue les attaques par déni de service de type SYN flood en n’allouant pas de ressources tant qu’une connexion TCP n’est pas pleinement établie ([Sysctl - Linux Audit](https://linux-audit.com/kernel/sysctl/#:~:text=The%20sysctl%20tool%20allows%20configuring,or%20system%20hardening%20in%20general)). Ce paramètre est généralement à `1` par défaut sur la plupart des distributions modernes, mais il est bon de le vérifier sur les systèmes anciens ou lors de durcissement de la sécurité.  
- **Paramètre mémoire virtuelle :** `vm.swappiness` – Définit l’appétence du noyau pour l’utilisation du swap (valeur entre 0 et 100). Une valeur faible (ex. 10) indique au noyau de garder le plus possible en RAM et d’éviter de swapper, tandis qu’une valeur élevée (ex. 60 par défaut) le rend plus agressif pour échanger en swap. En réduisant `swappiness`, on peut améliorer les performances perçues sur une station de travail en évitant de swapper inutilement, au prix d’une utilisation mémoire plus soutenue.  
- **Paramètre du noyau (divers) :** `kernel.randomize_va_space` – Contrôle la randomisation de l’espace d’adressage (ASLR). Une valeur de `2` active une randomisation complète (niveau de sécurité maximal par défaut), `1` une randomisation partielle, et `0` la désactive (à éviter sauf besoin spécifique de debug). Ce paramètre contribue à la sécurité du système en rendant plus difficile l’exploitation de failles de mémoire.  

*(Chaque paramètre sysctl a une documentation détaillée dans le kernel documentation ou via `man 5 proc` pour ceux sous `/proc/sys`. Il est recommandé de bien comprendre l’impact d’un réglage avant de le modifier.)*  

### Rendre les changements persistants  
Les modifications faites via `sysctl` ou en écrivant dans `/proc/sys` **ne survivent pas à un redémarrage**. Au boot, le noyau réinitialise tous les paramètres aux valeurs par défaut (intégrées au noyau ou définies par les options de boot). Pour appliquer automatiquement nos réglages à chaque démarrage, on doit les inscrire dans un fichier de configuration lu au boot. Sous Debian, Ubuntu et dérivés, le fichier traditionnel est **`/etc/sysctl.conf`**, dans lequel on liste les réglages souhaités (un par ligne sous la forme `clé = valeur`). Ce fichier est pris en charge par le script d’initialisation du paquet **procps** lors du boot ou par le service systemd `systemd-sysctl`.  

Sous les distributions modernes utilisant systemd (Arch, Fedora, Debian >=8, Ubuntu >=15,...), il est recommandé d’utiliser des fichiers de configuration dans **`/etc/sysctl.d/`**. Par exemple, on peut créer un fichier `/etc/sysctl.d/99-custom.conf` et y placer nos paramètres personnalisés. Cela permet de ne pas toucher au fichier principal et de segmenter la configuration par thématique. Systemd va lire tous les fichiers `*.conf` de `/usr/lib/sysctl.d/` (valeurs par défaut du système ou des paquets), puis ceux de `/etc/sysctl.d/` (surcharges de l’administrateur), puis enfin `/etc/sysctl.conf` ([Sysctl - Linux Audit](https://linux-audit.com/kernel/sysctl/#:~:text=,%2Fetc%2Fsysctl.conf)) ([sysctl - ArchWiki](https://wiki.archlinux.org/title/Sysctl#:~:text=The%20sysctl%20preload%2Fconfiguration%20file%20can,processed%20later%20from%20both%20directories)). L’ordre de lecture peut avoir son importance si la même clé est définie à plusieurs endroits (la dernière lue l’emporte). Sur Arch Linux par exemple, il n’y a pas de `/etc/sysctl.conf` fourni par défaut – l’administrateur crée directement un fichier dans `/etc/sysctl.d/` si nécessaire ([If /etc/sysctl.conf doesn't exist, where is my sysctl storing configs?](https://unix.stackexchange.com/questions/595032/if-etc-sysctl-conf-doesnt-exist-where-is-my-sysctl-storing-configs#:~:text=If%20%2Fetc%2Fsysctl,swappiness%3D10)). En revanche, sur Debian/Ubuntu, un fichier `/etc/sysctl.conf` est présent par défaut (souvent commenté) et peut être utilisé directement. Dans tous les cas, **la gestion de `sysctl` est très similaire d’une distribution à l’autre** : elles lisent juste ces fichiers à des moments légèrement différents, mais finalement appliquer un paramètre se résume aux mêmes étapes.  

Pour appliquer immédiatement des changements persistants sans redémarrer, on peut utiliser `sudo sysctl -p` (qui relit `/etc/sysctl.conf`) ou `sudo sysctl --system` ([sysctl - ArchWiki](https://wiki.archlinux.org/title/Sysctl#:~:text=To%20load%20all%20configuration%20files,manually%2C%20execute)) (qui relit l’ensemble des fichiers de configuration sysctl.d). Ainsi, on s’assure que la configuration en mémoire correspond bien à ce qui est écrit dans nos fichiers.  

## 4. Présentation du pseudo-système de fichiers `/sys`  
Le répertoire `/sys` correspond au pseudo-système de fichiers appelé **sysfs**. Introduit avec le noyau Linux 2.6, il a pour objectif d’exposer à l’espace utilisateur une vue unifiée des **périphériques matériels et de leurs pilotes** ([Sysfs — Wikipédia](https://fr.wikipedia.org/wiki/Sysfs#:~:text=Sysfs%20est%20un%20syst%C3%A8me%20de,configurer%20certaines%20fonctionnalit%C3%A9s%20du%20noyau)). Comme `/proc`, il s’agit d’un filesystem virtuel maintenu en mémoire (basé à l’origine sur *ramfs*) ([Sysfs — Wikipédia](https://fr.wikipedia.org/wiki/Sysfs#:~:text=Sysfs%20est%20un%20syst%C3%A8me%20de,syst%C3%A8mes%20de%20fichiers%20en%20m%C3%A9moire)). Toutefois, son contenu et sa finalité diffèrent de `/proc` : `/sys` est organisé selon la structure interne du noyau (le *Device Tree* ou arbre des périphériques) et vise principalement à représenter la configuration matérielle du système.  

Historiquement, avant Linux 2.6, le répertoire `/proc` avait commencé à accumuler des informations ne concernant pas directement les processus (par exemple des données sur le matériel, les pilotes, etc.), ce qui le rendait moins lisible. Sysfs a été conçu pour **désengorger `/proc` en déplaçant dans `/sys` toutes les informations relatives aux périphériques** et aux sous-systèmes du noyau ([Sysfs — Wikipédia](https://fr.wikipedia.org/wiki/Sysfs#:~:text=,d%27informations%20non%20li%C3%A9es%20aux%20processus)). Concrètement, `/sys` offre une vision arborescente de tous les composants matériels (bus, périphériques, drivers…) du système, séparée des informations purement liées aux processus que l’on trouve dans `/proc`.  

Comme `/proc`, le pseudo-fichier système `/sys` est monté automatiquement au démarrage. Sur les systèmes à init **systemd**, celui-ci monte `sysfs` très tôt dans la séquence de boot. Sur Debian/Ubuntu classiques (SysVinit ou systemd), on trouve également souvent une entrée dans `/etc/fstab` du type: `sysfs  /sys  sysfs  defaults  0 0`, indiquant de monter sysfs sur `/sys`. Dans la pratique, quelle que soit la distribution (Debian, Arch, Fedora…), **`/sys` est toujours monté par le système au boot** car des composants critiques comme udev en dépendent pour détecter le matériel ([fr/DeviceManagement - Debian Wiki](https://wiki.debian.org/fr/DeviceManagement#:~:text=Udev%20et%20hal%20utilisent%20sysfs,dans%20leur%20fonctionnement)). Il n’est donc pas nécessaire de le monter manuellement (sauf en environnement minimaliste ou en chroot, le cas échéant).  

En résumé, `/sys` est un **miroir du modèle objet du noyau** : il représente les bus, les périphériques, les classes de périphériques, et expose leurs attributs sous forme de fichiers. Il fournit également des points de contrôle pour certains aspects du matériel ou du noyau. C’est un outil précieux pour interagir avec les drivers et obtenir des informations précises sur chaque composant du système.  

## 5. Informations contenues dans `/sys`  
La structure de `/sys` est hiérarchique et reflète l’architecture interne du noyau. À la racine de `/sys`, on trouve notamment :  

- **`/sys/devices/`** – Regroupe les périphériques physiques par hiérarchie matérielle. On y voit l’arborescence réelle : par exemple, sous `/sys/devices/system/cpu/` se trouvent les CPU, sous `/sys/devices/pci0000:00/` les appareils sur le bus PCI racine, etc. C’est ici qu’apparaissent concrètement tous les dispositifs détectés dans le système (disques, interfaces réseau, USB, etc.), organisés par bus et connexions.  
- **`/sys/class/`** – Vue logique par *classe* de périphériques. Les *classes* regroupent des périphériques ayant des fonctions similaires, indépendamment de leur localisation sur un bus. Par exemple, la classe `net` contient toutes les interfaces réseau du système (eth0, wlan0, lo, etc.), la classe `block` contient tous les périphériques de stockage en bloc (sda, sdb, loop0, …), la classe `tty` les terminaux, etc. Parcourir `/sys/class` permet de trouver rapidement un type de périphérique sans connaître sa position exacte dans `/sys/devices`.  
- **`/sys/bus/`** – Vue par bus systèmes. Ce répertoire contient une entrée pour chaque type de bus présent dans le noyau (pci, usb, spi, i2c, etc.). À l’intérieur, on peut voir les périphériques attachés à chaque bus (`/sys/bus/pci/devices/...` par ex.) ainsi que les drivers associés (`/sys/bus/pci/drivers/...`). C’est une autre manière de naviguer vers les mêmes informations, mais classées par bus de communication.  
- **`/sys/modules/`** – Informations sur les modules du noyau chargés. Chaque module (pilote ou composant du noyau chargé dynamiquement) a un dossier ici, contenant notamment un fichier `parameters/` qui expose les paramètres modulables de ce module. Par exemple, si un module pilote accepte des options (comme la taille de buffer, etc.), elles seront visibles et modifiables via des fichiers dans `/sys/modules/<nom_module>/parameters/`.  
- **`/sys/kernel/`** – Données spécifiques au noyau lui-même. On y trouve par exemple des informations de debug (`/sys/kernel/debug/` si monté), des réglages de sécurité (`/sys/kernel/security/`), ou la configuration à chaud du noyau (`/sys/kernel/mm/` pour la mémoire, etc.). Ce répertoire peut également accueillir d’autres pseudo-systèmes de fichiers comme *configfs* (généralement monté sur `/sys/kernel/config`).  

Chaque fichier visible dans `/sys` représente soit un **attribut** d’un objet kernel (un périphérique, un driver, un module…), soit un **point de contrôle** permettant d’influer sur le comportement du système. Par exemple :  

- Le fichier `/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor` permet de lire et changer le gouverneur d’économie d’énergie du CPU0 (on peut y écrire `performance` ou `powersave` pour modifier la stratégie d’horloge du processeur).  
- Le répertoire `/sys/class/net/eth0/` contient des fichiers donnant des infos sur l’interface réseau `eth0` (adresse MAC, MTU, état) et certains permettant de la configurer (par ex. désactiver/activer l’interface en écrivant dans `/sys/class/net/eth0/operstate` ou via d’autres mécanismes liés).  
- Le fichier `/sys/class/leds/input3::capslock/brightness` (s’il existe) pourrait contrôler la LED *verrouillage majuscule* d’un clavier – écrire `1` dedans allumerait la LED, `0` l’éteindrait.  
- Le fichier `/sys/block/sda/queue/scheduler` affiche et permet de définir l’algorithme d’ordonnancement I/O pour le disque `sda`. En y écrivant le nom d’un scheduler supporté (comme `mq-deadline` ou `bfq`), on change la politique d’ordonnancement des E/S disque à la volée.  

La **différence avec `/proc`** est que `/sys` est orienté *matériel* et *pilotes*. Il expose les attributs des objets du kernel (périphériques, drivers) d’une manière cohérente et navigable, alors que `/proc` est plus hétérogène et inclut principalement des infos sur les processus et divers paramètres système. En somme, `/proc` donne une vision d’ensemble du système et du noyau (état des processus, mémoire, configuration générale), tandis que `/sys` permet de **dialoguer avec les composants du noyau** en représentant leur état individuel. D’ailleurs, on peut souvent agir sur le matériel en écrivant dans `/sys` (ce qui va appeler le pilote correspondant dans le noyau), ce qui n’est pas le cas de la plupart des fichiers de `/proc` (sauf ceux sous `/proc/sys` destinés aux paramètres noyau).  

**Interaction avec les pilotes :** Les développeurs de drivers utilisent sysfs pour offrir des interfaces utilisateur. Quand un pilote est chargé, il enregistre des objets et attributs dans `/sys` pour que l’administrateur puisse, par exemple, activer/désactiver une fonctionnalité du périphérique, lire un capteur, régler une valeur, etc. Par exemple, un pilote de carte réseau peut exposer une option `/sys/class/net/<iface>/queues/rx-0/rps_cpus` pour configurer l’affinité CPU de la réception réseau. Ainsi, `/sys` est devenu un outil incontournable pour la configuration fine des périphériques sous Linux. La commande `udev` elle-même parcourt `/sys` pour identifier le matériel et créer les nœuds de périphérique correspondants sous `/dev` ([fr/DeviceManagement - Debian Wiki](https://wiki.debian.org/fr/DeviceManagement#:~:text=Udev%20et%20hal%20utilisent%20sysfs,dans%20leur%20fonctionnement)).  

En ce qui concerne la **portabilité entre distributions**, `/sys` est tout aussi standard que `/proc` : toute distribution Linux moderne utilise sysfs. Les différences peuvent résider dans les règles *udev* ou la présentation de certains périphériques, mais l’arborescence de base de `/sys` et son fonctionnement sont uniformes (car dictés par le noyau). Sur Ubuntu, Debian, Arch, Fedora, vous retrouverez donc une structure `/sys` très similaire, à condition d’avoir un noyau de version équivalente et les mêmes modules chargés.  

## 6. Utilitaire `sysTool` (systool)  
**`systool`** (à ne pas confondre avec *sysctl*) est un utilitaire en ligne de commande permettant d’interroger l’arborescence de sysfs plus aisément. Fourni par le paquet `sysfsutils` sur Debian/Ubuntu, il sert à lister les périphériques et leurs attributs par bus, classe ou module kernel, en utilisant l’API de libsysfs ([systool(1) — sysfsutils — Debian unstable — Debian Manpages](https://manpages.debian.org/unstable/sysfsutils/systool.1#:~:text=Calling%20systool%20without%20parameters%20will,device%20classes%2C%20and%20root%20devices)). En d’autres termes, `systool` offre une vue formatée de ce qui se trouve sous `/sys`, ce qui peut être plus pratique que de parcourir manuellement les répertoires.  

**Présentation et installation :** Sur Debian, pour disposer de `systool`, il faut installer le paquet **`sysfsutils`** (s’il ne l’est pas déjà). Ce paquet contient également un fichier de configuration `/etc/sysfs.conf` permettant de définir des valeurs à écrire dans certains nœuds de sysfs au démarrage du système ([Debian -- Details of package sysfsutils in sid](https://packages.debian.org/sid/utils/sysfsutils#:~:text=The%20sysfs%20is%20a%20virtual,by%20bus%2C%20class%2C%20and%20topology)). Sur Arch Linux et Fedora, `systool` n’est pas installé par défaut non plus, mais on le trouve respectivement dans le paquet `sysfsutils` (installation via pacman) et dans les dépôts officiels (installation via dnf/yum).  

**Usage courant :** Sans argument, la commande `systool` affiche tous les types de bus, toutes les classes de périphériques et tous les périphériques racine disponibles sur le système ([systool(1) — sysfsutils — Debian unstable — Debian Manpages](https://manpages.debian.org/unstable/sysfsutils/systool.1#:~:text=DESCRIPTION%C2%B6)). Cela donne une vision d’ensemble de la hiérarchie du matériel. On peut affiner la requête avec des options :  

- `systool -b <bus>` – Liste les périphériques et informations pour un bus donné. Par exemple `systool -b pci` affichera la liste des périphériques PCI et leurs attributs (identifiants, ressources, driver associé, etc.).  
- `systool -c <classe>` – Affiche les périphériques d’une **classe** spécifique. Par exemple, `systool -c net -v` listera toutes les interfaces réseau (classe *net*) avec tous leurs attributs et valeurs (`-v` pour *verbose*, afin de voir les détails) ([Kernel module - ArchWiki](https://wiki.archlinux.org/title/Kernel_module#:~:text=To%20list%20the%20options%20that,1%29%20from%20sysfsutils)). De même, `systool -c block -v` donnerait des informations détaillées sur tous les périphériques de stockage (disques, partitions) visibles par le système.  
- `systool -m <module>` – Donne des informations sur un **module du noyau** chargé. C’est très utile pour voir les paramètres d’un pilote. Par exemple `systool -v -m usb_storage` affichera les attributs du module `usb_storage`, y compris les paramètres qu’il accepte (identiques à ceux qu’on pourrait passer via modprobe) et leur valeur actuelle ([Kernel module - ArchWiki](https://wiki.archlinux.org/title/Kernel_module#:~:text=To%20list%20the%20options%20that,1%29%20from%20sysfsutils)). Cela équivaut en partie à combiner ce qu’on peut trouver sous `/sys/module/usb_storage` et la commande `modinfo`.  

En somme, `systool` permet de **consulter facilement** ce qui est exposé dans `/sys` sans devoir ouvrir manuellement de multiples fichiers. On peut ainsi vérifier la configuration des périphériques ou modules de façon centralisée. Par exemple, pour parcourir tous les appareils USB connectés : `systool -b usb -v` donnera une liste structurée de chaque périphérique USB, avec son identifiant, son fabricant, etc., en puisant ces infos dans `/sys/bus/usb/devices/`.  

**Manipulation des paramètres système :** Notons que `systool` est essentiellement un outil de lecture (il n’a pas d’option pour écrire/modifier directement les valeurs). Si l’on veut modifier un paramètre dans `/sys`, on le fait soit manuellement (avec `echo` dans le fichier approprié), soit via un mécanisme de configuration. Le paquet `sysfsutils` mentionné plus haut offre la possibilité de définir des valeurs persistantes à appliquer à des entrées de `/sys` lors du boot via le fichier `/etc/sysfs.conf` ([Debian -- Details of package sysfsutils in sid](https://packages.debian.org/sid/utils/sysfsutils#:~:text=In%20addition%20this%20package%20ships,via%20an%20init%20script)). Ce fichier n’est pas très courant, mais il peut rendre service pour appliquer automatiquement des réglages *sysfs* (par exemple, fixer la luminosité par défaut d’un rétroéclairage, activer/désactiver un périphérique spécifique, etc.). Sur la plupart des distributions modernes, on privilégiera cependant udev ou des scripts systemd pour ce genre de configuration au démarrage, sauf usage de `sysfsutils`.  

En résumé, `systool` (utilitaire *sysfs*) complète `sysctl` (utilitaire *procfs*) :  
- `sysctl` interroge et modifie les paramètres noyau (sous `/proc/sys`) relatifs à la configuration générale du système.  
- `systool` interroge l’arbre matériel et permet de voir les caractéristiques et paramètres des périphériques et modules (sous `/sys`).  

Les deux outils sont complémentaires pour administrer finement un système Linux. Leur utilisation et disponibilité sont similaires sur différentes distributions (il suffit d’installer `sysfsutils` pour avoir `systool` sur les distros qui ne l’incluent pas d’office).  

## 7. Exemple pratique : modification de paramètres avec `sysctl`  
Pour illustrer la manipulation des pseudo-systèmes de fichiers, prenons un petit exercice pratique de modification d’un paramètre du noyau avec `sysctl`. Imaginons que l’on veuille activer l’IPv4 *forwarding* (routage IP) sur une Debian – opération souvent nécessaire pour transformer la machine en routeur ou pour faire du partage de connexion. Par défaut, ce paramètre est désactivé. Voici les étapes :  

**1. Vérification initiale du paramètre** – Tout d’abord, on consulte la valeur actuelle de `net.ipv4.ip_forward`. On peut utiliser la commande `sysctl` sans privilèges pour le lire :  

```bash
$ sysctl net.ipv4.ip_forward  
net.ipv4.ip_forward = 0  
```  

La sortie confirme que le routage IP est actuellement **désactivé** (`0`). (Si on préférait, on pourrait également lire directement le fichier `/proc/sys/net/ipv4/ip_forward` qui contiendrait `0`.)  

**2. Activation du routage IP** – On va maintenant activer ce paramètre. Cela nécessite les droits d’administration :  

```bash
$ sudo sysctl -w net.ipv4.ip_forward=1  
net.ipv4.ip_forward = 1  
```  

Ici, l’option `-w` (*write*) indique qu’on écrit une nouvelle valeur. Le système renvoie la nouvelle valeur pour confirmation. À ce stade, le noyau a modifié son comportement : **le transfert de paquets entre interfaces est autorisé**. Si notre machine a deux interfaces réseau (par ex. `eth0` et `eth1`), elle commencera à router les paquets entre elles. Bien sûr, pour un véritable routeur, il faudrait également configurer le pare-feu (iptables/nftables) afin de contrôler/autoriser le trafic, mais au niveau du noyau, l’option est en place.  

**3. Vérification après changement** – On peut relire la valeur pour s’assurer qu’elle est passée à 1 :  

```bash
$ cat /proc/sys/net/ipv4/ip_forward  
1  
```  

Ou via `sysctl net.ipv4.ip_forward` qui devrait maintenant répondre `1`. On constate donc le **changement effectif** par rapport à la situation initiale.  

**4. Impact sur le système** – Concrètement, qu’est-ce que ce changement implique ? En activant `ip_forward`, on a transformé notre hôte en élément de routage au niveau IP. Cela n’a pas d’effet visible immédiat pour l’utilisateur lambda (aucun programme ne s’est lancé en plus), mais le noyau va désormais examiner les paquets entrants pour voir s’ils doivent être retransmis vers une autre interface. Si l’on faisait un test avant/après : avant, un paquet reçu sur `eth0` destiné à un réseau accessible via `eth1` aurait été ignoré (ou détruit) par le noyau. Après activation, ce même paquet serait retransmis sur `eth1`. Ainsi, ce paramètre est essentiel pour des usages comme le partage de connexion Internet (par exemple avec la commande *iptables* `MASQUERADE` couplée à `ip_forward=1`). Du point de vue performances, laisser `ip_forward` à 1 n’a pas de coût significatif en soi, mais sur un système non prévu pour router, mieux vaut le laisser à 0 par sécurité (éviter des routages inattendus).  

**5. Rendre la modification pérenne (ou l’annuler)** – Dans notre exemple, le changement est **temporaire**. Si on redémarre la machine, `net.ipv4.ip_forward` reviendra à 0 (comportement par défaut). Si notre intention est de transformer durablement la machine en routeur, il faudra ajouter la ligne suivante dans un fichier de configuration :  

```
net.ipv4.ip_forward = 1  
```  

Sur Debian/Ubuntu, on peut l’ajouter dans `/etc/sysctl.conf` ou mieux, dans un fichier dédié sous `/etc/sysctl.d/` (par ex. `/etc/sysctl.d/30-ipforward.conf`). Sur Arch/Fedora, on créera un fichier sous `/etc/sysctl.d/` également, puisque c’est la méthode privilégiée ([Sysctl - Linux Audit](https://linux-audit.com/kernel/sysctl/#:~:text=,%2Fetc%2Fsysctl.conf)). Une fois en place, on peut appliquer la config avec `sudo sysctl -p` ou attendre le prochain redémarrage – le service de sysctl l’activera automatiquement.  

Si, au contraire, on souhaite **annuler le changement** (revenir à la valeur par défaut sans redémarrer), il suffit de repasser le paramètre à 0 :  

```bash
$ sudo sysctl -w net.ipv4.ip_forward=0  
net.ipv4.ip_forward = 0  
```  

Le noyau cesse alors immédiatement de faire du forwarding de paquets. On vérifie que tout est rentré dans l’ordre initial avec `sysctl net.ipv4.ip_forward` qui doit renvoyer `0`. Enfin, on retirerait la ligne de configuration persistante si on l’avait ajoutée, pour que le paramètre ne soit plus activé au boot.  

**Comparaison avec d’autres distributions :** Les étapes ci-dessus seraient les mêmes sur Ubuntu, Arch ou Fedora. Le mécanisme de `sysctl` et l’interface `/proc/sys` sous-jacente sont identiques d’une distro à l’autre. La seule différence porte sur **l’emplacement de la configuration persistante** : par exemple sur Arch Linux, on créerait un fichier `/etc/sysctl.d/99-sysctl.conf` (s’il n’existe pas déjà) car il n’y a pas de `/etc/sysctl.conf` par défaut ([If /etc/sysctl.conf doesn't exist, where is my sysctl storing configs?](https://unix.stackexchange.com/questions/595032/if-etc-sysctl-conf-doesnt-exist-where-is-my-sysctl-storing-configs#:~:text=If%20%2Fetc%2Fsysctl,swappiness%3D10)). Sur Fedora (utilisant systemd), on pourrait aussi utiliser `/etc/sysctl.d/`. Ubuntu, étant très proche de Debian, supporte les deux méthodes mais inclut de base un `/etc/sysctl.conf`. Mis à part ce détail, le comportement de `/proc/sys/net/ipv4/ip_forward` et de `sysctl` est inchangé : c’est le même noyau Linux qui est configuré.  

En guise de conclusion, les pseudo-systèmes de fichiers **`/proc` et `/sys` sous Debian** fournissent une fenêtre en temps réel sur le fonctionnement interne du système et un moyen d’agir sur le noyau. Les outils comme `cat`, `grep` ou `find` permettent d’explorer ces arborescences pour obtenir toutes sortes d’informations (CPU, mémoire, processus, périphériques...). Quant à `sysctl` et `systool`, ils offrent des interfaces dédiées pour ajuster le comportement du noyau et inspecter la configuration hardware. Ces concepts sont valables sur l’ensemble des distributions Linux – les différences résident surtout dans l’organisation ou l’emplacement de quelques fichiers de config, mais le fond (le noyau Linux et ses interfaces /proc, /sys) reste universel ([procfs — Wikipédia](https://fr.wikipedia.org/wiki/Procfs#:~:text=,Unix%20%2072)) ([Sysfs — Wikipédia](https://fr.wikipedia.org/wiki/Sysfs#:~:text=,d%27informations%20non%20li%C3%A9es%20aux%20processus)). Les administrateurs système exploitent couramment ces pseudo-systèmes de fichiers pour le diagnostic, l’optimisation et la configuration fine de leurs systèmes Linux, quel que soit le flavour de leur distribution.  

