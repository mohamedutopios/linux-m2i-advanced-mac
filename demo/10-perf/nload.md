Voici une explication de la sortie de nload pour l'interface eth0 :

---

**Device eth0 [10.0.2.15] (1/1):**  
- Cela indique que nload surveille l'interface réseau nommée **eth0** et affiche son adresse IP (ici, **10.0.2.15**).  
- Le "(1/1)" signifie qu'il y a une seule interface surveillée sur le système, et c'est la première (et seule) de la liste.

---

### Incoming (Trafic entrant) :

- **Curr (Courant) : 944.00 Bit/s**  
  Indique le débit instantané actuel des données entrantes (en bits par seconde). Ici, environ 944 bits par seconde arrivent sur eth0.

- **Avg (Moyen) : 1.77 kBit/s**  
  C'est la moyenne du débit entrant sur une période donnée.

- **Min (Minimum) : 928.00 Bit/s**  
  Le débit minimal enregistré pendant la période de surveillance.

- **Max (Maximum) : 4.12 kBit/s**  
  Le débit maximal observé durant la période.

- **Ttl (Total) : 460.08 kByte**  
  La quantité totale de données reçues (en kilo-octets) depuis le début de la surveillance.

---

### Outgoing (Trafic sortant) :

- **Curr : 1.82 kBit/s**  
  Le débit instantané actuel des données sortantes est d'environ 1.82 kBit/s.

- **Avg : 2.38 kBit/s**  
  La moyenne du débit sortant sur la période de surveillance.

- **Min : 1.67 kBit/s**  
  Le débit minimal observé pour les données sortantes.

- **Max : 5.05 kBit/s**  
  Le débit maximal des données sortantes observé durant la période.

- **Ttl : 439.19 kByte**  
  La quantité totale de données envoyées (en kilo-octets) depuis le début de la surveillance.

---

### En résumé

- **nload** affiche en temps réel le trafic sur l'interface **eth0**.
- Vous voyez le débit instantané (Curr), ainsi que des statistiques moyennes, minimales et maximales pour le trafic entrant et sortant.
- La valeur **Ttl** indique le volume total de données transférées pendant la session de surveillance.

Cela permet de suivre l'utilisation de la bande passante et de diagnostiquer la charge réseau sur l'interface.