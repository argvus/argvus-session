---
title: Sesión TTY
description: Inicie ARGVUS manualmente desde un terminal virtual.
---
Después de iniciar sesión en un TTY, inicia la sesión con:

```sh
argvus --start-desktop
```
Este es el punto de entrada manual compatible desde `argvus session`. Utiliza el mismo `argvus start` y el ciclo de vida del servicio de usuario que un inicio de sesión gráfico.

Para inspeccionar o reiniciar la sesión resultante, use `argvus sessionctl status`, `argvus sessionctl reload` o `argvus sessionctl logs`.

## Migración desde `exec argvus-tty`

Las versiones anteriores instalaban `argvus-tty` en `/usr/bin`, y algunos usuarios iniciaban la sesión desde `~/.profile` con `exec argvus-tty`. Ese archivo ahora es privado y ya no está en `PATH`, por lo que la línea falla después de la actualización. Reemplácela con el punto de entrada compatible:

```sh
exec argvus --start-desktop
```
`argvus tty` es el mismo punto de entrada. Elimine o actualice la línea en `~/.profile`, `~/.zprofile` o `~/.bash_profile` antes del próximo inicio de sesión en un TTY.
