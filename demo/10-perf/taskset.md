La commande suivante que tu mentionnes :

```bash
taskset -cp 2 <PID>
```

ne sert **pas** à **récupérer le nombre de cœurs**, mais à **fixer l'affinité processeur** d’un processus donné. Voici une explication complète, **et ensuite je te montre comment récupérer le vrai nombre de cœurs**.

---

## 🔧 **Comprendre `taskset -cp`**

### 📌 Syntaxe :
```bash
taskset -cp <cpu_list> <pid>
```

- **`-c`** : utiliser une **liste de processeurs** (ex: `0,1,2`).
- **`-p`** : opère sur un **processus existant**.

### ✅ **Exemples** :

1. **Voir l'affinité actuelle d’un processus** (ex: PID 1234) :
```bash
taskset -cp 1234
```
Exemple de sortie :
```
pid 1234's current affinity list: 0-3
```
→ Ce processus peut s'exécuter sur les CPU 0, 1, 2 et 3.

2. **Restreindre un processus à un seul cœur (ex: cœur 2)** :
```bash
taskset -cp 2 1234
```
→ Le processus `1234` ne pourra tourner que sur le CPU n°2.

---

## ✅ **Comment récupérer le nombre de cœurs (vCPU) d’une machine ?**

Voici les méthodes **fiables** pour connaître le **nombre de cœurs** :

### 🧪 **1. Avec `nproc`**
```bash
nproc
```
→ Affiche le **nombre total de processeurs logiques disponibles** (ex: 8).

---

### 🧪 **2. Avec `lscpu`**
```bash
lscpu
```
Extrait typique :
```
CPU(s):              8
Core(s) per socket:  4
Socket(s):           1
Thread(s) per core:  2
```

➡️ Explication :
- **CPU(s)** : nombre total de cœurs logiques (avec hyperthreading).
- **Core(s) per socket** : cœurs physiques par socket.
- **Thread(s) per core** : 1 ou 2 (hyperthreading).
- **Socket(s)** : nombre de CPU physiques.

---

### 🧪 **3. Avec `/proc/cpuinfo`**
```bash
grep ^processor /proc/cpuinfo | wc -l
```
→ Donne le nombre total de processeurs logiques (cœurs visibles du point de vue OS).

---

## 📝 Résumé

| Objectif                           | Commande                         |
|-----------------------------------|----------------------------------|
| Récupérer **nb de cœurs logiques** | `nproc` ou `lscpu`               |
| Voir **affinité d’un processus**   | `taskset -cp <pid>`              |
| Fixer un processus à 1 cœur        | `taskset -cp 2 <pid>`            |

Souhaite-tu aussi un script pour **lister tous les processus par CPU/core utilisé** ?