Voici un exemple détaillé qui présente, pour chaque scénario, comment on peut :

1. **Créer le problème** (simuler le goulet d'étranglement),  
2. **Le détecter** (observer le symptôme ou mesurer l’impact),  
3. **Appliquer la solution** pour l’atténuer ou l’éliminer.

---

## Scénario 1 : Utilisation excessive du swap

### Création du problème  

La sortie de `free -m` indique que la partition (ou le fichier) swap n'est pas configurée sur votre système, c'est pourquoi vous voyez « Swap: 0 ». Même si stress-ng a bien sollicité la mémoire (90 % de la RAM), le système n'a pas pu utiliser de swap car aucun espace swap n'a été défini.

### Explication détaillée

- **Stress test réussi :**  
  La commande `stress-ng --vm 2 --vm-bytes 90% --timeout 60s` a bien été exécutée pendant 60 secondes, sollicitant la mémoire RAM.

- **Absence de swap :**  
  La commande `free -m` affiche « Swap: 0 0 0 », ce qui signifie qu'il n'y a pas de swap configuré.  
  Par défaut, si vous n'avez pas créé de partition ou de fichier swap, le système ne pourra pas utiliser de swap, même en cas de pression mémoire.

### Comment créer un fichier swap pour voir l'utilisation du swap

Si vous souhaitez activer le swap pour observer son utilisation en cas de stress, vous pouvez créer un fichier swap. Voici les commandes à exécuter :

1. **Créer un fichier swap de 512 Mo :**
   ```bash
   sudo fallocate -l 512M /swapfile
   ```
   Si `fallocate` n'est pas disponible, vous pouvez utiliser :
   ```bash
   sudo dd if=/dev/zero of=/swapfile bs=1M count=512
   ```

2. **Définir les permissions correctes pour le fichier swap :**
   ```bash
   sudo chmod 600 /swapfile
   ```

3. **Configurer le fichier en tant que swap :**
   ```bash
   sudo mkswap /swapfile
   ```

4. **Activer le swap :**
   ```bash
   sudo swapon /swapfile
   ```

5. **Vérifier la configuration :**
   ```bash
   free -m
   ```
   Vous devriez maintenant voir une section « Swap » avec la taille configurée.

6. **Pour rendre la modification permanente :**  
   Ajoutez la ligne suivante dans `/etc/fstab` :
   ```bash
   /swapfile none swap sw 0 0
   ```
   
On force l'utilisation du swap en consommant 90 % de la RAM avec deux processus pendant 60 secondes.  
```bash
stress-ng --vm 2 --vm-bytes 90% --timeout 60s
```
> **Explication :** Cette commande alloue 90 % de la mémoire pour chaque processus, forçant le système à décharger une partie de la RAM sur le swap, ce qui ralentit les performances.

### Détection du problème  
- **Observation du système :**  
  On peut utiliser des outils comme `vmstat` ou `free -m` pour constater une augmentation importante du swap utilisé.  
  ```bash
  free -m
  ```
  Vous verrez que la colonne « Swap » est fortement utilisée et que le temps de réponse du système augmente.

### Solution  
Réduire la priorité du swap afin que le système privilégie l’utilisation de la RAM avant de passer au swap.
```bash
sudo sysctl -w vm.swappiness=10
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
```
> **Explication :** Un swappiness de 10 fait en sorte que le noyau utilisera la RAM autant que possible avant d'utiliser le swap, améliorant ainsi la réactivité.

---

## Scénario 2 : Surcharge CPU par un processus gourmand

### Création du problème  
On génère une charge CPU élevée en lançant 4 processus de calcul intensif pendant 60 secondes.
```bash
stress-ng --cpu 4 --timeout 60s
```
> **Explication :** Cette commande utilise 100 % du CPU sur 4 threads, ce qui peut ralentir l'ensemble du système.

### Détection du problème  
- **Observation de la charge CPU :**  
  Avec `top`, `htop` ou `pidstat -u 1`, on peut observer qu’un ou plusieurs processus consomment une part importante du CPU.
  ```bash
  top
  ```
  Le(s) processus concernés apparaîtront avec un pourcentage élevé d'utilisation CPU.

### Solution  
Réduire la priorité du processus pour qu’il ait moins d’impact sur le système.
```bash
sudo renice -n 10 -p <PID>
```
> **Alternative avec cgroups :**  
  Pour limiter l’accès aux ressources CPU du processus, on peut le placer dans un groupe de contrôle :
  ```bash
  sudo cgcreate -g cpu:/lowpriority
  sudo cgclassify -g cpu:/lowpriority <PID>
  ```
> **Explication :** En augmentant la valeur de renice ou en utilisant des cgroups, le processus aura une priorité plus faible, ce qui permettra à d’autres processus critiques d’obtenir leur part de CPU.

---

## Scénario 3 : Surcharge d'écritures disque

### Création du problème  
On effectue un transfert massif de données en écrivant 10 Go sur le disque.
```bash
dd if=/dev/zero of=/tmp/testfile bs=1M count=10000
```
> **Explication :** Cette commande écrit 10 Go de zéros sur le disque, générant une charge I/O importante qui peut ralentir les autres opérations sur le disque.

### Détection du problème  
- **Observation de l'utilisation des I/O :**  

  Avec `iostat -xz 1` ou `iotop`, on peut voir que le disque est fortement sollicité.
  ```bash
  sudo apt install iotop
  iotop
  ```
  Le processus dd ou tout autre processus effectuant beaucoup d'écritures apparaîtra en haut de la liste.

### Solution  
Réduire la priorité d'accès au disque du processus afin de limiter son impact sur l'ensemble du système.
```bash
sudo ionice -c3 -p <PID>
```
> **Explication :** La classe 3 (idle) de ionice garantit que le processus n'aura accès aux I/O que lorsque le système est inactif, laissant la priorité aux autres opérations critiques.

---

## Scénario 4 : Ordonnanceur I/O inadapté pour un SSD

### Création du problème  
On configure l'ordonnanceur de disque pour utiliser CFQ, qui est plus adapté aux disques durs traditionnels qu'aux SSD.
```bash
echo cfq | sudo tee /sys/block/sda/queue/scheduler
```
> **Explication :** CFQ (Completely Fair Queuing) peut induire une latence supplémentaire sur un SSD, impactant négativement les performances.

### Détection du problème  
- **Mesure des performances I/O :**  
  On peut utiliser `fio` ou `ioping` pour mesurer la latence et les débits du SSD, et constater des performances inférieures aux attentes.

### Solution  
Changer l'ordonnanceur pour un scheduler optimisé pour les SSD, comme `deadline`.
```bash
echo deadline | sudo tee /sys/block/sda/queue/scheduler
```
> **Explication :** Le scheduler deadline est mieux adapté aux SSD car il réduit la latence en évitant des écritures superflues, améliorant ainsi les performances.

---

## Scénario 5 : Surcharge de connexions réseau (SYN flood)

### Création du problème  
On simule une attaque SYN flood en envoyant 10 000 paquets TCP SYN vers le port 80 d'une machine.
```bash
hping3 -S -p 80 -c 10000 <IP>
```
> **Explication :** Cette commande envoie 10 000 paquets SYN, ce qui surcharge le système avec un trop grand nombre de connexions incomplètes, épuisant les ressources.

### Détection du problème  
- **Observation des connexions :**  
  sudo apt install net-tools
  Avec `netstat -an` ou `ss -s`, on peut constater un nombre élevé de connexions en attente sur le port 80.

### Solution  
Limiter le nombre de connexions simultanées par IP avec iptables.
```bash
sudo iptables -A INPUT -p tcp --dport 80 -m connlimit --connlimit-above 10 -j DROP
```
> **Explication :** Cette règle bloque les adresses IP qui essaient d’ouvrir plus de 10 connexions simultanées vers le port 80, empêchant ainsi une surcharge du système.

---

## Scénario 6 : Trop de processus en attente

### Création du problème  
On lance 1000 processus en parallèle qui ne font rien (sleep), saturant ainsi la table des processus.
```bash
for i in {1..1000}; do sleep 1000 & done
```
> **Explication :** Cette commande crée 1000 processus, ce qui peut atteindre la limite du nombre de processus autorisés pour l'utilisateur et bloquer le système.

### Détection du problème  
- **Vérification du nombre de processus :**  
  Avec `ulimit -u` on peut voir la limite actuelle du nombre de processus pour l'utilisateur.  
  On peut également utiliser `ps -e | wc -l` pour compter les processus en cours.

### Solution  
Augmenter la limite du nombre maximal de processus si nécessaire.
```bash
ulimit -u 4096
```
> **Explication :** En augmentant la limite, le système peut gérer plus de processus simultanément, ce qui est nécessaire dans certains environnements de test ou de production.

---

## Conclusion

Ces scénarios vous permettent de :

- **Créer volontairement des problèmes de performance** (swap, CPU, disque, I/O, réseau, processus).
- **Les détecter** à l'aide d'outils de surveillance (vmstat, top, iotop, netstat, ss, etc.).
- **Appliquer des solutions** pour améliorer les performances : en ajustant la priorité, en modifiant les paramètres du noyau ou en limitant les ressources.

Ce LAB offre ainsi une approche pratique pour identifier et résoudre divers goulets d’étranglement sur un système Debian. Vous pouvez adapter chaque scénario selon vos besoins et observer l’impact des modifications sur les performances globales du système.