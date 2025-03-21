Voici un guide **détaillé**, avec **explications**, **cas d’usage**, **commandes concrètes** et **exemples commentés** pour les outils de monitoring système suivants : `mpstat`, `vmstat`, `iostat`, `ioping`, `iftop`, `nload`.

---

## 🔧 **1. `mpstat` – Statistiques CPU par cœur**

### ✅ **Cas d’usage** :
- Surveiller la **charge CPU** globale et par cœur.
- Identifier des déséquilibres de charge (ex: CPU 0 saturé, CPU 1 inactif).
- Diagnostiquer un système lent (CPU utilisé à 100%).

### 🔍 **Exemple de commande** :
```bash
mpstat -P ALL 2 5
```
→ Affiche l'utilisation de **chaque cœur CPU** toutes les 2 secondes, 5 fois.

### 📊 **Exemple de sortie commentée** :
```
11:30:20 AM  CPU   %usr   %nice %sys %iowait %irq %soft %steal %idle
11:30:22 AM  all    10.0    0.0   3.0     0.5   0.0   0.1    0.0   86.4
11:30:22 AM    0    12.5    0.0   4.0     0.2   0.0   0.2    0.0   83.1
11:30:22 AM    1     7.5    0.0   2.0     0.8   0.0   0.1    0.0   89.6
```

### 📝 **Commentaires** :
- `%usr` : temps utilisateur (exécution de programmes).
- `%sys` : temps noyau (appel système).
- `%iowait` : attente liée aux disques (au-delà de 5% = à surveiller).
- `%idle` : temps d’inactivité (idéalement élevé si peu de charge).

---

## 💾 **2. `vmstat` – Mémoire, swap, I/O, CPU, processus**

### ✅ **Cas d’usage** :
- Identifier les **problèmes de mémoire** ou de **swap**.
- Diagnostiquer un **bottleneck CPU/I/O**.
- Observer les **processus bloqués ou en attente**.

### 🔍 **Exemple de commande** :
```bash
vmstat 2 5
```
→ Affiche les stats toutes les 2 secondes, 5 fois.

### 📊 **Exemple de sortie commentée** :
```
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free  buff  cache   si   so    bi    bo   in   cs  us  sy  id  wa
 2  0      0 102400  1200  98000    0    0     1     2  100  200   5   1  93   1
```

### 📝 **Commentaires** :
- `r` : 2 processus attendent le CPU.
- `b` : 0 processus bloqué en I/O → pas d’engorgement.
- `swpd` : 0 swap utilisé → bon signe.
- `si/so` : (swap in/out) → si ≠ 0 → le système manque de RAM.
- `id` : 93% d'inactivité → faible charge CPU.

---

## 📀 **3. `iostat` – Activité disque + CPU**

### ✅ **Cas d’usage** :
- Détecter une saturation de disque.
- Analyser les performances disque (lecture/écriture, attente).
- Identifier les goulots d'étranglement sur les disques physiques.

### 🔍 **Exemple de commande** :
```bash
iostat -dx 2 3
```
→ Statistiques **détaillées** des disques, toutes les 2 sec, 3 fois.

### 📊 **Exemple de sortie commentée** :
```
Device:    r/s   w/s  rkB/s  wkB/s  await  %util
sda        10     5    400    200   10.5    70.0
```

### 📝 **Commentaires** :
- `r/s`, `w/s` : lectures/écritures par seconde.
- `rkB/s`, `wkB/s` : débit en ko/s.
- `await` : temps moyen d’attente d’une opération (au-delà de 20 ms = suspect).
- `%util` : pourcentage d'utilisation disque (70% ici → OK, 100% = saturation !).

---

## 📉 **4. `ioping` – Latence disque**

### ✅ **Cas d’usage** :
- Tester la **latence** d'accès disque (comme `ping` pour le réseau).
- Diagnostiquer un **disque lent ou surchargé**.
- Comparer des performances entre SSD/HDD.

### 🔍 **Exemple de commande** :
```bash
ioping -c 5 /
```
→ 5 tests de latence sur le point de montage racine.

### 📊 **Exemple de sortie commentée** :
```
4 requests completed in 3.22 ms, avg latency 0.80 ms
```

### 📝 **Commentaires** :
- Latence < 1 ms sur SSD : très bon.
- Latence > 10 ms sur HDD ou VM : peut être un souci.

---

## 🌐 **5. `iftop` – Bande passante réseau par hôte**

### ✅ **Cas d’usage** :
- Identifier **les connexions réseau actives**.
- Voir qui **consomme de la bande passante**.
- Déboguer une application réseau lente.

### 🔍 **Exemple de commande** :
```bash
sudo iftop -i eth0
```

### 📊 **Exemple de sortie commentée** :
```
192.168.0.10 => 8.8.8.8            5.30Mb  5.20Mb  5.10Mb
192.168.0.10 => 192.168.0.1        1.00Mb  0.80Mb  0.70Mb
```

### 📝 **Commentaires** :
- Les colonnes : débit sur 2s / 10s / 40s.
- Le `=>` indique le **trafic sortant**, `<=>` pour bidirectionnel.
- Tu vois directement qui consomme le réseau.

---

## 📈 **6. `nload` – Graphique bande passante**

### ✅ **Cas d’usage** :
- Suivi **visuel** de la consommation réseau.
- Utile pour une **vue instantanée** ou pendant des tests de charge.
- Plus simple que `iftop` si on veut juste le total entrant/sortant.

### 🔍 **Exemple de commande** :
```bash
sudo nload -u M eth0
```

### 📊 **Exemple de sortie commentée** :
```
Device: eth0
Incoming:  1.23 MBit/s
Outgoing:  0.54 MBit/s
```

### 📝 **Commentaires** :
- Très visuel (graphique ASCII).
- Idéal pour **voir une saturation réseau en direct**.

---

## 🧪 **Cas d'utilisation combiné**
Exemple de diagnostic sur une VM lente :
1. `vmstat 1` → Y a-t-il du swap ou des blocages ?
2. `mpstat -P ALL 1` → CPU saturé ?
3. `iostat -dx 1` → Disque lent ?
4. `iftop` ou `nload` → Trafic réseau élevé ?
5. `ioping` → Vérifier si le disque est lent ou congestionné.

---

Souhaitez-tu que je crée un **script shell automatisé** pour enchaîner tous ces tests ?