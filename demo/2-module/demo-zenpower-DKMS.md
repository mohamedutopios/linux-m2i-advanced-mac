Voici un excellent exemple, très pratique et rapide à tester, que tu peux installer avec DKMS :

# ✅ **Module "zenpower" : Surveillance de température CPU pour les processeurs AMD Ryzen**

---

## 🚩 **Pourquoi choisir Zenpower comme exemple réel ?**

Le module **Zenpower** permet d'accéder aux informations de température des processeurs **AMD Ryzen**, car ces infos ne sont pas toujours correctement prises en charge nativement par le noyau Linux.

- **Très utile** au quotidien pour surveiller la température CPU.
- Installation rapide via DKMS.
- Résultat immédiat, facile à vérifier.

---

## 🔧 **Installation complète de zenpower avec DKMS :**

### 1. Préparation (installer DKMS, git, et outils de compilation) :

```bash
sudo apt update
sudo apt install -y build-essential linux-headers-$(uname -r) dkms git
```

---

### 2. Téléchargement du module zenpower :

```bash
cd ~
git clone https://github.com/ocerman/zenpower.git
```

---

### 3. Installation automatique avec DKMS :

Entre dans le dossier et exécute le script DKMS :

```bash
cd zenpower
sudo ./dkms-install.sh
```

Ce script automatique fait les choses suivantes :

- Copie les fichiers vers `/usr/src/zenpower-VERSION`
- Ajoute automatiquement le module à DKMS
- Compile et installe immédiatement le module

---

### 4. Vérifie que le module est bien installé et chargé :

```bash
dkms status
```

Tu obtiendras quelque chose comme :

```
zenpower, 0.2.1, 6.1.0-29-amd64, x86_64: installed
```

Puis charge immédiatement le module si ce n’est pas déjà fait :

```bash
sudo modprobe zenpower
```

---

## 🚨 **Test immédiat du fonctionnement du module :**

Utilise maintenant la commande `sensors` pour vérifier immédiatement le fonctionnement :

```bash
sudo apt install lm-sensors -y
sensors
```

Tu obtiens immédiatement les températures du processeur Ryzen :

**Exemple réel de résultat :**

```
zenpower-pci-00c3
Adapter: PCI adapter
Tctl:         +45.0°C  
Tdie:         +45.0°C  
Tccd1:        +42.8°C  
```

---

## 📌 **Décharger ou supprimer ce module (si besoin)** :

- Décharger temporairement :

```bash
sudo modprobe -r zenpower
```

- Supprimer définitivement avec DKMS :

```bash
sudo dkms remove zenpower/0.2.1 --all
```

---

## 🎯 **Résumé clair (copie-colle) :**

Installation complète et vérification rapide en une seule fois :

```bash
# Préparation
sudo apt update
sudo apt install -y build-essential linux-headers-$(uname -r) dkms git lm-sensors

# Téléchargement
git clone https://github.com/ocerman/zenpower.git
cd zenpower

# Installation via DKMS
sudo ./dkms-install.sh

# Chargement immédiat
sudo modprobe zenpower

# Vérification immédiate du fonctionnement
sensors
```

---

✅ **Pourquoi cet exemple est idéal :**

- Utile au quotidien pour la surveillance CPU
- Installation rapide et simple
- Résultats instantanés à tester immédiatement après installation
- Très pédagogique et adapté à une démonstration complète avec DKMS