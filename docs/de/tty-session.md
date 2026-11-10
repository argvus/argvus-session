---
title: TTY-Sitzung
description: Starten Sie ARGVUS manuell von einem virtuellen Terminal.
---
Nach dem Einloggen auf einem TTY starten Sie die Sitzung mit:

```sh
argvus --start-desktop
```
Dies ist der unterstützte manuelle Einstiegspunkt von `argvus session`. Er verwendet denselben `argvus start`- und Benutzer-Service-Lebenszyklus wie ein grafischer Login.

Um die resultierende Sitzung zu überprüfen oder neu zu starten, verwenden Sie `argvus sessionctl status`, `argvus sessionctl reload` oder `argvus sessionctl logs`.

## Migration von `exec argvus-tty`

Frühere Versionen installierten `argvus-tty` in `/usr/bin`, und einige Benutzer starteten die Sitzung von `~/.profile` mit `exec argvus-tty`. Diese Datei ist jetzt privat und befindet sich nicht mehr auf `PATH`, sodass die Zeile nach dem Upgrade fehlschlägt. Ersetzen Sie sie durch den unterstützten Einstiegspunkt:

```sh
exec argvus --start-desktop
```
`argvus tty` ist derselbe Einstiegspunkt. Entfernen oder aktualisieren Sie die Zeile in `~/.profile`, `~/.zprofile` oder `~/.bash_profile` vor dem nächsten Login auf einem TTY.
