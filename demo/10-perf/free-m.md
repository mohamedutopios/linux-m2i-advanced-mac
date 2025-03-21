La commande `free -m` affiche un résumé de l'utilisation de la mémoire en mégaoctets. Voici une explication détaillée de la sortie que vous avez obtenue :

```
               total        used        free      shared  buff/cache   available
Mem:             457          95          35           0         338         362
Swap:            511           2         509
```

### Pour la RAM (ligne "Mem:") :

- **total (457 Mo)** :  
  C'est la quantité totale de mémoire physique (RAM) disponible sur votre machine, ici 457 Mo.

- **used (95 Mo)** :  
  C'est la quantité de mémoire qui est actuellement utilisée par les processus et le système. Ici, 95 Mo sont occupés.

- **free (35 Mo)** :  
  C'est la quantité de mémoire qui est totalement libre, c'est-à-dire qui n'est utilisée par aucun processus ni par des caches. Ici, seulement 35 Mo sont libres.

- **shared (0 Mo)** :  
  C'est la quantité de mémoire partagée entre plusieurs processus. Dans ce cas, la valeur est 0 Mo.

- **buff/cache (338 Mo)** :  
  C'est la mémoire utilisée par le système pour les buffers et caches. Cette mémoire améliore les performances en stockant temporairement des données fréquemment utilisées. Si nécessaire, le noyau peut libérer rapidement cette mémoire pour d'autres usages. Ici, 338 Mo sont utilisés pour les caches et buffers.

- **available (362 Mo)** :  
  C'est une estimation de la mémoire disponible pour démarrer de nouveaux processus sans recourir au swap. Cette valeur tient compte de la mémoire libre et de la mémoire que le système peut libérer (comme le cache). Ici, environ 362 Mo sont disponibles.

### Pour le swap (ligne "Swap:") :

- **total (511 Mo)** :  
  C'est la taille totale de l'espace swap configuré sur le système, ici 511 Mo.

- **used (2 Mo)** :  
  C'est la quantité de swap actuellement utilisée. Dans votre cas, seulement 2 Mo de swap sont occupés, ce qui indique que, malgré la forte sollicitation de la RAM, le système a pu satisfaire la demande avec la mémoire physique (et des caches).

- **free (509 Mo)** :  
  C'est la quantité de swap libre, ici 509 Mo.

### Interprétation dans le contexte du stress :

- **Pendant le test stress-ng :**  
  La commande `stress-ng --vm 2 --vm-bytes 95% --timeout 60s` a forcé la consommation de 95 % de la RAM par 2 processus pendant 60 secondes. Cependant, après le test, on voit que la RAM utilisée n'est que de 95 Mo sur 457 Mo, avec 338 Mo utilisés pour le cache.  
- **Faible utilisation du swap :**  
  Seuls 2 Mo de swap sont utilisés, ce qui signifie que le système n'a pas eu besoin d'utiliser le swap de manière intensive. Le noyau a pu libérer la mémoire cache si nécessaire, et la mémoire "available" (362 Mo) reste élevée, indiquant que le système peut encore répondre à de nouvelles demandes de mémoire sans avoir recours au swap.

### Conclusion

La sortie de `free -m` montre que, même sous stress, votre système parvient à gérer la mémoire efficacement en utilisant des caches et en gardant la majeure partie du swap inutilisé. Cela indique une bonne gestion de la mémoire par le noyau, qui préfère utiliser la RAM et libérer le cache plutôt que d'utiliser le swap, surtout si le paramètre `vm.swappiness` est réglé à une valeur faible (ce qui privilégie l'utilisation de la RAM).