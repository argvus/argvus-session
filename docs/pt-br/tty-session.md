---
title: Sessão TTY
description: Inicie o ARGVUS manualmente por um terminal virtual.
---

Depois de fazer login em um TTY:

```sh
argvus --start-desktop
```

Esse é o ponto de entrada manual de `argvus session` e usa o mesmo ciclo de vida de `argvus start` e dos serviços de usuário. Consulte `argvus sessionctl status`, `reload` e `logs`.

## Migração de `exec argvus-tty`

Versões anteriores instalavam `argvus-tty` em `/usr/bin`, e alguns usuários iniciavam a sessão pelo `~/.profile` com `exec argvus-tty`. Esse arquivo agora é privado e não está mais no `PATH`, então a linha falha depois da atualização. Substitua pelo ponto de entrada suportado:

```sh
exec argvus --start-desktop
```

`argvus tty` é o mesmo ponto de entrada. Remova ou atualize a linha em `~/.profile`, `~/.zprofile` ou `~/.bash_profile` antes do próximo login em um TTY.
