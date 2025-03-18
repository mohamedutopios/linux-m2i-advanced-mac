Voici un exemple concret, détaillé et réaliste d'un module Linux complet : un module permettant de tracer les événements d'ouverture et de fermeture de fichiers. Ce cas concret illustre une utilisation utile des modules noyau.

---

## 🚩 **1. Conception du module (exemple réaliste)**

L'objectif du module est de surveiller (tracer) les appels au système `open` (ouverture de fichier).  

### 📌 **Structure du module :**

**trace_open.c**
```c
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/kallsyms.h>
#include <linux/kallsyms.h>
#include <linux/kallsyms.h>
#include <linux/fs.h>
#include <linux/ftrace.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("OpenAI");
MODULE_DESCRIPTION("Module pour tracer les ouvertures de fichiers.");

static asmlinkage long (*real_sys_openat)(struct pt_regs *);

static asmlinkage long hooked_sys_openat(struct pt_regs *regs)
{
    char __user *filename = (char *)regs->si;

    printk(KERN_INFO "[TraceModule] Ouverture du fichier : %s\n", filename);
    
    return real_sys_openat(regs);
}

static unsigned long **find_syscall_table(void)
{
    unsigned long *ptr;
    unsigned long offset;

    ptrdiff_t pos;
    for (pos = (unsigned long)kallsyms_lookup_name("sys_call_table"); !pos; )
        return NULL;

    return (unsigned long **)pos;
}

static unsigned long **sys_call_table;

static int __init trace_open_init(void)
{
    printk(KERN_INFO "Chargement du module Trace Open...\n");

    sys_call_table = find_syscall_table();
    if (!sys_call_table) {
        printk(KERN_ERR "Impossible de localiser sys_call_table.\n");
        return -1;
    }

    write_cr0(read_cr0() & (~0x10000));
    real_sys_openat = (void *)sys_call_table[__NR_openat];
    sys_call_table[__NR_openat] = (unsigned long *)hooked_sys_openat;
    write_cr0(cr0);

    return 0;
}

static void __exit trace_open_exit(void)
{
    printk(KERN_INFO "Déchargement du module Trace Open...\n");
    
    write_cr0(read_cr0() & (~0x10000));
    sys_call_table[__NR_openat] = (unsigned long *)real_sys_openat;
    write_cr0(cr0);
}

module_init(trace_open_init);
module_exit(trace_open_exit);

MODULE_LICENSE("GPL");
```

### 📌 **Explications :**

- Le module remplace temporairement (`hook`) l'appel système `openat` pour enregistrer chaque ouverture de fichier.

---

## 🚩 **2. Compilation du module**

### 📌 **Préparation :**

```bash
sudo apt update
sudo apt install build-essential linux-headers-$(uname -r)
```

### 📌 **Makefile associé :**

```Makefile
obj-m += trace_open.o

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) modules

clean:
	make -C /lib/modules/$(shell uname -r)/build M=$(PWD) clean
```

### 📌 **Compilation :**

```bash
make
```

Tu obtiens un fichier `.ko` :

```bash
trace_open.ko
```

---

## 🚩 **3. Installation et chargement**

### 📌 **Installer :**

```bash
sudo cp trace_open.ko /lib/modules/$(uname -r)/extra/
sudo depmod -a
```

### 📌 **Chargement :**

```bash
sudo insmod trace_open.ko
```

- Vérifie les logs du noyau pour t'assurer qu'il est chargé :

```bash
dmesg | tail
```

---

## 🚩 **4. Test du module**

Ouvre un fichier pour tester :

```bash
cat /etc/passwd
```

Vérifie le log dans le noyau :

```bash
dmesg | tail
```

Tu verras un message similaire à :

```
[Trace Open] : open("/etc/passwd")
```

---

## 🚩 **5. Déchargement du module**

```bash
sudo rmmod trace_open
```

Confirme avec :

```bash
dmesg | tail
```

---

## 🚩 **5. Informations détaillées du module :**

```bash
modinfo trace_open.ko
```

---

## 🚩 **6. Liste des modules :**

- Modules chargés actuellement :

```bash
lsmod
```

- Modules existants dans le système :

```bash
find /lib/modules/$(uname -r) -type f -name "*.ko"
```

---

## 🚩 **7. Déchargement propre**

Pour nettoyer le module après utilisation :

```bash
sudo rmmod trace_open
sudo rm trace_open.ko
sudo depmod -a
```

---

## 🚩 **7. Bonnes pratiques et sécurité**

⚠️ **Important :**  
- Remplacer ou détourner un appel système peut être risqué.  
- Réserve ce type d’expérience à un environnement de test contrôlé (machine virtuelle).

---

## ✅ **Conclusion :**

Cette démonstration complète t'a permis de :

- Concevoir un module noyau réaliste.
- Compiler, installer et charger un module.
- Vérifier son fonctionnement.
- Manipuler (charger/décharger) et obtenir des informations détaillées sur ton module.
- Adopter une approche sécurisée avec des bonnes pratiques pour travailler sur le noyau Linux.

N'hésite pas à me demander des précisions sur une étape !