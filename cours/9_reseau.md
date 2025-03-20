Je vais préparer un guide détaillé sur la maintenance de la configuration réseau sous Debian Linux, en couvrant les aspects suivants :
- Configuration des interfaces réseau, routage, DNS, pare-feu (iptables/firewalld), proxy et VPN.
- Méthodes de dépannage des problèmes courants.
- Optimisation des performances réseau.
- Sécurité et bonnes pratiques.
- Démonstrations et exemples concrets avec commandes et scripts.

Je vous tiens informé dès que l’analyse est terminée.

# Guide de maintenance de la configuration réseau sous Debian

Ce guide couvre les principaux aspects de la configuration réseau sur Debian Linux, de la mise en place des interfaces et du routage aux techniques de dépannage, d’optimisation et de sécurisation du réseau. Chaque section fournit des explications détaillées, des bonnes pratiques et des exemples concrets (avec commandes et scripts Bash) applicables en production. 

## 1. Configuration du réseau

### Gestion des interfaces réseau

Debian utilise traditionnellement le fichier de configuration `/etc/network/interfaces` pour définir les interfaces réseau et leurs paramètres. On peut y configurer des interfaces en **DHCP** ou en **IP statique**, définir la passerelle par défaut, etc. ([NetworkConfiguration - Debian Wiki](https://wiki.debian.org/NetworkConfiguration#:~:text=The%20majority%20of%20network%20setup,default%20routes%20and%20much%20more)). Les interfaces listées avec l’option `auto` seront activées automatiquement au démarrage. Par exemple, pour configurer une interface Ethernet `eth0` avec une adresse IP fixe : ([Chapter 2. interface configuration](http://linux-training.be/networking/ch02.html#:~:text=root%40debian7~,iface%20lo%20inet%20loopback))

```bash
# Exemple d'extrait de /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 10.42.189.198
    netmask 255.255.255.240
    gateway 10.42.189.193
    dns-nameservers 10.42.189.1 8.8.8.8
```

*(Cet exemple définit `eth0` en statique avec son adresse, masque, passerelle et serveurs DNS.)*

Une fois les interfaces définies, vous pouvez les activer ou désactiver manuellement avec les commandes **`ifup`** et **`ifdown`** (ex: `sudo ifdown eth0 && sudo ifup eth0`) ([NetworkConfiguration - Debian Wiki](https://wiki.debian.org/NetworkConfiguration#:~:text=Interfaces%20configured%20with%20,the%20ifup%20and%20ifdown%20commands)). Ces commandes appliquent les changements sans nécessiter de redémarrage du service réseau.

> **Remarque :** Sur les versions récentes de Debian (et dérivés), le schéma de nommage des interfaces a changé : la plupart des systèmes utilisent des **noms d’interface prévisibles** fournis par *systemd* (par ex. `enp0s25` au lieu de `eth0`) ([Chapitre 5. Configuration du réseau](https://www.debian.org/doc/manuals/debian-reference/ch05.fr.html#:~:text=systemd%20utilise%20,enp0s25)). Ainsi, vérifiez le nom exact de votre interface avec `ip link` ou `ip addr`. 

Debian peut aussi utiliser un **gestionnaire d’interfaces** comme **NetworkManager** (surtout en environnement desktop). Dans ce cas, on pourra gérer les connexions via l’outil en ligne de commande **`nmcli`** ou l’interface texte **`nmtui`**, et il faudra veiller à ce qu’il n’y ait pas de conflit entre NetworkManager et `/etc/network/interfaces` ([Chapitre 5. Configuration du réseau](https://www.debian.org/doc/manuals/debian-reference/ch05.fr.html#:~:text=match%20at%20L298%20%C2%AB%C2%A0,systemd)). Par exemple, `nmcli device status` liste les interfaces et leur état, et `nmcli connection show` affiche les profils de connexion gérés par NetworkManager.

Par ailleurs, l’ancienne commande **`ifconfig`** (du paquet *net-tools*) est aujourd’hui remplacée par la commande **`ip`** (du paquet *iproute2*) pour la gestion des interfaces. La commande `ip` offre une syntaxe plus puissante et cohérente ([Chapitre 5. Configuration du réseau](https://www.debian.org/doc/manuals/debian-reference/ch05.fr.html#:~:text=net,param%C3%A9trage%20du%20p%C3%A9riph%C3%A9rique%20Ethernet)). Par exemple : 

- `ip addr show` (équivalent de `ifconfig`) affiche les adresses et l’état des interfaces ([Chapitre 5. Configuration du réseau](https://www.debian.org/doc/manuals/debian-reference/ch05.fr.html#:~:text=commande%20%20description%20,des%20tables%20de%20cache%20d%E2%80%99ARP)).  
- `ip link set eth0 up`/`down` remplace `ifconfig eth0 up`/`down` pour activer ou désactiver une interface.  
- `ip addr add 192.168.1.100/24 dev eth0` permet d’ajouter une adresse IP à une interface donnée.

 ([The Linux 'ip' Command in Networking - CellStream, Inc.](https://www.cellstream.com/2018/10/26/linux-ip-command/)) *Figure 1: Exemple de sortie de `ip addr` sur Debian, listant les interfaces réseau avec leurs adresses IPv4/IPv6 et l’état (UP/DOWN) de chaque interface.*  

La figure ci-dessus illustre la sortie de `ip addr` sur un système Debian. On y voit l’interface de loopback (`lo`) et une interface Ethernet (`enp3s0`) qui est **UP** avec une adresse IPv4 (`192.168.1.119/24`) et plusieurs adresses IPv6. Le nom `enp3s0` suit la convention de nommage prévisible (Ethernet + emplacement physique) ([The Linux 'ip' Command in Networking - CellStream, Inc.](https://www.cellstream.com/2018/10/26/linux-ip-command/#:~:text=Here%20is%20how%20it%20works%3A%C2%A0,Ethernet%2C%20Port%2FBus%203%2C%20Slot%200)). On remarque également d’éventuelles interfaces virtuelles (par ex. `virbr0` pour une interface de bridge VM). Pour obtenir des détails sur une interface spécifique, on peut utiliser `ip addr show dev enp3s0`. 

### Configuration du routage IP

Le routage détermine vers où le système envoie les paquets en fonction des adresses de destination. Sur Debian, on peut définir la **passerelle par défaut** (gateway) dans `/etc/network/interfaces` en ajoutant une ligne `gateway x.x.x.x` dans la strophe de l’interface appropriée (comme dans l’exemple ci-dessus). Cela ajoutera automatiquement une route par défaut dans la table de routage.

Pour consulter et modifier les routes à la volée, on utilise la commande `ip route`. Par exemple, la commande `ip route show` affiche la table de routage courante (y compris la route par défaut) ([Chapitre 5. Configuration du réseau](https://www.debian.org/doc/manuals/debian-reference/ch05.fr.html#:~:text=%60route%20,des%20tables%20de%20cache%20d%E2%80%99ARP)). Un exemple de sortie typique est : 

```bash
$ ip route show
default via 192.168.1.1 dev enp3s0 proto dhcp src 192.168.1.119 metric 100 
192.168.1.0/24 dev enp3s0 proto kernel scope link src 192.168.1.119 
```

Ici, la première ligne indique la route par défaut (tout le trafic vers l’extérieur passe par la passerelle `192.168.1.1` via l’interface enp3s0). La seconde ligne indique que le réseau **192.168.1.0/24** est accessible directement sur `enp3s0` (réseau local). 

On peut ajouter une route statique avec `ip route add` – par exemple : `sudo ip route add 10.10.10.0/24 via 192.168.1.254 dev enp3s0` (ajoute une route vers le réseau 10.10.10.0/24 en passant par le routeur 192.168.1.254). Pour supprimer cette route : `ip route del 10.10.10.0/24 via 192.168.1.254 dev enp3s0`. Ces changements sont volatils (non persistants) à moins de les ajouter dans un fichier de config (`/etc/network/interfaces` ou un script de démarrage). 

> **Astuce :** La commande héritée `route -n` (du paquet net-tools) affiche aussi la table de routage, mais il est recommandé d’utiliser `ip route` pour les nouveaux systèmes ([Chapitre 5. Configuration du réseau](https://www.debian.org/doc/manuals/debian-reference/ch05.fr.html#:~:text=net,se%20basant%20sur%20l%E2%80%99adresse%20MAC)).

### Configuration du DNS

Sur Debian, la résolution DNS est configurée via le fichier **`/etc/resolv.conf`** qui contient les adresses des serveurs DNS à utiliser ([Chapitre 5. Configuration du réseau](https://www.debian.org/doc/manuals/debian-reference/ch05.fr.html#:~:text=%C2%AB%C2%A0,il%20contient%20ce%20qui%20suit)). Un fichier `/etc/resolv.conf` typique contient par exemple : 

```
nameserver 192.168.1.1
nameserver 8.8.8.8
```

Cela indique au système d’utiliser d’abord le serveur DNS à l’adresse 192.168.1.1 (souvent la box/routeur local), puis Google DNS (8.8.8.8) en second. **Attention :** si le paquet **`resolvconf`** est installé, le fichier `/etc/resolv.conf` sera géré automatiquement (et converti en lien symbolique) ([NetworkConfiguration - Debian Wiki](https://wiki.debian.org/NetworkConfiguration#The_resolv.conf_configuration_file#:~:text=When%20,etc%2Fresolvconf%2Frun%2Fresolv.conf)) ([NetworkConfiguration - Debian Wiki](https://wiki.debian.org/NetworkConfiguration#The_resolv.conf_configuration_file#:~:text=If%20the%20,etc%2Fnetwork%2Finterfaces)). Dans ce cas, on ne le modifie pas directement, mais on configure les DNS via les interfaces réseau (par exemple en ajoutant `dns-nameservers 8.8.8.8 8.8.4.4` dans `/etc/network/interfaces` pour une interface statique) ([NetworkConfiguration - Debian Wiki](https://wiki.debian.org/NetworkConfiguration#The_resolv.conf_configuration_file#:~:text=configuration%20file%20at%20)). 

Les systèmes modernes peuvent aussi utiliser **systemd-resolved**, un service de systemd dédié à la résolution DNS. Sur Debian, *systemd-resolved* n’est pas toujours activé par défaut, mais on peut le démarrer pour bénéficier de fonctionnalités comme la mise en cache DNS locale ou DNSSEC. Ses paramètres se trouvent dans `/etc/systemd/resolved.conf`. Une fois activé, on peut configurer `/etc/resolv.conf` pour qu’il pointe vers `127.0.0.53` (adresse du stub resolver systemd) ([NetworkConfiguration - Debian Wiki](https://wiki.debian.org/NetworkConfiguration#The_resolv.conf_configuration_file#:~:text=When%20,etc%2Fresolvconf%2Frun%2Fresolv.conf)). On peut vérifier l’état avec `systemd-resolve --status` (ou `resolvectl status` sur Debian 11+). 

En résumé, pour la configuration DNS sous Debian :

- **Statique** : éditer `/etc/resolv.conf` (si non géré par resolvconf/systemd) et y placer les lignes `nameserver`.  
- **Via resolvconf** : configurer les DNS dans les fichiers d’interfaces ou via NetworkManager, qui mettra à jour resolvconf.  
- **Via systemd-resolved** : activer le service et configurer la résolution via lui (optionnel).  

### Gestion du pare-feu (iptables / firewalld)

Debian intègre le pare-feu de Linux *netfilter*. L’outil classique pour le configurer est **iptables** (pour IPv4) et ip6tables (pour IPv6). Depuis Debian 10, iptables utilise en coulisse le moteur *nftables*, mais la syntaxe iptables reste disponible. 

Avec **iptables**, on définit des règles de filtrage dans différentes *chaînes* par défaut : **INPUT** (trafic entrant vers la machine), **OUTPUT** (trafic sortant) et **FORWARD** (trafic routé à travers la machine) ([Configuration IPtables sur Debian – Oleks IT Blog](https://oleks.ca/2024/09/23/configuration-iptables-sur-debian/#:~:text=INPUT%20%3A%20Cette%20cha%C3%AEne%20g%C3%A8re,passe%20par%20la%20cha%C3%AEne%20INPUT)) ([Configuration IPtables sur Debian – Oleks IT Blog](https://oleks.ca/2024/09/23/configuration-iptables-sur-debian/#:~:text=OUTPUT%20%3A%20Cette%20cha%C3%AEne%20surveille,mises%20%C3%A0%20jour%20depuis%20Internet)). Chaque chaîne a une politique par défaut (par exemple ACCEPT par défaut, ce qui signifie ne rien bloquer si aucune règle ne matche). On peut lister les règles courantes avec `sudo iptables -L -v -n` ([The Beginners Guide to IPTables (Includes Essential Commands!)](https://www.comparitech.com/net-admin/beginners-guide-ip-tables/#:~:text=user%40ubuntu%3A~%24%20sudo%20iptables%20,policy%20ACCEPT%29%20user%40ubuntu)). Par exemple, juste après une installation Debian, cette commande montre généralement que les politiques de INPUT/OUTPUT/FORWARD sont sur ACCEPT et qu’aucune règle explicite n’est définie (tout le trafic est autorisé par défaut) ([The Beginners Guide to IPTables (Includes Essential Commands!)](https://www.comparitech.com/net-admin/beginners-guide-ip-tables/#:~:text=user%40ubuntu%3A~%24%20sudo%20iptables%20,policy%20ACCEPT%29%20user%40ubuntu)).

**Bonnes pratiques du pare-feu** : En production, on adopte généralement une politique par défaut restrictive (tout bloquer) et on ouvre explicitement ce qui est nécessaire ([Comment configurer un pare-feu Linux : le guide ultime - NinjaOne](https://www.ninjaone.com/fr/blog/comment-configurer-un-pare-feu-linux/#:~:text=D%C3%A9finition%20de%20politiques%20par%20d%C3%A9faut)). Concrètement, cela signifie : définir les politiques par défaut à DROP (au lieu de ACCEPT) puis ajouter des règles ACCEPT pour les ports/ips/services autorisés. Par exemple, pour ne laisser que SSH et HTTP(S) accéder à la machine : 

```bash
# (Exemple) Politique par défaut restrictive
sudo iptables -P INPUT DROP    # tout entrées bloquées par défaut
sudo iptables -P FORWARD DROP  # (si routeur)
sudo iptables -P OUTPUT ACCEPT # on autorise le trafic sortant

# Autoriser loopback et trafic établi
sudo iptables -A INPUT -i lo -j ACCEPT
sudo iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Autoriser SSH (port 22) et HTTP/HTTPS (ports 80,443)
sudo iptables -A INPUT -p tcp --dport 22 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 80 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 443 -j ACCEPT
```

*(Dans cet exemple, on bloque tout par défaut sauf les connexions établies, la loopback et on ouvre SSH/Web. Adaptez les ports/services selon vos besoins.)*

Une fois les règles testées, on peut les sauvegarder pour qu’elles persistent au redémarrage. Sous Debian, on peut installer le paquet **`iptables-persistent`** ou utiliser manuellement `iptables-save > /etc/iptables/rules.v4` (et idem pour ip6tables). Au démarrage, iptables-persistent restaurera ces règles avec `iptables-restore` ([Chapitre 5. Configuration du réseau](https://www.debian.org/doc/manuals/debian-reference/ch05.fr.html#:~:text=%60iptables%60%288%29.%20Vous%20pouvez%20configurer%20vous,lors%20du%20red%C3%A9marrage%20du%20syst%C3%A8me)). 

En alternative à iptables, Debian permet aussi d’utiliser **firewalld**, un service de gestion du pare-feu dynamique (utilisé par défaut sur Red Hat/CentOS). Firewalld offre une abstraction par zones (par ex. zone *public*, *home*, *internal* avec des règles différentes) et applique les changements sans interrompre les connexions existantes. On peut installer `firewalld` (`sudo apt install firewalld`) et utiliser la commande `firewall-cmd` pour ajouter des règles. Par exemple : `firewall-cmd --zone=public --add-service=ssh --permanent` autorise SSH dans la zone public de façon permanente. **Note :** iptables et firewalld utilisent tous deux netfilter en arrière-plan, il faut donc éviter de les utiliser simultanément pour ne pas créer de conflit ([Configuration IPtables sur Debian – Oleks IT Blog](https://oleks.ca/2024/09/23/configuration-iptables-sur-debian/#:~:text=%23%20V%C3%A9rification%20d%E2%80%99autres%20pare,)). Si firewalld est utilisé, ne pas manipuler iptables directement mais passer par `firewall-cmd` ou l’outil GUI *firewall-config*. 

### Mise en place d’un proxy et d’un VPN

**Proxy :** Suivant le contexte, il peut s’agir soit de *configurer la machine Debian pour qu’elle utilise un proxy externe*, soit d’*installer un serveur proxy* sur la machine. 

- *Client proxy* : Pour indiquer à Debian d’utiliser un proxy HTTP/HTTPS pour ses accès sortants (par exemple pour `apt update`), on peut définir les variables d’environnement `http_proxy` et `https_proxy`. Ceci peut se faire globalement dans le fichier `/etc/environment` ou spécifiquement pour APT dans un fichier `/etc/apt/apt.conf.d/proxy`. Exemple pour APT : créer un fichier `/etc/apt/apt.conf.d/01proxy` contenant `Acquire::http::Proxy "http://monproxy:3128/";`. Ainsi, les mises à jour passeront par ce proxy. De même, les outils en ligne de commande comme `wget` ou `curl` respectent ces variables si elles sont exportées (`export http_proxy=http://monproxy:3128`). 

- *Serveur proxy* : Pour mettre en place un proxy local (cache web, filtrage, etc.), on peut installer un paquet dédié comme **Squid** (proxy cache web) ou **Privoxy** (proxy filtrant). Par exemple, `sudo apt install squid` puis éditer `/etc/squid/squid.conf` pour ajuster les paramètres (par défaut Squid écoute sur le port 3128). Après configuration (réseaux autorisés, taille du cache…), on redémarre le service (`systemctl restart squid`). Le proxy peut alors être utilisé par d’autres machines en pointant vers l’IP du serveur Debian sur le port 3128. N’oubliez pas d’ouvrir ce port dans le pare-feu pour les clients autorisés. 

**VPN :** Debian supporte de nombreux serveurs et clients VPN, notamment **OpenVPN** et **WireGuard** (cités ici). 

- *OpenVPN* : C’est une solution VPN éprouvée fonctionnant en espace utilisateur. Pour l’installer sur Debian : `sudo apt install openvpn easy-rsa`. On génère une PKI (certificats) via easy-rsa ou un script, puis on configure un fichier serveur (ex: `/etc/openvpn/server.conf`). Par exemple, un serveur OpenVPN basique en mode tun sur UDP 1194 comportera dans sa config des options comme `dev tun`, `port 1194`, `server 10.8.0.0 255.255.255.0` (plage d’adresses VPN), `push "redirect-gateway def1"` (pour envoyer tout le trafic client dans le VPN) et les certificats/cles (`ca.crt`, `server.crt`, `server.key`, `dh.pem`, etc.). Une fois configuré, on démarre le service avec `systemctl start openvpn@server`. Les clients utiliseront un fichier `.ovpn` contenant les infos du serveur et le certificat client. **Astuce :** assurez-vous d’activer le *forwarding IP* sur le serveur VPN si vous voulez qu’il route le trafic des clients (par ex. ajouter `net.ipv4.ip_forward=1` dans `/etc/sysctl.conf` puis `sysctl -p`). 

- *WireGuard* : WireGuard est un VPN plus récent, intégré au noyau Linux (donc très performant). Pour l’installer : `sudo apt install wireguard`. WireGuard fonctionne avec des paires de clés publiques/privées et une configuration très simple. Par exemple, créer un fichier `/etc/wireguard/wg0.conf` pour l’interface VPN wg0 : 
  ```
  [Interface]
  Address = 10.10.10.1/24
  PrivateKey = <clé privée du serveur>
  ListenPort = 51820

  [Peer]
  PublicKey = <clé publique du client>
  AllowedIPs = 10.10.10.2/32
  ```
  On peut ajouter plusieurs blocs [Peer] pour chaque client autorisé. Ensuite, on active le VPN par `wg-quick up wg0` (ou via `systemctl enable --now wg-quick@wg0` pour démarrage auto). WireGuard n’a pas de concept de serveur/cliente strictement, c’est pair-à-pair : tout **Peer** avec la bonne clé peut se connecter sur le port configuré. Veillez donc à bien restreindre `AllowedIPs` pour chaque client (plage des IP que le client peut utiliser à travers le tunnel). Comme pour OpenVPN, activer le forwarding IP si le VPN doit acheminer du trafic vers Internet, et créer des règles de pare-feu (iptables/nftables) pour masquer le trafic (SNAT/MASQUERADE) sortant du tunnel vers Internet, le cas échéant. 

## 2. Dépannage réseau

Même avec une configuration correcte, des problèmes peuvent survenir. Cette section aide à identifier et résoudre les problèmes courants de réseau sur Debian, en présentant également quelques outils de diagnostic indispensables.

### Problèmes courants et solutions

- **Interface non détectée ou inactive** : Si une interface réseau n’apparaît pas dans `ip addr`/`ip link`, il peut s’agir d’un module kernel manquant (driver non chargé). Vérifiez avec `dmesg` ou `lspci -k` si du matériel réseau est présent et si un pilote est associé. Sur Debian, il arrive qu’il faille installer un paquet de firmware (par ex. `firmware-realtek` pour certaines cartes Ethernet/Wi-Fi Realtek) – sans le firmware, l’interface peut rester absente. Si l’interface existe mais n’est pas **UP**, utilisez `sudo ip link set eth0 up` pour l’activer (ou éditez `/etc/network/interfaces` pour qu’elle soit en *auto* et redémarrez la networking, ou utilisez NetworkManager/Nmcli si approprié). 

- **Pas de connectivité IP** : Si l’interface est bien up mais que vous n’avez pas d’IP (par ex. en DHCP), vérifiez le service DHCP client. Debian utilise par défaut *isc-dhcp-client* ou *systemd-networkd* selon le cas. La commande `sudo dhclient -v eth0` peut forcer une demande DHCP et afficher les éventuelles erreurs. En IP statique, recontrôlez l’IP, le masque et la gateway configurés (`ip addr show`, `ip route` etc.). Une erreur de masque ou de gateway peut empêcher la communication hors de votre réseau local.

- **Problème de résolution de nom** : Un symptôme typique est *« host unreachable »* uniquement quand on ping un nom de domaine. Par exemple, si `ping 8.8.8.8` (IP) fonctionne mais que `ping google.com` échoue avec *unknown host*, alors la connectivité Internet est là mais c’est la résolution DNS qui pose problème ([Ping command basics for testing and troubleshooting](https://www.redhat.com/en/blog/ping-usage-basics#:~:text=You%20can%20use%20the%20,address%20in%20the%20second%20test)). Il faudra vérifier `/etc/resolv.conf` ou la configuration DNS (serveur DNS accessible ? correct ?). En attendant, utiliser l’IP directe peut dépanner. Inversement, si même le ping d’une IP publique ne répond pas, le problème est de l’ordre de la connectivité réseau (pas de route, passerelle incorrecte, ou pare-feu bloquant). 

- **Latence élevée ou pertes de paquets** : Si le réseau fonctionne mais avec des performances médiocres (ping très longs, paquets perdus), plusieurs causes sont possibles. Cela peut être externe (problème chez le fournisseur, saturation) ou interne. Coté Debian, vérifiez qu’il n’y a pas de **duplication d’IP** (conflit d’adresse sur le réseau) – l’outil `arp -a` peut aider à voir si deux équipements ont la même IP. Vérifiez aussi les paramètres de la carte : **vitesse et duplex** avec `ethtool eth0`. Une **mauvaise négociation duplex** (ex. un côté en half-duplex) cause des collisions et ralentit énormément le lien. Idéalement, assurez-vous que `Speed: 1000Mb/s` et `Duplex: Full` (ou les valeurs maximales supportées) s’affichent. Si ce n’est pas le cas, un câble défectueux ou un paramètre forcé peut être en cause. Enfin, pour la latence réseau pure (par ex. sur Internet), vous pouvez utiliser `traceroute` pour voir le chemin et identifier si un saut intermédiaire introduit du délai ou des pertes.

- **Services inaccessibles** : Si un service (ex. serveur web sur port 80) n’est pas joignable, il faut isoler le problème. Vérifiez d’abord que le service écoute bien (avec `ss -tlnp | grep 80` par exemple, ou `netstat -lntp` sur Debian ([Chapitre 5. Configuration du réseau](https://www.debian.org/doc/manuals/debian-reference/ch05.fr.html#:~:text=un%20enregistrement%20%C2%AB%C2%A0,%C2%BB))) – ceci affiche les sockets TCP d’écoute et le processus associé. Si rien n’écoute sur le port, le problème vient du service lui-même (non démarré ou mal configuré). Si le service écoute, vérifiez le pare-feu (`iptables -L -n` pour voir si une règle ne bloquerait pas le port). Enfin, assurez-vous que le service n’écoute pas seulement sur 127.0.0.1 (loopback) alors que vous essayez depuis une autre machine. Par exemple, un Nginx par défaut peut écouter sur 127.0.0.1:80, rendant le site inaccessible de l’extérieur – il faut alors le configurer pour écouter sur 0.0.0.0 (toutes interfaces) ou l’IP du serveur. 

### Outils de diagnostic réseau

Debian fournit de nombreux outils en ligne de commande pour diagnostiquer les problèmes réseau. En voici une sélection indispensable :

- **ping** : envoie des requêtes ICMP Echo pour tester la connectivité avec une cible. C’est le premier réflexe pour voir si une machine est joignable. Par exemple `ping 192.168.1.1` ou `ping google.com`. Un *ping* mesure aussi le **temps de latence** (aller-retour). Utilisez l’option `-c 4` pour limiter à 4 pings. Si le ping échoue (*destination unreachable* ou *timeout*), soit la cible est inatteignable (panne, route manquante) soit un pare-feu le bloque. Un ping réussi vers une IP publique mais pas vers un nom de domaine signale un problème DNS (comme mentionné plus haut). 

- **traceroute** : trace le chemin réseau (les routeurs) emprunté pour joindre une destination. Utile pour identifier où ça coince. Par exemple `traceroute 8.8.8.8` listera les *sauts* jusqu’à Google DNS. Chaque ligne indique un routeur intermédiaire (avec son IP ou nom) et les temps de réponse. Des `* * *` en sortie signifient soit des paquets perdus, soit que le routeur n’a pas répondu (certains filtrent les traceroutes) ([How can I perform a traceroute? - KnownHost](https://www.knownhost.com/kb/how-can-i-perform-a-traceroute/#:~:text=2%20%20%20%20,19)) ([How can I perform a traceroute? - KnownHost](https://www.knownhost.com/kb/how-can-i-perform-a-traceroute/#:~:text=Trace%20complete)). Traceroute est très utile pour voir à quel hop le réseau est rompu (par ex. on voit le dernier routeur joignable avant l’échec). Notez qu’il existe aussi **mtr** (my traceroute), combinant ping et traceroute en continu, très pratique pour diagnostiquer les pertes de paquets sur un trajet. 

- **netstat / ss** : permettent d’inspecter les connexions et ports ouverts. **`netstat -tulpen`** liste les ports TCP/UDP à l’écoute avec les processus (option -p). **`ss -tua`** fait de même (ss est un remplacement moderne de netstat). Cela sert par exemple à vérifier qu’un service écoute bien sur le bon port/adresse, ou à lister les connexions actives vers/depuis la machine. Par exemple, `ss -established` montre les connexions TCP établies. Pour un aperçu rapide des sockets d’écoute : `ss -lnt` (TCP) et `ss -lnu` (UDP). Ces commandes peuvent aider à repérer une saturation du nombre de connexions ou une écoute inattendue sur un port.

- **tcpdump** : un outil *sniffer* en ligne de commande qui capture les paquets circulant sur une interface. C’est l’équivalent en mode texte de Wireshark. Par exemple, `sudo tcpdump -i eth0 -n port 80` capture le trafic HTTP sur eth0. On peut l’affiner par protocole, IP source/dest, etc. Tcpdump permet de **voir ce qui se passe réellement sur le réseau** : par ex. si une requête DNS part et si une réponse revient, si un SYN part sur un port et pas de SYN-ACK en retour, etc. Il faut un peu connaître les protocoles pour interpréter, mais c’est extrêmement puissant pour diagnostiquer (attention, il faut être root pour capturer, et le volume peut être énorme – à filtrer ou écrire vers un fichier pcap pour analyse dans Wireshark). 

- **iftop** : outil en curse (mode texte interactif) affichant en temps réel la consommation de bande passante par connexion ([Linux interface analytics on-demand with iftop](https://www.redhat.com/en/blog/linux-interface-iftop#:~:text=Much%20like%20top%20%20and,excess%20of%20activity%20on%20the)). Il liste en colonne les flux entrants et sortants les plus actifs, avec leur débit instantané et cumulé. On l’installe avec `sudo apt install iftop`. Ensuite `sudo iftop -i eth0` pour monitorer l’interface eth0. Par défaut, iftop affiche pour chaque paire d’hôtes deux lignes : l’adresse source et destination, et en face la quantité de données transférées. La ligne suivante montre les débits moyens sur 2, 10 et 40 secondes ([How to see active connections and bandwidth usage on Linux - Linux Audit](https://linux-audit.com/networking/faq/how-to-see-active-connections-and-bandwidth-usage/)). C’est utile pour identifier qui « monopolise » la bande passante sur un serveur (par ex. une IP suspecte téléchargeant à fond, ou une machine interne consommant tout le lien). 

 ([image]()) *Figure 2 : Exemple de sortie d’`iftop` montrant les connexions actives sur l’interface (adresses source => destination) et, sur la deuxième ligne de chaque entrée, la bande passante utilisée (débit mesuré sur les dernières 2s, 10s, 40s).*

- **mtr** (my traceroute) : déjà mentionné, il combine un ping continu avec la découverte de route. En installant le paquet `mtr-tiny`, la commande `mtr google.com` va afficher la liste des routeurs successifs comme traceroute, mais en actualisant en temps réel les latences et le pourcentage de paquets perdus vers chacun. Cela permet de voir par exemple que sur 100 pings, il y a 0% de perte jusqu’au routeur 5, puis 50% à partir du routeur 6 – signe d’un problème entre le hop5 et hop6.

- **dig / nslookup** : outils pour tester la résolution DNS. Sur Debian, `dig` est fourni par le paquet *dnsutils*. Par exemple `dig example.com ANY` interroge le DNS par défaut (défini dans resolv.conf) pour tous les enregistrements du domaine. On peut spécifier un serveur DNS particulier : `dig @8.8.8.8 example.com A` forcera une requête A vers Google DNS. Ces outils aident à vérifier qu’un nom de domaine se résout correctement et obtenir des détails (par ex. plusieurs entrées A, enregistrements MX, etc.). **host** est une alternative simplifiée (ex: `host debian.org`). 

En somme, face à un problème réseau, utilisez **ping** pour la connectivité de base, **traceroute/mtr** pour localiser un point de rupture, **ss/netstat** pour vérifier les sockets locaux, **tcpdump** pour voir les paquets, et **dig/host** pour le DNS. Ces outils combinés fournissent une vision complète du problème.

## 3. Optimisation des performances réseau

Optimiser les performances réseau sur Debian peut impliquer d’ajuster certains paramètres système et réseau afin d’améliorer le débit, réduire la latence ou accroître la fiabilité sous forte charge. 

### Réglage des paramètres noyau (sysctl)

De nombreux réglages réseau sont exposés via l’interface **`/proc/sys`** et configurables de façon persistante dans **`/etc/sysctl.conf`** ou des fichiers sous **`/etc/sysctl.d`**. Voici quelques tunings courants :

- **Taille des buffers TCP** : Par défaut, Linux ajuste dynamiquement les buffers de réception/émission TCP en fonction des besoins, dans des limites définies. Pour les connexions à haut débit et haute latence (long fat networks), il peut être utile d’augmenter les limites. Par exemple, on peut ajouter dans `/etc/sysctl.conf` : 
  ``` 
  net.core.rmem_max = 26214400 
  net.core.wmem_max = 26214400 
  net.ipv4.tcp_rmem = 4096 87380 16777216 
  net.ipv4.tcp_wmem = 4096 65536 16777216 
  ``` 
  Ici on autorise des buffers TCP jusqu’à ~16 Mo. **Attention** : n’augmentez ces valeurs que si nécessaire (transferts longue distance à très haut débit), car des buffers trop grands peuvent introduire de la latence (phénomène de *bufferbloat*).

- **Algorithme de congestion TCP** : Depuis Linux 4.9+, l’algorithme **BBR** (Bottleneck Bandwidth and RTT) de Google est disponible, visant à améliorer débit et latence sur Internet par rapport à l’algorithme classique Cubic. Pour l’activer sur Debian, il suffit d’ajouter dans sysctl.conf :
  ```
  net.core.default_qdisc = fq
  net.ipv4.tcp_congestion_control = bbr
  ``` 
  puis appliquer avec `sysctl -p`. La discipline de file *fq* (Fair Queueing) combinée à BBR peut réduire le bufferbloat et maintenir de meilleurs temps de réponse sous charge élevée. Vous pouvez vérifier l’activation avec `sysctl net.ipv4.tcp_congestion_control` (BBR) et `lsmod | grep bbr` (le module tcp_bbr doit être chargé). BBR est bénéfique pour les flux longue distance saturant la bande passante, mais peut ne pas convenir à tous les scénarios, il est donc à tester selon vos usages.

- **Augmentation du backlog de connexions** : Un serveur recevant de très nombreuses connexions simultanées (par ex. un serveur web sous très forte charge) peut voir sa file d’attente de connexions en cours de handshake saturée. Le paramètre `net.core.somaxconn` définit la taille maximale de cette queue (par défaut souvent 128). On peut l’augmenter (ex: 1024) pour éviter de refuser des connexions dans ces cas extrêmes. De même, `net.core.netdev_max_backlog` peut être augmenté si l’interface réseau reçoit les paquets plus vite que le noyau ne les traite (paquets en attente dans la file d’interruption).

- **Temps d’attente des sockets** : Pour un serveur faisant face à de multiples connexions *TIME_WAIT*, on peut réduire `net.ipv4.tcp_fin_timeout` (par ex. 15 au lieu de 60 secondes) afin de libérer plus vite les ressources, et activer éventuellement `net.ipv4.tcp_tw_reuse = 1` pour réutiliser des sockets en TIME_WAIT pour de nouvelles connexions si approprié (note: *tcp_tw_reuse* n’a d’effet que pour les connexions sortantes en IPv4, et *tcp_tw_recycle* est à éviter car dangereux avec NAT).

En appliquant ces réglages avec `sysctl -p`, on peut améliorer la tenue en charge du système. **Cependant, chaque paramètre doit être testé** : une valeur trop élevée peut consommer de la mémoire ou avoir des effets de bord. Il est recommandé de modifier un paramètre à la fois et de surveiller le comportement (via `ss -s` pour les stats TCP, `sar -n DEV` pour le trafic, etc.). 

### Optimisation au niveau de la carte réseau (ethtool)

**`ethtool`** est l’outil principal pour interroger et configurer les interfaces réseau au niveau matériel. Avec `ethtool eth0`, on obtient les capacités de la carte **eth0** : vitesses supportées, mode duplex, autonegociation, taille des file d’attente, offload matériel, etc. Quelques optimisations possibles via ethtool :

- **Forcer la vitesse/duplex** : Normalement la négociation auto (autoneg) règle ça automatiquement. Mais en cas de matériel ancien ou de switch problématique, on peut explicitement fixer la vitesse. Par exemple `sudo ethtool -s eth0 speed 100 duplex full autoneg off` force eth0 en 100Mbps Full. C’est à utiliser avec précaution et en cohérence avec l’équipement en face (sinon mismatch). En général, laissez autoneg *on* pour les liaisons gigabit et plus.

- **Offloading matériel** : Les cartes récentes supportent des déchargements matériels (checksum, segmentation TCP, GRO/LRO). Ces offloads améliorent les performances en déchargeant le CPU. Vous pouvez vérifier avec `ethtool -k eth0` la liste des offloads (ex: `tcp-segmentation-offload: on`). En cas de problème spécifique (par ex. capture de paquets où on préfère désactiver GRO/LRO pour voir les paquets réels), on peut les désactiver temporairement (`sudo ethtool -K eth0 gro off lro off`). Mais pour la performance, on laissera tout *on* (par défaut) à moins d’une raison précise. 

- **Taille des buffers et IRQ coalescing** : `ethtool -g eth0` montre la taille des tampons RX/TX de la carte. Sur des débits très élevés, augmenter les buffers de la carte peut éviter de perdre des paquets lorsque le système est occupé. De même, `ethtool -c eth0` affiche les paramètres de coalescence d’interruptions (combien de paquets ou pendant combien de microsecondes la carte attend avant de déclencher une interruption CPU). Ajuster ces valeurs permet de trouver un équilibre entre latence (interruption immédiate à chaque paquet) et débit/charge CPU (regrouper plusieurs paquets par interruption). Par exemple, sur une carte 10Gb, on peut augmenter légèrement `rx-usecs` pour réduire la charge CPU à peine au détriment de quelques microsecondes de latence.

- **Wake-on-LAN, etc.** : ethtool sert aussi à configurer le Wake-on-LAN (`ethtool -s eth0 wol g` pour activer le réveil via paquet magique) si on a besoin de cette fonctionnalité.

En résumé, **ethtool** aide à diagnostiquer les problèmes de lien (erreurs, stats, etc.) et à peaufiner la config de la NIC pour de très hautes performances. Pour la plupart des serveurs, les réglages par défaut sont déjà optimisés, mais dans des scénarios spécifiques (trafic 10G intense, capture de paquets, latence ultra-faible), il vaut le coup d’affiner ces paramètres. Consultez la documentation du fabricant de la carte pour des recommandations éventuelles (certains pilotes/noyaux suggèrent d’ajuster les IRQ affinity, etc., ce qui sort du cadre de ce guide).

### Contrôle de trafic et QoS (tc)

Linux propose des mécanismes avancés de **Traffic Control** via l’outil `tc`. Cela permet de mettre en place de la **QoS (Quality of Service)**, du **shaping** (limitation de débit) ou de la **prioritisation** de certains paquets. Sur Debian, `tc` est fourni par le paquet iproute2 (installé par défaut). 

Configurer la QoS est un sujet complexe, mais voici quelques exemples d’optimisations qu’on peut réaliser :

- **Limiter le débit sortant** : Si vous hébergez un service et voulez éviter qu’il n’utilise toute la bande passante, on peut attacher une discipline de sortie. Par ex. pour limiter `eth0` à 100 Mbps en sortie, on peut utiliser un qdisc *tbf* (Token Bucket Filter) :  
  ```bash
  tc qdisc add dev eth0 root tbf rate 100mbit burst 32kbit latency 400ms
  ``` 
  Ceci crée un *goulot* à 100 Mbps. Les paramètres `burst` et `latency` ajustent la tolérance de pic et la latence max du seau de tokens. C’est une méthode simple pour s’assurer qu’un service ne sature pas l’upload, en laissant de la place pour d’autres. 

- **Priorisation** : On peut créer des classes de trafic et appliquer des priorités (par ex. passer les paquets SSH/VoIP avant ceux de téléchargement). Un exemple simplifié : 
  ```bash
  tc qdisc add dev eth0 root handle 1: htb default 10
  tc class add dev eth0 parent 1: classid 1:1 htb rate 100mbit
  tc class add dev eth0 parent 1:1 classid 1:10 htb rate 80mbit ceil 100mbit prio 2  # trafic normal
  tc class add dev eth0 parent 1:1 classid 1:20 htb rate 20mbit ceil 100mbit prio 1  # trafic prioritaire
  tc filter add dev eth0 protocol ip parent 1:0 prio 1 u32 match ip dport 22 0xffff flowid 1:20
  ``` 
  Ici on réserve 20 Mbps mini pour le trafic prioritaire (par ex. SSH, dport 22), qui peut monter jusqu’à 100 Mbps et a une priorité 1 (haute), tandis que le reste est classe 10 (priorité 2). Ainsi, en cas de saturation, les paquets SSH seront servis en priorité. Ce n’est qu’un aperçu de la puissance de `tc` – on peut faire beaucoup plus (filets FIFO, RED, SFQ, fq_codel pour réduire la latence, etc.).

- **Réduire la latence (bufferbloat)** : Sur les liaisons où la latence augmente fortement en charge (bufferbloat), l’utilisation d’un algorithme de queue moderne comme **fq_codel** ou **cake** peut aider. Par exemple remplacer le qdisc par défaut par fq_codel : `tc qdisc add dev eth0 root fq_codel`. Sur Debian Buster/Bullseye, fq_codel est souvent déjà la file par défaut (via `net.core.default_qdisc=fq_codel`). L’avantage de fq_codel est de gérer automatiquement la file d’attente pour réduire la latence en maintenant un débit élevé (en évitant que des flux lents ne subissent la latence induite par des flux volumineux).

En somme, **tc** et la QoS permettent d’adapter le comportement du réseau aux besoins (limiter tel flux, garantir de la bande passante à tel service, éviter la saturation des buffers…). La mise en place demande d’analyser son trafic et éventuellement de faire des tests. Pour aller plus loin, le *Linux Advanced Routing & Traffic Control HOWTO* est une référence incontournable ([Chapitre 5. Configuration du réseau](https://www.debian.org/doc/manuals/debian-reference/ch05.fr.html#:~:text=Consulter%20,Routing%20%26%20Traffic%20Control)).

### Amélioration du débit et tuning applicatif

Outre les réglages système, pensez aussi aux optimisations au niveau des applications réseau elles-mêmes : 

- **Multithreading** : Sur un serveur multi-cœur, utiliser des démons capables de gérer plusieurs threads ou processus en parallèle peut améliorer le débit global (par ex. `nginx` est asynchrone et multi-worker, `apache2` peut utiliser le MPM event, etc.). Cela permet d’exploiter toute la capacité CPU pour traiter du trafic réseau.

- **Encryption/décryption** : Si la charge réseau implique du chiffrement (HTTPS, VPN…), le CPU peut devenir le goulot d’étranglement. L’activation de fonctions comme **AES-NI** (instructions matérielles d’accélération AES, généralement activées par défaut si le CPU les supporte) ou l’utilisation de bibliothèques optimisées (OpenSSL avec engine, Chiffrement ChaCha20Poly1305 pour les CPU sans AES-NI, etc.) peut augmenter le débit chiffré. Sur OpenVPN par ex., utiliser `--cipher AES-256-GCM` (avec AES-NI) ou `--cipher CHACHA20-POLY1305` selon le matériel peut faire une différence significative en performance.

- **Tuning au niveau de l’application** : Parfois, il suffit d’ajuster un paramètre applicatif. Par ex., pour un serveur web ou proxy, augmenter la taille du socket listen backlog (couplé avec le somaxconn noyau) permet d’accepter plus de connexions simultanées. Pour un serveur SSH soumis à de nombreuses connexions, on peut ajuster `MaxStartups` pour tolérer plus de connexions non authentifiées simultanées (sinon SSH pourrait les dropper). Pour un serveur BIND (DNS) très sollicité, augmenter `recursive-clients` évite de rejeter des requêtes sous forte charge. Chaque service a ses knobs de tuning – consultez la documentation de l’application en question après avoir optimisé le système.

En résumé, **optimiser les performances réseau** passe par une approche globale : du noyau (sysctl) aux cartes réseau (ethtool), en passant par le contrôle de trafic (tc) et les optimisations logicielles. Il convient de cibler les optimisations en fonction du problème à résoudre (débit insuffisant, latence élevée, surcharge CPU, etc.) et de toujours tester l’impact d’un changement dans un environnement de préproduction si possible.

## 4. Sécurité et bonnes pratiques réseau

Sécuriser le réseau d’un système Debian est crucial pour protéger le serveur et les données. Cette section aborde les bonnes pratiques de configuration du pare-feu, la sécurisation des services réseau courants et la surveillance du trafic et des logs pour détecter d’éventuels incidents.

### Configuration des règles de pare-feu

Comme déjà évoqué, une règle de base est d’adopter une **politique par défaut restrictive** : *« deny by default, allow by exception »*. Sur un serveur Debian, cela signifie configurer iptables de sorte à **tout bloquer en entrée par défaut**, puis ajouter des règles pour les ports/services nécessaires (SSH, web, etc.) ([Comment configurer un pare-feu Linux : le guide ultime - NinjaOne](https://www.ninjaone.com/fr/blog/comment-configurer-un-pare-feu-linux/#:~:text=Pour%20une%20s%C3%A9curit%C3%A9%20optimale%20de,abandonnent%20silencieusement%20les%20paquets%20de)). 

Veillez à **inclure des règles pour le trafic établi** afin de ne pas perturber les connexions en cours (ex. la règle iptables `-m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT` comme montrée plus haut). Sans cela, si vous bloquez tout par défaut, même les réponses aux connexions légitimes seraient bloquées. 

Une bonne pratique est aussi de **logguer** certaines paquets rejetés pour enquête. Par exemple, ajouter en dernière règle avant le drop : `iptables -A INPUT -m limit --limit 5/min -j LOG --log-prefix "iptables DROP: " --log-level 7`. Ceci journalise (au maximum 5 par minute pour éviter le spam) les paquets qui vont être bloqués, avec un préfixe identifiable dans syslog. Ces logs permettront de voir si un service légitime était bloqué par erreur ou si des ports sont scannés en permanence, etc. N’abusez pas du log (une rafale de logs peut elle-même saturer le système), mais cibler quelques types de paquets critiques (paquets inconnus, nouveaux, etc.). 

Si vous utilisez **IPv6**, n’oubliez pas de configurer ip6tables de manière équivalente à iptables pour IPv4. Debian traite IPv4 et IPv6 séparément en termes de pare-feu. Vous pouvez avoir tout sécurisé en v4, mais si v6 est activé et non filtré, la machine reste ouverte via son adresse IPv6. Si vous n’utilisez pas IPv6, vous pouvez dans un premier temps le désactiver (sysctl `disable_ipv6=1` sur les interfaces) ou bloquer tout v6 en entrée par précaution.

Pour faciliter la gestion, surtout sur des serveurs simples, Debian propose aussi **UFW (Uncomplicated Firewall)** disponible dans les dépôts. UFW est un frontend simplifié pour iptables. On l’installe (`apt install ufw`), puis on définit des règles du genre `ufw allow 22/tcp`, `ufw allow 80/tcp` etc., et `ufw enable` pour appliquer. UFW se charge de créer les règles iptables correspondantes. Il est pratique pour une configuration basique (bien qu’il ajoute une légère abstraction en plus). Firewalld (mentionné plus haut) est une autre option pour ceux qui préfèrent la gestion par zone.

En production, pensez à tester vos règles *hors production* ou à planifier une fenêtre de maintenance, car une erreur de règle peut vous verrouiller hors du serveur (ex: si on bloque par mégarde SSH). Un bon réflexe est d’utiliser des commandes *à délai* pour appliquer les règles critiques : par exemple, sous `bash`, exécutez `sleep 60 && ufw disable` dans un autre terminal avant d’activer des règles drastiques – si vous vous coupez l’accès, au bout de 60s le pare-feu sera désactivé, vous rendant la main. Si tout va bien, vous annulez la commande programmée. Ce genre d’astuce évite bien des sueurs froides.

### Sécurisation des services réseau (SSH, DNS, VPN, etc.)

Chaque service réseau ouvert sur un serveur doit être sécurisé individuellement, en plus du pare-feu. Voici quelques recommandations pour les services les plus courants :

- **SSH** (Secure Shell) : C’est la porte d’entrée classique d’un serveur. Première mesure : utiliser l’**authentification par clés** au lieu des mots de passe, et *désactiver* l’authentification par mot de passe dans `/etc/ssh/sshd_config` (`PasswordAuthentication no`) ([Do I need fail2ban?? : r/debian - Reddit](https://www.reddit.com/r/debian/comments/14kssxo/do_i_need_fail2ban/#:~:text=Do%20I%20need%20fail2ban%3F%3F%20%3A,be%20a%20bit%20noisy)). De plus, **désactiver le login root direct** (`PermitRootLogin no`) force les attaquants à d’abord compromettre un compte non privilégié, ajoutant une couche de sécurité. Utilisez un compte utilisateur normal + `sudo` pour l’administration. Assurez-vous évidemment de tester la connexion par clé avec un autre terminal avant de couper l’accès mot de passe pour ne pas vous enfermer dehors. Il est aussi conseillé de changer le port SSH (par ex. 2222 au lieu de 22) – cela n’ajoute qu’une **sécurité par obscurité** modeste (des scans trouveront éventuellement le port), mais réduit fortement le bruit des bots automatisés sur le port 22 ([Fail2ban sous Debian12 - debian-fr.org](https://www.debian-fr.org/t/fail2ban-sous-debian12/88569#:~:text=Fail2ban%20sous%20Debian12%20,port%20d%27%C3%A9coute%20ssh%2C%20la)). Enfin, vous pouvez restreindre l’accès SSH par adresse IP source (iptables ou dans sshd_config `AllowUsers user@ip`), ou utiliser des solutions d’authentification multi-facteur pour SSH si nécessaire.

- **Serveur Web (Apache/Nginx)** : Assurez-vous de maintenir les logiciels à jour (les mises à jour de sécurité Debian comblent les failles connues). Désactivez les modules/protocoles inutiles (par ex. désactiver SSLv3, TLS1.0 sur Apache pour n’accepter que TLS modernes afin d’éviter les failles anciennes comme POODLE). Sur Apache, surveillez les fichiers `.htaccess` si utilisés, et sur Nginx, pensez à utiliser `limit_req_zone` ou équivalent pour mitiger les attaques de type DOS applicatives (limitation du nombre de requêtes par IP). Activez les pare-feux applicatifs (Web Application Firewall) si vous avez des applications web (ModSecurity sur Apache, ou des services externalisés). 

- **Base de données (MySQL/PostgreSQL)** : Si le SGBD n’est utilisé qu’en local, écoutez uniquement sur `localhost` (dans `mysqld.cnf` mettre `bind-address = 127.0.0.1`). Si vous devez autoriser l’accès distant, faites-le uniquement depuis des IP de confiance (pare-feu ou config du SGBD pour n’accepter que certaines IP). Mettez des mots de passe forts pour les utilisateurs DB, et supprimez les comptes anonymes par défaut. 

- **DNS (Bind/Unbound)** : Un serveur DNS public doit être configuré en cache récursif **ou** en faisant autorité, mais pas les deux sur la même instance pour éviter les attaques de type *cache poisoning*. Si vous faites tourner *Bind9* par exemple, désactivez la récursion si c’est un serveur faisant autorité publique (`recursion no;` dans `named.conf.options`) ([Chapitre 5. Configuration du réseau](https://www.debian.org/doc/manuals/debian-reference/ch05.fr.html#:~:text=Pour%20un%20syst%C3%A8me%20avec%20une,plut%C3%B4t%20que%20le%20simple%20nom_hote)), et autorisez la récursion seulement pour vos IP internes si c’est un cache interne (`allow-recursion { <vos réseaux>; };`). Évitez d’être un *open resolver* accessible à tous, car il pourrait être abusé pour des attaques DDoS par amplification. Pensez aussi à appliquer DNSSEC si vous gérez des domaines (Bind peut signer les zones, et en cache il peut valider DNSSEC). 

- **VPN (OpenVPN/WireGuard)** : Pour OpenVPN, utilisez les chiffrement et authentifications robustes (tls-version-min 1.2, certificats 2048 bits minimum ou ed25519, etc.). Révoquez les certificats clients non utilisés. Sur WireGuard, les clés étant pré-partagées, tenez-les secrètes et mettez en place éventuellement une surveillance des IP connectées. Limitez les ports ouverts aux seuls nécessaires (1194/UDP pour OpenVPN, 51820/UDP pour WG, etc.). Un VPN expose potentiellement le réseau interne, il faut donc veiller à l’isoler en segmentant le réseau (par ex. les clients VPN arrivent dans un sous-réseau à part et des règles supplémentaires contrôlent ce à quoi ils accèdent). 

- **Autres services** : Pour tout service, cherchez les guides de *hardening*. Par exemple, pour SSH on a vu les grands points. Pour un serveur mail (Postfix/Dovecot) il y a d’autres considérations (relayer ou non, anti-spam, authentification chiffrée obligatoire, etc.). Un serveur FTP ? Mieux vaut le remplacer par SFTP via SSH si possible pour éviter la transmission en clair. En somme, évaluez chaque port ouvert avec : *« Ce service est-il correctement configuré et nécessaire ? »*. Si la réponse est non, fermez-le jusqu’à en avoir besoin.

- **Mises à jour de sécurité** : Ce n’est pas spécifique réseau, mais **garder le système à jour** est l’une des meilleures pratiques de sécurité. Debian propose des mises à jour de sécurité régulières (sur les packages *stable*). Pensez à les appliquer (éventuellement via unattended-upgrades pour les patchs de sécu automatiques). Les failles réseau (OpenSSL, OpenSSH, etc.) sont souvent critiques, et Debian les corrige rapidement une fois divulguées. 

### Surveillance et logs réseau

Mettre en place une bonne surveillance permet de détecter proactivement les incidents ou tentatives d’intrusion. Voici quelques outils et pratiques pour monitorer le réseau et conserver des traces :

- **Logs du système et des services** : Sur Debian avec *systemd*, la commande `journalctl` permet d’accéder au journal centralisé. Par exemple `journalctl -u ssh` affichera les logs du service SSH (sshd). Utilisez `journalctl -f` pour suivre les logs en temps réel (toute nouvelle entrée s’affiche, un équivalent de `tail -f` sur les logs traditionnels). Il est conseillé de rendre le journal *persistant* (par défaut sur Debian, le journal systemd peut être volatil en RAM). Pour cela, éditez `/etc/systemd/journald.conf` et assurez `Storage=persistent` ([How do view older journalctl logs (after a rotation maybe?)](https://serverfault.com/questions/809093/how-do-view-older-journalctl-logs-after-a-rotation-maybe#:~:text=How%20do%20view%20older%20journalctl,line%20from%20auto%20to%20persistent)), puis redémarrez journald. Ainsi, les logs seront conservés dans /var/log/journal même après reboot. En parallèle, Debian installe encore souvent **rsyslog** qui enregistre dans les fichiers texte sous /var/log (auth.log, syslog, daemon.log, etc.). Vérifiez que vos services logguent quelque part et que la rotation des logs est configurée (via `logrotate`). Par défaut, /var/log/auth.log contient les connexions SSH (succès/échecs), /var/log/syslog a un peu de tout (dépend de la config). **Surveillez ces fichiers** régulièrement ou via des outils pour détecter des anomalies (beaucoup d’échecs SSH, etc.). 

- **fail2ban** : C’est un outil incontournable pour la sécurité. Fail2ban surveille les logs (ex: auth.log pour SSH) et crée dynamiquement des règles de pare-feu pour bannir les IP ayant un comportement suspect (par ex. 5 mots de passe incorrects en 10 minutes) ([Install and Configure Fail2Ban for SSH on Debian - G RBE](https://gorbe.io/posts/fail2ban/install/#:~:text=Install%20and%20Configure%20Fail2Ban%20for,force%20attacks)). Sur Debian, `apt install fail2ban` puis activez le service. Par défaut, une *jail* SSH est activée (voir `/etc/fail2ban/jail.conf` ou `/etc/fail2ban/jail.d/debian.conf`). Vous pouvez ajuster les paramètres : nombre d’échecs (maxretry), durée du bannissement (bantime), etc., et créer des jails pour d’autres services (web, FTP…) en se basant sur des filtres fournis ou personnalisés. Fail2ban utilise iptables pour bannir (il ajoute des règles DROP sur les IP malveillantes) ([Fail2ban Configuration for Secure Servers: One Step at a Time](https://www.plesk.com/blog/various/using-fail2ban-to-secure-your-server/#:~:text=When%20Fail2ban%20identifies%20and%20locates,via%20email%20as%20they%20occur)). Il peut envoyer des emails lors des bans si configuré. C’est un outil léger qui *mitige* les attaques par force brute. Cependant, ne comptez pas uniquement sur lui : il ne remplace pas des mesures de fond (comme l’authentification par clé, qui élimine justement l’intérêt des attaques par mot de passe). 

- **Surveillance réseau en temps réel** : Pour superviser le trafic et la disponibilité, il peut être utile d’utiliser des outils dédiés ou des systèmes de monitoring. Par exemple, mettre en place **Munin**, **Cacti** ou **Prometheus/Grafana** pour grapher l’usage du réseau (octets/s, paquets erronés, etc.) et envoyer des alertes. Ou utiliser un service d’astreinte (Pingdom, UptimeRobot, etc.) qui va pinger/monitorer depuis l’extérieur l’accessibilité de vos services. Debian elle-même n’intègre pas ce genre d’outil par défaut, mais ils sont simples à ajouter. 

- **Intrusion Detection System (IDS)** : Pour aller plus loin, vous pouvez déployer un IDS/IPS comme **Snort**, **Suricata** ou **OSSEC**. Ces outils inspectent le trafic réseau (ou les logs système) à la recherche de signatures d’attaques connues ou de comportements suspects. Par exemple, Snort en mode IDS sur votre interface réseau peut alerter en cas de portscan, tentative d’exploit, etc. OSSEC peut analyser les logs et vous alerter en cas de message de log correspondant à une intrusion. Ce sont des solutions plus complexes à configurer (il faut tuner les règles pour éviter les faux positifs) mais pour une infrastructure critique elles apportent une couche de sécurité supplémentaire.

- **Audit de configuration** : Pensez à utiliser des outils comme **Lynis** (disponible via apt) qui audite la configuration de la machine et donne des recommandations de sécurité. Il va vérifier la configuration réseau, les permissions, les bannières, etc., et signaler ce qui peut être amélioré. C’est un bon complément pour ne pas rater un réglage important.

En termes de logs, il est utile d’**centraliser** les journaux si vous gérez plusieurs serveurs (via syslog remote, ou avec une pile ELK – Elasticsearch/Logstash/Kibana – ou Grafana Loki, etc.). Cela permet de corréler des événements sur plusieurs machines et d’avoir une vue d’ensemble. 

Pour **résumer la sécurité réseau sur Debian** : fermez toutes les portes inutiles (pare-feu strict), sécurisez celles qui restent ouvertes (configurer et mettre à jour les services, utiliser des méthodes d’authentification robustes), et *surveillez* en permanence (logs, monitoring) afin de réagir vite en cas de tentative d’intrusion ou de comportement anormal. Avec ces bonnes pratiques, vous réduirez fortement les risques et serez en mesure de détecter proactivement les problèmes.

## 5. Démonstrations et exemples concrets

Dans cette dernière section, nous illustrons certaines opérations de maintenance réseau sous Debian avec des cas pratiques, commandes et scripts Bash. Ces exemples se basent sur des situations réelles que l’on peut rencontrer en administration système.

- **Exemple 1 : Redémarrage automatique d’une interface en cas de perte de lien** – Imaginons un serveur ayant une interface qui perd parfois sa connexion (problème de câble ou switch). On souhaite que Debian détecte la perte de lien et tente de redémarrer l’interface. On peut utiliser les scripts *ifupdown* et *mii-tool*. Par exemple, créer un script `/usr/local/bin/check_eth0.sh` :

  ```bash
  #!/bin/bash
  if ! /sbin/mii-tool eth0 | grep -q 'link ok'; then
      echo "$(date): link down, restarting eth0" >> /var/log/eth_monitor.log
      ifdown eth0 && ifup eth0
  fi
  ``` 

  Ce script utilise `mii-tool` (ou `ethtool` équivalent) pour vérifier l’état de lien. S’il ne voit pas "link ok", il log l’événement puis redémarre l’interface. Il faudrait l’ajouter dans la crontab root pour exécution périodique (ex: toutes les minutes). C’est une solution de contournement simple pour un problème matériel.

- **Exemple 2 : Script de détection de latence élevée** – Supposons que vous voulez surveiller la latence vers une IP critique (ex: la gateway). Vous pouvez écrire un petit script Bash qui ping la gateway et log si le temps dépasse un seuil :

  ```bash
  #!/bin/bash
  GATEWAY=192.168.1.1
  MAX_LAT=100  # ms
  ping -c 4 -q $GATEWAY > /tmp/pingtest.txt
  RTT=$(grep 'min/avg' /tmp/pingtest.txt | awk -F '/' '{print $6}')
  if [ "${RTT%.*}" -gt "$MAX_LAT" ]; then
      echo "$(date): Latence élevée $RTT ms vers $GATEWAY" >> /var/log/latence.log
  fi
  ```

  Ce script envoie 4 ping, extrait la latence moyenne et si elle dépasse 100ms, il enregistre un message. On peut le lancer via cron également. C’est rudimentaire mais ça peut aider à détecter des montées de latence (par ex. si latence.log se remplit, il y a peut-être saturation ou problème réseau à ce moment-là).

- **Exemple 3 : Ajout dynamique d’une route en VPN** – Vous avez un VPN qui ne doit être utilisé que pour certaines routes (split tunneling). Par exemple, vous voulez qu’en se connectant au VPN, une route vers 10.0.0.0/8 passe par le VPN. Si vous utilisez *openvpn*, dans la config client vous pouvez ajouter `route 10.0.0.0 255.0.0.0`. Mais on peut aussi le faire côté client Debian avec un script *up* d’openvpn ou via `/etc/network/if-up.d/`. Par exemple, créez `/etc/network/if-up.d/vpn-routes` :

  ```bash
  #!/bin/sh
  [ "$IFACE" = "tun0" ] || exit 0
  ip route add 10.0.0.0/8 via 10.8.0.1
  ``` 

  Rendez-le exécutable. Ainsi, à chaque activation de l’interface tun0 (supposée être le VPN), la route est ajoutée. De même un script *if-down.d* pourrait la supprimer. Debian exécute ces scripts automatiquement pour les interfaces gérées par ifupdown.

- **Exemple 4 : Bloquer automatiquement une IP scannant des ports** – On peut utiliser *iptables* avec un module *recent* ou *hashlimit* pour détecter un scan de ports. Par exemple, insérer une règle qui si plus de X ports touchés en Y secondes, ajoute l’IP dans une liste et la bloque. Une des façons :

  ```bash
  # Table raw: mark connection attempts
  iptables -t raw -A PREROUTING -p tcp -m tcp --syn -m hashlimit \
    --hashlimit-name portscan --hashlimit-above 20/minute --hashlimit-mode dstport \
    --hashlimit-srcmask 32 -j DROP
  ```

  Ici, si plus de 20 ports distincts sont ciblés en une minute depuis la même IP, on drop (on pourrait au lieu de drop, ajouter à une liste recent puis drop dans filter). C’est un peu technique et peut générer des faux positifs, mais ça montre comment iptables peut être scripté pour réagir à des motifs d’attaque simples. Pour une solution plus robuste, on utiliserait plutôt **fail2ban** sur les logs du port sentry (par ex. en combinaison avec *portreserve* ou un honeypot).

- **Exemple 5 : Analyse simple des logs de connexion** – Imaginons que vous voulez un rapport quotidien des IP ayant tenté de se connecter en SSH. On peut ajouter dans `/etc/cron.daily/` un script :

  ```bash
  #!/bin/bash
  zgrep "Failed password" /var/log/auth.log* | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr > /tmp/ssh_failures.txt
  mail -s "Rapport tentatives SSH - $(hostname)" admin@mondomaine.com < /tmp/ssh_failures.txt
  ```

  Ce script va parcourir auth.log (y compris les archives .gz via zgrep) à la recherche de "Failed password", extraire l’IP source, faire un comptage (`uniq -c`) puis envoyer le rapport par email (en supposant que le mail local est configuré pour expédier à root -> votre adresse). Ainsi chaque jour vous recevez la liste des IP qui ont échoué à se connecter, avec le nombre de tentatives. Vous pourriez croiser ça avec les bannissements fail2ban, etc. C’est un exemple de *surveillance artisanale* par les logs. On pourrait faire de même pour d’autres services.

Ces quelques exemples montrent comment automatiser certaines tâches de maintenance et de supervision réseau. Bien sûr, chaque infrastructure a ses besoins, et il existe souvent des outils plus spécialisés pour chaque problème (par ex. utiliser Grafana au lieu d’un script ping maison, ou OSSEC au lieu d’un script de parsing de logs). L’important est de comprendre la logique et de savoir qu’avec Debian/Linux, on a la flexibilité de **scripter quasiment n’importe quel comportement** afin de maintenir le système réseau robuste et sécurisé.

---

En suivant ce guide, un administrateur devrait être en mesure de configurer finement le réseau d’une Debian, de diagnostiquer les pannes courantes, d’optimiser les performances selon ses besoins et de mettre en place les protections adéquates pour une exploitation en production sereine. N’oubliez pas que la documentation officielle Debian (le *Debian Handbook*, le wiki, les pages de manuel ([NetworkConfiguration - Debian Wiki](https://wiki.debian.org/NetworkConfiguration#:~:text=See%20)), etc.) est une ressource précieuse à consulter en complément, de même que les forums et communautés Debian en cas de doute ou de problème non résolu. Bon administration ! 

