Parfait ! Voici un **pas à pas complet** pour créer une **VM Prometheus + Grafana** avec Vagrant, qui surveillera une **autre VM Debian** déjà configurée avec `node_exporter`.

---

## 🏗️ Architecture cible

- **VM1 (debian-vm)** → IP : `192.168.56.11`  
  ➤ Fournit les métriques avec `node_exporter` sur le port `9100`.

- **VM2 (prometheus-vm)** → IP : `192.168.56.10`  
  ➤ Contient Prometheus (port `9090`) + Grafana (port `3000`)  
  ➤ Scrape la VM1

---

## 🧾 Étape 1 : Structure du projet

Crée un dossier pour ton projet :
```bash
mkdir vagrant-prometheus-lab && cd vagrant-prometheus-lab
```

---

## 📁 Étape 2 : Créer le fichier `Vagrantfile`

```ruby
Vagrant.configure("2") do |config|

  # VM cible à surveiller
  config.vm.define "debian-vm" do |debian|
    debian.vm.box = "debian/bookworm64"
    debian.vm.hostname = "debian-vm"
    debian.vm.network "private_network", ip: "192.168.56.11"
    debian.vm.provider "virtualbox" do |vb|
      vb.memory = 1024
      vb.cpus = 1
    end
    debian.vm.provision "shell", inline: <<-SHELL
      apt-get update -y
      apt install -y wget curl net-tools vim

      # Installer Node Exporter
      useradd --no-create-home --shell /bin/false node_exporter
      cd /tmp
      wget https://github.com/prometheus/node_exporter/releases/download/v1.8.1/node_exporter-1.8.1.linux-amd64.tar.gz
      tar -xzf node_exporter-1.8.1.linux-amd64.tar.gz
      cp node_exporter-1.8.1.linux-amd64/node_exporter /usr/local/bin/
      
      cat <<EOF > /etc/systemd/system/node_exporter.service
      [Unit]
      Description=Node Exporter
      After=network.target

      [Service]
      User=node_exporter
      ExecStart=/usr/local/bin/node_exporter

      [Install]
      WantedBy=default.target
      EOF

      systemctl daemon-reexec
      systemctl daemon-reload
      systemctl enable node_exporter
      systemctl start node_exporter
    SHELL
  end

  # VM Prometheus + Grafana
  config.vm.define "prometheus-vm" do |prometheus|
    prometheus.vm.box = "debian/bookworm64"
    prometheus.vm.hostname = "prometheus-vm"
    prometheus.vm.network "private_network", ip: "192.168.56.10"
    prometheus.vm.provider "virtualbox" do |vb|
      vb.memory = 2048
      vb.cpus = 2
    end
    prometheus.vm.provision "shell", inline: <<-SHELL
      apt-get update -y
      apt install -y wget curl vim net-tools software-properties-common apt-transport-https

      # Créer utilisateur prometheus
      useradd --no-create-home --shell /bin/false prometheus

      # Installer Prometheus
      cd /tmp
      wget https://github.com/prometheus/prometheus/releases/download/v2.50.1/prometheus-2.50.1.linux-amd64.tar.gz
      tar -xzf prometheus-2.50.1.linux-amd64.tar.gz
      cd prometheus-2.50.1.linux-amd64
      cp prometheus promtool /usr/local/bin/
      mkdir -p /etc/prometheus /var/lib/prometheus
      cp -r consoles/ console_libraries/ /etc/prometheus/
      cp prometheus.yml /etc/prometheus/

      # Configuration Prometheus avec cible debian-vm
      cat <<EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 10s

scrape_configs:
  - job_name: 'debian-node'
    static_configs:
      - targets: ['192.168.56.11:9100']
EOF

      chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
      chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

      cat <<EOF > /etc/systemd/system/prometheus.service
      [Unit]
      Description=Prometheus
      Wants=network-online.target
      After=network-online.target

      [Service]
      User=prometheus
      ExecStart=/usr/local/bin/prometheus \\
        --config.file=/etc/prometheus/prometheus.yml \\
        --storage.tsdb.path=/var/lib/prometheus \\
        --web.listen-address=:9090

      [Install]
      WantedBy=default.target
      EOF

      systemctl daemon-reload
      systemctl enable prometheus
      systemctl start prometheus

      # Ajouter Grafana
      mkdir -p /etc/apt/keyrings
      wget -q -O - https://apt.grafana.com/gpg.key | tee /etc/apt/keyrings/grafana.asc
      echo "deb [signed-by=/etc/apt/keyrings/grafana.asc] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list

      apt-get update -y
      apt-get install -y grafana
      systemctl enable grafana-server
      systemctl start grafana-server
    SHELL
  end
end
```

---

## 🚀 Étape 3 : Lancer les VMs

```bash
vagrant up
```

> Tu peux aussi faire `vagrant reload --provision` si tu modifies le Vagrantfile ensuite.

---

## 🌐 Étape 4 : Accéder aux interfaces

| Service       | Adresse depuis l’hôte       |
|---------------|-----------------------------|
| Prometheus    | http://192.168.56.10:9090   |
| Grafana       | http://192.168.56.10:3000   |
| Node Exporter | http://192.168.56.11:9100   |

---

## ✅ Étape 5 : Configurer Grafana

1. Aller sur `http://192.168.56.10:3000`
2. Login : `admin` / `admin`
3. **Add Data Source** → Prometheus
   - URL : `http://localhost:9090`
4. **Save & Test**
5. **Import un dashboard Node Exporter** (par exemple ID `1860`)

---

## 🎉 Résultat

- `node_exporter` expose les métriques sur `192.168.56.11:9100`
- `prometheus` les scrape toutes les 10s
- `grafana` affiche les résultats avec de beaux dashboards

---

Souhaites-tu que je t’ajoute aussi **des règles d’alerting Prometheus**, ou des dashboards personnalisés ?