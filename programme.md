Jour 1
Architecture système Linux
– Vue d'ensemble
– Anneaux de protection (-1, 0 et 3)
– Plateformes matérielles
– Noyau Linux et LKM
– Le système de fichiers root
– Pilotes de périphériques
– Bibliothèques partagées et statistiques
– Appels systèmes
– Diﬀérents Shells
– La virtualisation
Noyau Linux
– Téléchargement des sources et des outils nécessaires
– Paramétrage du noyau avancé
– Compilation et installation du noyau méthode classique ou méthode Debian
– Intégration de drivers et outils
Loadable Kernel Modules (LKM)
– Conception d'un module de noyau
– Compilation et installation d'un module
– Chargement / déchargement d'un module
– Liste de tous les modules existants
– Liste des modules chargés
– Aﬃchage des informations d'un module
– Gestion des dépendances
– Blocage d'un module
– Création d'un noyau personnalisé
Exemple de travaux pratiques (à titre indicatif)
– Compilation et installation d'un module de noyau
"/proc" et "/sys"
– Présentation du pseudo-système de fichiers /proc
– Informations contenues dans /proc
– Modification des paramètres du noyau avec sysctl
– Présentation du pseudo-système de fichiers sysfs
– Informations contenues dans /sys
– Utilitaire sysTool
Exemple de travaux pratiques (à titre indicatif)
– Paramétrages avec sysctl
Dépannage matériel
– Types de problèmes matériels
– Analyse du matériel
Exemples de travaux pratiques (à titre indicatif)
– Aﬃcher les caractéristiques d'un matériel
– Identifier les incidents associés
Jour 2
Logicial Volume Manager (LVM)
– Rappel des principaux systèmes de fichiers (ext2, ext3, ext4, zfs, xfs)
– Description de LVM (Volumes logiques) et de Device Mapper
– Gestion des Volume Groups (VG), des Physical Volumes (PV) et des Logical Volumes (LV)
– Extensions Physiques (PE) et Extensions Logiques (LE)
– Métadonnées (PVRA, VGRA, BBRA)
– Sécurisation des volumes
Exemples de travaux pratiques (à titre indicatif)
– Augmentation de la capacité d'un volume logique
– Création d'un nouveau volume groupe, d'un volume logique formaté en ext4 et monté de façon
permanente
BTRFS
– Présentation des fonctionnalités (volumes, subvolumes, snapshot, CoW, compression...)
Exemple de travaux pratiques (à titre indicatif)
– Mise en oeuvre de BTRFS
Séquence d'amorçage
– Fonctionnement détaillé du boot
– Passage d'arguments au boot ponctuel ou permanent
– Reconstruction du boot
– Analyse des temps de démarrage du système
Exemples de travaux pratiques (à titre indicatif)
– Démarrage
– Mode rescue
– Mode emergency
– Mode débogage
– Réinitialisation du mot de passe root
Gestion de l'activité
– Analyse des fichiers journaux de systemd-journald
– Configuration de journald
– Rétro-compatibilité avec rsyslogd
– Etude des principales options de systemctl
m2iformation.fr 3/4
Exemple de travaux pratiques (à titre indicatif)
– Analyse d'un service en échec
Jour 3
Maintenance du système
Gestion d'urgence en cas de crash
Maintenance de la configuration réseau
Contrôler et améliorer les performances
– Recherche des problèmes de performance
– Analyses des diﬀérentes couches
– Tester les performances
– Identifier les goulots d'étranglements et résolution
– Introduction à la supervision centralisée
La sécurité
– Tour d'horizon des bonnes pratiques de durcissement
– Mettre en oeuvre un durcissement adapté
– Introduction à la sécurité de l'identité, du réseau, des données
– Gestion des clés, chiﬀrements de flux...
Exemples de travaux pratiques (à titre indicatif)
– Analyses CPU, mémoire, disque et réseau
Le contenu de ce programme peut faire l'objet d'adaptation selon les niveaux, prérequis et besoins des apprenants.