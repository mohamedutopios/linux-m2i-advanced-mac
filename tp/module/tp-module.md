
# Conception et Mise en Œuvre d’un Module Linux de Traçage des Ouvertures de Fichiers

Dans cet exercice, vous allez concevoir, compiler, installer et tester un module noyau Linux. Ce module a pour objectif de tracer les appels au système d'ouverture de fichiers (ici, l'appel système `openat`). Vous découvrirez ainsi comment intercepter un appel système, générer des messages dans les logs du noyau et manipuler un module (chargement, déchargement, vérification des logs).

## 1. Conception du Module

### Objectif
- Intercepter l'appel système `openat` pour enregistrer, dans le journal du noyau, chaque demande d'ouverture d'un fichier.

### Structure du Code Source

Le fichier source, nommé **trace_open.c**, doit contenir :

- Les inclusions nécessaires pour interagir avec le noyau et manipuler les symboles.
- La déclaration d'un pointeur vers la fonction système originale `sys_openat`.
- La définition d'une fonction "hookée" qui sera appelée à la place de l'appel système d'origine, et qui enregistrera le nom du fichier ouvert via `printk()`.
- Une fonction d'initialisation qui localise la table des appels système (sys_call_table), désactive temporairement la protection en écriture, remplace l'entrée correspondant à `openat` par la fonction hookée, puis restaure la protection.
- Une fonction de nettoyage qui restaure l'entrée d'origine dans la table des appels système lors du déchargement du module.


---

## 2. Compilation du Module

### Installation des Prérequis

### Rédaction d’un Makefile

### Compilation


---

## 3. Installation et Chargement du Module

### Installation
### Chargement

---

## 4. Test du Module

Pour vérifier le fonctionnement du module, procédez comme suit :

1. Ouvrez un fichier dans un terminal, par exemple :

2. Consultez les logs du noyau pour vérifier que le message de traçage apparaît :


---

## 5. Déchargement et Nettoyage

### Déchargement du Module
- Pour retirer le module du noyau.

- Vérifiez à nouveau que la modification a été prise en compte.


### Informations et Gestion
- Obtenir des informations détaillées sur le module.

- Lister les modules chargés.

- Afficher l’ensemble des modules présents sur le système.


### Nettoyage Final
- Pour nettoyer les fichiers générés après le test 

---

