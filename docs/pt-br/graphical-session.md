---
title: Sessão gráfica
description: Inicie o ARGVUS pelo login gráfico.
slug: pt/0.4.0/docs/user-guide/sessions/graphical-session
---

O ponto de entrada gráfico é `/usr/bin/argvus-session`. Ele importa o ambiente da sessão e delega para `argvus-start`, que valida a configuração Lua do Hyprland fornecida pelo pacote ou pelo usuário, aplica ajustes gráficos detectados, inicia o Hyprland e aguarda o compositor ficar pronto.

Os logs são gravados em `~/.local/state/argvus/session.log`. O greeter roda como outro usuário antes do login, então sua saída pré-login fica em `/run/argvus-greeter/session.log` e é anexada ao `session.log` quando a sessão inicia. Consulte esse arquivo primeiro quando um aviso de inicialização do Hyprland não aparecer no log da sessão.

A sessão garante que a variável de ambiente `PATH` do shell esteja definida para um padrão sensato, mesmo quando o gerenciador de login (como greetd com `source_profile=false`) não exporta nenhum. Isso garante que utilitários como `hyprland-dialog`, usados pelo Hyprland na inicialização, sejam descobertos pelos processos filhos.

Depois que o Hyprland está pronto, `argvus-sessionctl` inicia `argvus-session.target`. Esse target inicia taskbar, Control Panel, notificações, wallpaper, idle, clipboard e serviços relacionados. Ele é encerrado quando o Hyprland termina, evitando processos órfãos após o logout.

A sessão também importa as variáveis Wayland e do ambiente desktop para o gerenciador systemd do usuário. Para inspecionar ou recarregar uma sessão ativa:

```sh
argvus-sessionctl status
argvus-sessionctl logs
argvus-sessionctl reload
```

`reload` aplica a generation que já foi commitada. Se um comando como `argvus-config apply-theme`, `accent`, `set`/`patch` ou uma mudança de bloco de widget-telemetry acabou de projetar a mudança, o reload restaura os consumidores afetados a partir do manifesto de projeção em vez de projetar de novo. Ele só projeta quando não existe plano pendente, por exemplo no startup da sessão. Se nenhuma seção relevante para o runtime mudou, ele termina com sucesso sem recarregar o Hyprland, reiniciar serviços ou mostrar o splash. Quando existem mudanças, reaplica a integração da sessão e recarrega somente o compositor e as superfícies afetadas. Reloads repetidos são serializados e seções sem alteração não reiniciam seus consumidores. `apply-config` é um alias explícito dessa operação. O overlay do reload direto é estático e opaco enquanto o trabalho acontece, para que a área de trabalho intermediária não fique visível. Ele não substitui o logout quando é necessário reiniciar o compositor ou o ambiente de login.

Se a projeção não puder ser concluída, o reload para antes de reiniciar as superfícies do desktop. Consulte `argvus-sessionctl logs` e execute `argvus-config validate` antes de tentar novamente; isso evita deixar Waybar, notificações ou o Control Panel executando uma mistura antiga de temas após uma projeção falha.

O fluxo padrão usa greetd. Para a sequência de inicialização e a responsabilidade dos serviços, veja [Ciclo de vida em tempo de execução](../../developer-guide/architecture/runtime-lifecycle/).
