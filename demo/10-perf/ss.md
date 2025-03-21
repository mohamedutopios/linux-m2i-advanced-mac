La commande `ss -tuln` affiche les sockets (connexions réseau) ouvertes sur la machine, en filtrant par type (TCP, UDP) et en ne résolvant pas les noms (d'où l'option `-n`). Voici une explication ligne par ligne :

---

**Sortie complète :**

```
Netid  State   Recv-Q   Send-Q     Local Address:Port     Peer Address:Port  Process  
udp    UNCONN  0        0              127.0.0.1:323           0.0.0.0:*  
udp    UNCONN  0        0                0.0.0.0:68            0.0.0.0:*  
udp    UNCONN  0        0                  [::1]:323              [::]:*  
tcp    LISTEN  0        128              0.0.0.0:22            0.0.0.0:*  
tcp    LISTEN  0        511              0.0.0.0:80            0.0.0.0:*  
tcp    LISTEN  0        128                 [::]:22               [::]:*  
tcp    LISTEN  0        511                 [::]:80               [::]:*  
tcp    LISTEN  0        4096                   *:5201                *:*  
```

---

### Explication détaillée :

- **Netid** : Le type de protocole ou de socket (udp ou tcp).

- **State** : L'état de la socket.  
  - `LISTEN` signifie que la socket attend des connexions entrantes (pour TCP).  
  - `UNCONN` indique une socket UDP non connectée (les UDP n’établissent pas de connexion formelle comme TCP).

- **Recv-Q / Send-Q** : La quantité de données en attente dans la file de réception ou d'envoi.

- **Local Address:Port** : L'adresse locale et le port sur lesquels la socket écoute.  
  Par exemple, `0.0.0.0:80` signifie que le service écoute sur toutes les interfaces IPv4 sur le port 80.

- **Peer Address:Port** : L'adresse et le port du pair connecté. Pour les sockets en écoute ou non connectées, on affiche souvent `*` (indiquant aucune connexion établie ou une écoute générale).

- **Process** : (Non affiché ici) La colonne peut indiquer l'ID et le nom du processus associé à la socket, si cette information est disponible et si on a lancé la commande avec les droits suffisants.

---

### Lignes par ligne :

1. **`udp    UNCONN  0        0              127.0.0.1:323           0.0.0.0:*`**  
   - **Protocole :** UDP  
   - **État :** UNCONN (pas de connexion établie)  
   - **Local :** La socket écoute sur l'adresse de loopback 127.0.0.1 au port 323 (souvent utilisé par le service NTP via ntpd ou systemd-timesyncd)  
   - **Peer :** Aucun pair spécifique (`0.0.0.0:*`)

2. **`udp    UNCONN  0        0                0.0.0.0:68            0.0.0.0:*`**  
   - **Local :** Écoute sur toutes les interfaces IPv4 sur le port 68  
   - **Utilisation :** Port 68 est typiquement utilisé par le client DHCP pour recevoir des adresses IP.

3. **`udp    UNCONN  0        0                  [::1]:323              [::]:*`**  
   - **Protocole :** UDP sur IPv6  
   - **Local :** Écoute sur l'interface de loopback IPv6 ([::1]) au port 323.

4. **`tcp    LISTEN  0        128              0.0.0.0:22            0.0.0.0:*`**  
   - **Protocole :** TCP  
   - **État :** LISTEN  
   - **Local :** Le service SSH écoute sur le port 22 sur toutes les interfaces IPv4 (0.0.0.0:22).

5. **`tcp    LISTEN  0        511              0.0.0.0:80            0.0.0.0:*`**  
   - **Local :** Le service web (par exemple nginx ou Apache) écoute sur le port 80 sur toutes les interfaces IPv4.

6. **`tcp    LISTEN  0        128                 [::]:22               [::]:*`**  
   - **Local :** Le service SSH écoute également sur IPv6 (toutes les interfaces IPv6 sur le port 22).

7. **`tcp    LISTEN  0        511                 [::]:80               [::]:*`**  
   - **Local :** Le service web écoute sur le port 80 pour les connexions IPv6.

8. **`tcp    LISTEN  0        4096                   *:5201                *:*`**  
   - **Local :** Le service iperf3 (ou autre service) écoute sur le port 5201 sur toutes les interfaces (IPv4 et IPv6 si applicable).  
   - Cette socket est utilisée par iperf3 pour les tests de débit réseau.

---

### Conclusion

La commande `ss -tuln` vous donne une vue d'ensemble des ports sur lesquels des services écoutent, à la fois pour IPv4 et IPv6, ainsi que des sockets UDP.  
Chaque ligne vous informe sur l'interface locale, le port, l'état de la socket et, éventuellement, sur le processus associé (si vous utilisez une option pour l'afficher).

Cette commande est très utile pour diagnostiquer quels services sont en écoute et s'assurer que vos configurations réseau (comme les règles NAT ou de pare-feu) permettent bien aux services de communiquer comme prévu.