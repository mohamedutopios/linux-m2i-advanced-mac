Voici la procédure claire et simple pour créer rapidement une VM **Debian** avec **Vagrant** en utilisant **VirtualBox** :

---

## ⚙️ **Pré-requis**

1. **Installer Vagrant :** [https://www.vagrantup.com/downloads](https://www.vagrantup.com/downloads)
2. **Installer VirtualBox :** [https://www.virtualbox.org/wiki/Downloads](https://www.virtualbox.org/wiki/Downloads)

Assurez-vous que les commandes fonctionnent bien :
```bash
vagrant --version
VBoxManage --version
```

---

## 📝 **Création du Vagrantfile**

Ouvre un terminal ou invite de commandes et crée un dossier dédié à ton projet :

```bash
mkdir debian-vm
cd debian-vm
```

Ensuite, initialise une configuration de base avec Debian comme box :

```bash
vagrant init debian/bookworm64
```

Cela génère automatiquement un fichier nommé `Vagrantfile` dans ton dossier.

---

## 📂 **Exemple de Vagrantfile pour Debian**

Voici un exemple de Vagrantfile personnalisé, prêt à l'emploi :

```ruby
Vagrant.configure("2") do |config|
  # Box Debian officielle (Bookworm 12.x)
  config.vm.box = "debian/bookworm64"

  # Nom personnalisé pour la VM
  config.vm.hostname = "debian-vm"

  # Configuration du réseau privé (optionnel)
  config.vm.network "private_network", ip: "192.168.56.10"

  # Mémoire et CPU
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "2048"
    vb.cpus = 2
  end

  # Provisionnement initial avec un script shell simple (optionnel)
  config.vm.provision "shell", inline: <<-SHELL
    sudo apt-get update -y
    sudo apt-get install -y vim curl git
  SHELL
end
```

---

## 🚀 **Démarrer la VM**

Une fois que ton `Vagrantfile` est prêt, lance cette commande pour démarrer ta VM :

```bash
vagrant up
```

La première fois, Vagrant téléchargera automatiquement la box Debian si nécessaire.

---

## 🔑 **Accéder à ta VM**

Accède facilement à ta VM Debian via SSH :

```bash
vagrant ssh
```

Tu seras immédiatement connecté en tant qu'utilisateur `vagrant`.

- Pour passer root :

```bash
sudo -i
```

---

## 🔧 **Commandes utiles**

| Commande               | Description                                      |
|------------------------|--------------------------------------------------|
| `vagrant up`           | Démarrer la VM                                   |
| `vagrant ssh`          | Connexion SSH à la VM                            |
| `vagrant halt`         | Arrêter la VM                                    |
| `vagrant suspend`      | Suspendre la VM (mise en pause)                  |
| `vagrant reload`       | Redémarrer la VM                                 |
| `vagrant destroy`      | Supprimer définitivement la VM                   |
| `vagrant status`       | Vérifier le statut actuel de la VM               |
| `vagrant provision`    | Rejouer la configuration (scripts shell, Ansible, etc.) |

---

## ✅ **Vérification**

Tu peux vérifier que tu as bien une VM Debian fonctionnelle :

```bash
cat /etc/os-release
```

Tu obtiendras quelque chose comme :

```
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
```

---

**🎯 Conclusion :**

Ta VM Debian créée avec Vagrant est immédiatement prête à l’emploi, reproductible, et facile à partager ou modifier grâce au Vagrantfile.


- Exemple de connexion : 
- PS C:\Users\mohamed> ssh -i "C:\Users\mohamed\Downloads\linux_avance\demo\vagrant\debian-vm\.vagrant\machines\default\virtualbox\private_key" vagrant@192.168.56.10