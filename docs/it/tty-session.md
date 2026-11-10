---
title: sessione TTY
description: Avvia ARGVUS manualmente da un terminale virtuale.
---
Dopo aver effettuato il login su un TTY, avvia la sessione con:

```sh
argvus --start-desktop
```
Questo è il punto di accesso manuale supportato da `argvus session`. Utilizza lo stesso ciclo di vita `argvus start` e del servizio utente di un login grafico.

Per ispezionare o riavviare la sessione risultante, usa `argvus sessionctl status`, `argvus sessionctl reload` o `argvus sessionctl logs`.

## Migrazione da `exec argvus-tty`

Le versioni precedenti installavano `argvus-tty` in `/usr/bin`, e alcuni utenti avviavano la sessione da `~/.profile` con `exec argvus-tty`. Quel file ora è privato e non è più su `PATH`, quindi la linea fallisce dopo l'aggiornamento. Sostituiscila con il punto di accesso supportato:

```sh
exec argvus --start-desktop
```
`argvus tty` è lo stesso punto di ingresso. Rimuovi o aggiorna la riga in `~/.profile`, `~/.zprofile` o `~/.bash_profile` prima del prossimo accesso su un TTY.
