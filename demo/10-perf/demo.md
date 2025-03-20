Voici une série de **démonstrations pratiques** pour chaque thématique abordée dans le guide. Chaque démo est détaillée avec **les étapes et commandes** associées, pour une mise en pratique immédiate sur Debian.

---

## 🔍 **1. Recherche des problèmes de performance**

### 📌 **Surveillance en temps réel des ressources système**
#### **Étape 1 : Afficher l’utilisation du CPU et de la mémoire en temps réel**
```bash
top
```
🔹 **htop** offre une interface plus lisible :
```bash
htop
```
🔹 Affichage détaillé de chaque cœur du CPU :
```bash
mpstat -P ALL 1
```

#### **Étape 2 : Vérifier l'utilisation mémoire et le swap**
```bash
free -m
```
🔹 **Analyser la mémoire et le swap sur plusieurs secondes** :
```bash
vmstat 1 5
```

#### **Étape 3 : Analyser les processus qui monopolisent le disque**
```bash
iotop
```
🔹 **Surveiller les statistiques disque avec des détails par périphérique** :
```bash
iostat -x 1 5
```

#### **Étape 4 : Vérifier l'activité réseau**
```bash
iftop -i eth0
```
🔹 **Lister toutes les connexions réseau actives** :
```bash
ss -tuna
```

---

## 🔍 **2. Analyse des différentes couches**

### 🖥 **Analyse du CPU**
#### **Étape 1 : Voir la charge du système sur 1, 5 et 15 min**
```bash
uptime
```
#### **Étape 2 : Analyser les interruptions et context switches**
```bash
vmstat 1 5
```

#### **Étape 3 : Identifier les processus les plus consommateurs**
```bash
pidstat -u 1
```
🔹 **Voir l’utilisation CPU détaillée par processus et threads :**
```bash
top -H -p <PID>
```

---

### 💾 **Analyse de la mémoire**
#### **Étape 1 : Suivre l’évolution de la mémoire et du swap**
```bash
sar -r 1 5
```

#### **Étape 2 : Trouver les processus gourmands en mémoire**
```bash
ps aux --sort=-%mem | head -10
```
🔹 **Détails d’un processus spécifique :**
```bash
pmap <PID>
```

---

### 📀 **Analyse des performances disque**
#### **Étape 1 : Vérifier l’utilisation des disques**
```bash
df -h
```
🔹 **Voir le débit et la latence des disques :**
```bash
iostat -dx 1 5
```

#### **Étape 2 : Repérer les fichiers les plus volumineux**
```bash
du -ahx / | sort -rh | head -20
```

---

### 🌐 **Analyse du réseau**
#### **Étape 1 : Surveiller la bande passante sur une interface**
```bash
nload eth0
```
#### **Étape 2 : Voir les connexions en attente et les ports ouverts**
```bash
ss -tuln
```

---

## 🏎 **3. Tester les performances**

### ⚙ **Tester le CPU**
#### **Étape 1 : Tester les performances du processeur avec sysbench**
```bash
sysbench cpu --cpu-max-prime=20000 run
```

---

### 🛠 **Tester la mémoire**
#### **Étape 1 : Vérifier la vitesse d’accès mémoire**
```bash
sysbench memory --memory-block-size=1M --memory-total-size=5G run
```

---

### 📂 **Tester les performances disque**
#### **Étape 1 : Vérifier le débit de lecture d’un disque**
```bash
hdparm -Tt /dev/sda
```
#### **Étape 2 : Simuler une charge disque avec fio**
```bash
fio --name=randwrite --ioengine=libaio --rw=randwrite --bs=4k --size=1G --numjobs=4 --runtime=30 --group_reporting
```

---

### 🌐 **Tester les performances réseau**
#### **Étape 1 : Vérifier la latence du réseau**
```bash
ping -c 5 8.8.8.8
```
#### **Étape 2 : Tester la bande passante entre deux machines avec iperf**
🔹 **Démarrer un serveur iperf sur une machine A :**
```bash
iperf -s
```
🔹 **Lancer un test de débit depuis une machine B :**
```bash
iperf -c <IP_MACHINE_A>
```

---

## 🔍 **4. Identifier et résoudre les goulets d’étranglement**

### ⚙ **Optimisation des paramètres noyau**
#### **Étape 1 : Ajuster le swapiness pour éviter d’utiliser trop de swap**
```bash
sysctl -w vm.swappiness=10
```
🔹 **Rendre le changement permanent :**
```bash
echo "vm.swappiness=10" >> /etc/sysctl.conf
```

---

### ⚡ **Optimiser l’utilisation des processus**
#### **Étape 1 : Modifier la priorité d’un processus**
```bash
renice -n 10 -p <PID>
```
#### **Étape 2 : Réduire la priorité d’un processus qui écrit beaucoup sur le disque**
```bash
ionice -c3 -p <PID>
```

---

### 🚀 **Optimisation avancée des disques**
#### **Étape 1 : Changer la politique d’ordonnancement d’IO pour un SSD**
```bash
echo deadline > /sys/block/sda/queue/scheduler
```

---

## 📊 **5. Supervision centralisée avec Prometheus**

### 🔹 **Installation de Prometheus et Node Exporter**
#### **Étape 1 : Installer les paquets nécessaires**
```bash
sudo apt update && sudo apt install prometheus prometheus-node-exporter
```
#### **Étape 2 : Vérifier que node_exporter fonctionne**
```bash
curl http://localhost:9100/metrics
```

---

### 📊 **Mise en place de Grafana**
#### **Étape 1 : Installer Grafana**
```bash
sudo apt install grafana
```
#### **Étape 2 : Ajouter Prometheus comme source de données**
Dans Grafana :
1. Aller dans **Configuration > Data Sources**.
2. Ajouter **Prometheus** avec l’URL `http://localhost:9090`.

#### **Étape 3 : Importer un tableau de bord pour Linux**
Dans Grafana :
1. Aller dans **Dashboards > Import**.
2. Entrer l’ID `1860` pour importer **Node Exporter Full**.

---

### 📢 **Configurer les alertes avec Prometheus**
#### **Étape 1 : Créer une règle d’alerte CPU élevé**
Éditer le fichier `/etc/prometheus/prometheus.yml` :
```yaml
rule_files:
  - "alert.rules.yml"
```
Créer `alert.rules.yml` :
```yaml
groups:
- name: CPU_Alerts
  rules:
  - alert: HighCpuLoad
    expr: avg(rate(node_cpu_seconds_total{mode!="idle"}[5m])) > 0.9
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "CPU load élevé"
```
Redémarrer Prometheus :
```bash
sudo systemctl restart prometheus
```

---

## ✅ **Conclusion**
Avec ces **démos pratiques**, vous avez toutes les **commandes essentielles** pour surveiller et optimiser un serveur Debian. 🎯  
Elles couvrent **la détection des goulets d’étranglement**, **les tests de performance**, **l’optimisation système** et **la supervision avec Prometheus et Grafana**. 🚀  

Besoin d’une démo plus détaillée sur un point précis ? N’hésitez pas à demander ! 😊