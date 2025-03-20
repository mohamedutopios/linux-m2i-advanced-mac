Voici une série de **tests pratiques** où nous allons **créer volontairement des goulets d’étranglement** (problèmes de performance) et utiliser les bonnes commandes pour **les résoudre ou les optimiser**.  

---

## **🔍 4. Identifier et résoudre les goulets d’étranglement**

### 🧠 **Problème 1 : Trop d’utilisation du swap ralentit le système**
🔹 **Créer le problème :** On force l’utilisation du swap en remplissant la RAM.
```bash
stress-ng --vm 2 --vm-bytes 90% --timeout 60s
```
📌 *Cette commande va utiliser 90% de la RAM disponible avec 2 processus pendant 60 secondes, forçant le système à basculer sur le swap.*

✅ **Solution : Diminuer la priorité du swap pour qu'il soit moins utilisé**
```bash
sysctl -w vm.swappiness=10
echo "vm.swappiness=10" >> /etc/sysctl.conf
```
📌 *Cela force le noyau à utiliser la RAM au maximum avant de passer au swap.*

---

### 🔥 **Problème 2 : Un processus utilise trop de CPU et ralentit tout le système**
🔹 **Créer le problème :** On génère une charge CPU élevée avec un test de calcul intensif.
```bash
stress-ng --cpu 4 --timeout 60s
```
📌 *Cela va simuler 4 processus en train d’utiliser 100% du CPU pendant 60 secondes.*

✅ **Solution : Réduire la priorité du processus**
```bash
renice -n 10 -p <PID>
```
📌 *Cela réduit la priorité du processus pour éviter qu’il monopolise le CPU.*

✅ **Autre solution : Limiter son accès aux ressources CPU avec cgroups**
```bash
cgcreate -g cpu:/lowpriority
cgclassify -g cpu:/lowpriority <PID>
```
📌 *Cela place le processus dans un groupe de contrôle qui lui attribue moins de ressources CPU.*

---

### 💾 **Problème 3 : Un processus génère trop d’écritures disque, ralentissant tout le système**
🔹 **Créer le problème :** On écrit massivement sur le disque.
```bash
dd if=/dev/zero of=/tmp/testfile bs=1M count=10000
```
📌 *Cela écrit 10 Go de données sur le disque, surchargeant les I/O.*

✅ **Solution : Réduire sa priorité d’accès au disque**
```bash
ionice -c3 -p <PID>
```
📌 *Cela place le processus en priorité basse pour l’accès au disque.*

---

### 🚀 **Problème 4 : Mauvaise gestion des entrées/sorties sur un SSD**
🔹 **Créer le problème :** On utilise un ordonnanceur d’IO inadapté pour un SSD.
```bash
echo cfq > /sys/block/sda/queue/scheduler
```
📌 *CFQ (Completely Fair Queuing) est conçu pour les disques durs traditionnels, ce qui peut nuire aux performances d’un SSD.*

✅ **Solution : Utiliser un ordonnanceur optimisé pour SSD**
```bash
echo deadline > /sys/block/sda/queue/scheduler
```
📌 *Le scheduler "deadline" réduit la latence pour les SSD en minimisant les écritures non nécessaires.*

---

### 🔄 **Problème 5 : Un trop grand nombre de connexions réseau ralentit la machine**
🔹 **Créer le problème :** On simule une surcharge réseau en envoyant une multitude de connexions vers une machine.
```bash
hping3 -S -p 80 -c 10000 <IP>
```
📌 *Cette commande envoie 10 000 paquets TCP SYN vers le port 80, simulant une attaque de type SYN flood.*

✅ **Solution : Limiter le nombre de connexions ouvertes par IP**
```bash
iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 10 -j DROP
```
📌 *Cela bloque les adresses IP qui ouvrent plus de 10 connexions simultanées sur le port 80.*

---

### ⏳ **Problème 6 : Un trop grand nombre de processus en attente bloque le système**
🔹 **Créer le problème :** On lance trop de processus en parallèle.
```bash
for i in {1..1000}; do sleep 1000 & done
```
📌 *Cela lance 1000 processus "sleep", ce qui remplit la table des processus.*

✅ **Solution : Déterminer le nombre maximal de processus et l’augmenter si nécessaire**
```bash
ulimit -u
ulimit -u 4096
```
📌 *On ajuste le nombre maximal de processus utilisables par un utilisateur.*

---

Ces démos vous permettent de **créer et résoudre des problèmes réels** sur un système Debian. Vous pouvez **tester chaque cas** et observer comment le système réagit avant et après l’optimisation. 🚀

Besoin d’autres scénarios ? Je peux en ajouter d’autres spécifiques à votre environnement ! 😊