Voici un **script réaliste complet** correspondant exactement à ta demande actuelle :

✅ Il génère plusieurs incidents matériels et réseau réalistes.  
✅ Il s'exécute entièrement en arrière-plan dès son téléchargement.  
✅ Il s'auto-supprime après exécution.  
❌ Il **ne corrige PAS** les problèmes générés (pour exercices de dépannage).

---

## 🚩 **Résumé des incidents générés :**

1. ⚠️ **Incident réseau (DNS)** : configuration d’un serveur DNS invalide (plus de résolution de noms).
2. ⚠️ **Incident matériel (saturation espace disque)** : remplit le disque à 100%.
3. ⚠️ **Incident système (surcharge CPU)** : crée un processus consommant fortement le CPU.

Ces incidents restent en place pour permettre une réelle analyse de dépannage ultérieure.

---

## 🎯 **Script complet (`incident_global.sh`) :**

Voici exactement ton script :

```bash
#!/bin/bash

(
# Incident réseau (DNS invalide)
echo "nameserver 10.123.123.123" | sudo tee /etc/resolv.conf >/dev/null
echo "[Incident] DNS configuré vers 10.123.123.123 (invalide)" >> /tmp/incidents.log

# Incident matériel (remplissage complet disque dur)
fallocate -l $(df --output=avail / | tail -1 | awk '{print $1}')K /tmp/fichier_rempli.img 2>/dev/null || \
dd if=/dev/zero of=/tmp/fichier_rempli.img bs=1M status=none
echo "[Incident] Disque rempli à 100% via /tmp/fichier_rempli.img" >> /tmp/incidents.log

# Incident surcharge CPU (processus consommant fortement le CPU)
( while :; do :; done ) &
echo "[Incident] Processus surcharge CPU lancé (PID: $!)" >> /tmp/incidents.log

# Fin de la génération d'incidents, auto-suppression du script
rm -f "$(readlink -f "$0")"
) &
```

---

## 🚩 **Comment exécuter automatiquement le script en arrière-plan immédiatement après téléchargement :**

Commande unique à exécuter depuis ta VM Linux :

```bash
wget -qO- http://URL_DE_TON_SCRIPT/incident_global.sh | bash &
```

Le script :

- Se télécharge immédiatement.
- S’exécute entièrement en arrière-plan.
- Ne bloque jamais ton terminal (tu peux continuer tes manipulations).
- Génère **3 incidents réalistes et persistants**.
- S’auto-supprime à la fin de l’exécution.

---

## 🎯 **Comment vérifier facilement les incidents créés :**

Vérifie rapidement les incidents générés avec :

```bash
cat /tmp/incidents.log
```

Exemple clair du résultat attendu :

```
[Incident] DNS configuré vers 10.123.123.123 (invalide)
[Incident] Disque rempli à 100% via /tmp/fichier_rempli.img
[Incident] Processus surcharge CPU lancé (PID: 3456)
```

---

## 🔧 **Outils à utiliser pour l'analyse des incidents générés :**

| Incident généré | Diagnostic immédiat                             | Outil(s) recommandés          |
|-----------------|--------------------------------------------------|-------------------------------|
| DNS invalide    | Impossible de résoudre les noms (ping KO)        | `cat /etc/resolv.conf`, `dig`, `ping`|
| Disque saturé   | Impossible d’écrire sur disque                   | `df -h`, `du -sh /tmp/*`      |
| CPU à 100%      | Système lent, forte charge CPU                   | `htop`, `top`, `ps aux --sort=-%cpu`|

---

## 🚩 **Proposition de démarche de résolution ultérieure :**

| Incident       | Solution corrective recommandée (à faire manuellement)     |
|----------------|-------------------------------------------------------------|
| DNS invalide   | Modifier `/etc/resolv.conf` avec DNS valide (8.8.8.8)      |
| Disque saturé  | `sudo rm /tmp/fichier_gros.img`                            |
| Surcharge CPU  | `sudo kill -9 PID` (PID identifié via log `/tmp/incidents.log`) |

---

## 🎯 **Tableau récapitulatif global**

| Incident généré              | Manifestation visible | Diagnostic rapide             | Correction simple      |
|-----------------------------|----------------------|-----------------------------|
| DNS invalide (`resolv.conf`)| Pas de réseau par nom | `ping google.com`             |
| Disque plein à 100%         | Échec création fichiers | `df -h`                    |
| CPU saturé à 100%           | Fort ralentissement     | `top`, `htop`               |

---

## 📌 **Pourquoi cette approche est intéressante ?**

- Elle est **réaliste** : incidents courants en administration Linux.
- Elle est **pratique** : chaque problème peut être identifié précisément par des outils classiques.
- Elle est **pédagogique** : idéale pour former des administrateurs système sur des cas concrets et réalistes.

---

## ✅ **Conclusion claire (résumé rapide)**

Ce script génère **automatiquement 3 incidents réalistes** sur une VM Linux :

- Incident réseau DNS  
- Incident stockage disque dur  
- Incident surcharge CPU  

Il ne les corrige pas (selon ta demande précise), te permettant ainsi de **tester tes compétences d’analyse et dépannage matériel** sur des scénarios réels et concrets.

Je reste disponible si tu veux approfondir, ajuster, ou aller encore plus loin !