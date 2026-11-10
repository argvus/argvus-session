---
title: Session TTY
description: Démarrez ARGVUS manuellement depuis un terminal virtuel.
---
Après s'être connecté sur un TTY, démarrez la session avec :

```sh
argvus --start-desktop
```
Ceci est le point d'entrée manuel pris en charge depuis `argvus session`. Il utilise le même `argvus start` et le cycle de vie du service utilisateur qu'une connexion graphique.

Pour inspecter ou redémarrer la session résultante, utilisez `argvus sessionctl status`, `argvus sessionctl reload` ou `argvus sessionctl logs`.

## Migration depuis `exec argvus-tty`

Les versions précédentes ont installé `argvus-tty` dans `/usr/bin`, et certains utilisateurs ont démarré la session depuis `~/.profile` avec `exec argvus-tty`. Ce fichier est désormais privé et n'est plus sur `PATH`, donc la ligne échoue après la mise à jour. Remplacez-le par le point d'entrée pris en charge :

```sh
exec argvus --start-desktop
```
`argvus tty` est le même point d'entrée. Supprimez ou mettez à jour la ligne dans `~/.profile`, `~/.zprofile` ou `~/.bash_profile` avant la prochaine connexion sur un TTY.
