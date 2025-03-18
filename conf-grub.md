Le fichier de configuration de GRUB, notamment celui généré automatiquement (généralement **/boot/grub/grub.cfg**) ainsi que le fichier de configuration par défaut (**/etc/default/grub**), contient plusieurs éléments clés qui définissent le comportement du chargeur de démarrage. Voici les éléments importants :

- **GRUB_DEFAULT**  
  Définit l'entrée de menu par défaut qui sera sélectionnée lors du démarrage.

- **GRUB_TIMEOUT**  
  Spécifie le temps (en secondes) pendant lequel le menu GRUB reste visible avant de démarrer automatiquement l'entrée par défaut.

- **GRUB_DISTRIBUTOR**  
  Permet de définir le nom ou l'identifiant de la distribution, utilisé pour nommer certaines entrées ou pour afficher des informations dans le menu.

- **GRUB_CMDLINE_LINUX**  
  Contient la liste des paramètres à passer au noyau lors du démarrage. Par exemple, on peut y ajouter des options pour la gestion de la mémoire ou des pilotes spécifiques.

- **GRUB_DISABLE_RECOVERY**  
  Option permettant de désactiver ou d'activer la génération des entrées de récupération (recovery mode).

- **GRUB_GFXMODE / GRUB_GFXPAYLOAD_LINUX**  
  Ces options définissent la résolution graphique et le mode d’affichage utilisé par GRUB pour afficher le menu de démarrage.

- **Thèmes et personnalisation**  
  Des options telles que **GRUB_THEME** permettent de spécifier un thème graphique personnalisé pour le menu de démarrage.

Il est important de noter que **/boot/grub/grub.cfg** est généralement généré automatiquement (via des scripts présents dans **/etc/grub.d/** et le fichier **/etc/default/grub**), et il est déconseillé de le modifier directement. Les modifications doivent être apportées dans les fichiers de configuration source, puis le fichier **grub.cfg** est régénéré en utilisant une commande comme `update-grub` ou `grub-mkconfig`.