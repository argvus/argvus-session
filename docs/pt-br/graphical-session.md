---
title: Sessão gráfica
description: Inicie o ARGVUS pelo login gráfico.
---

O ponto de entrada gráfico é `argvus session`. Ele define o ambiente da sessão e delega para `argvus start`, que o importa no gerenciador de usuário, valida a configuração Lua do Hyprland fornecida pelo pacote ou pelo usuário, aplica ajustes gráficos detectados, inicia o Hyprland e aguarda o compositor ficar pronto.

Os logs são gravados em `~/.local/state/argvus/session.log`. O greeter roda como outro usuário antes do login, então sua saída pré-login fica em `/run/argvus-greeter/session.log` e é anexada ao `session.log` quando a sessão inicia. Consulte esse arquivo primeiro quando um aviso de inicialização do Hyprland não aparecer no log da sessão.

A sessão garante que a variável de ambiente `PATH` do shell esteja definida para um padrão sensato, mesmo quando o gerenciador de login (como greetd com `source_profile=false`) não exporta nenhum. Isso garante que utilitários como `hyprland-dialog`, usados pelo Hyprland na inicialização, sejam descobertos pelos processos filhos.

Depois que o Hyprland está pronto, `argvus sessionctl` inicia `argvus-session.target`. Esse target inicia taskbar, Control Panel, notificações, wallpaper, idle, clipboard, o agente SSH, o provedor Secret Service e serviços relacionados. Um único spinner de carregamento fica na tela desde a troca do login até esses serviços iniciarem.

`PATH` também recebe `~/.local/bin` e `~/.cargo/bin` no início, quando esses diretórios existem, para que ferramentas instaladas ali fiquem visíveis ao compositor e aos serviços. `EDITOR` e `VISUAL` recebem o editor de terminal padrão configurado nos aplicativos padrão do Control Center (`TERMINAL_EDITOR`) e são exportados para o gerenciador systemd do usuário, para a ativação via D-Bus e para o Hyprland, de modo que terminais e serviços iniciados pela sessão os herdem. O agente SSH (`argvus-ssh-agent.service`, do pacote `openssh`) escuta em `$XDG_RUNTIME_DIR/ssh-agent.socket` e publica `SSH_AUTH_SOCK` no gerenciador do usuário. Ao iniciar, o agente do ARGVUS substitui `SSH_AUTH_SOCK` no gerenciador do usuário. Se outro agente, como gnome-keyring ou gcr, deve ser o dono do socket, desative a unit do ARGVUS com `systemctl --user mask argvus-ssh-agent.service`. Ele é encerrado quando o Hyprland termina, evitando processos órfãos após o logout.

O provedor Secret Service é a unit `argvus-secret-service.service`. Ela inicia a unit upstream `gnome-keyring-daemon.service` apenas com o componente `secrets`, por isso não serve chaves SSH, e `SSH_AUTH_SOCK` continua sob responsabilidade de `argvus-ssh-agent.service`. A unit é ignorada quando o `gnome-keyring` não está instalado. O pacote declara o `gnome-keyring` como dependência opcional, o mesmo que o `argvus-taskbar-calendar`, que guarda ali as senhas do CalDAV. O ARGVUS não altera o PAM, então o keyring não é desbloqueado no login: o primeiro aplicativo que o usa pede a senha do keyring, e a coleção de login é criada nesse momento. Para verificar o estado, execute `argvus sessionctl secret-service-status`, que informa se está ausente, parado, em execução, bloqueado ou desbloqueado. Para que o KWallet ou o KeePassXC assuma o Secret Service, desative a unit do ARGVUS com `systemctl --user mask argvus-secret-service.service`; o provedor é encerrado quando a sessão termina.

A sessão também importa as variáveis Wayland e do ambiente desktop para o gerenciador systemd do usuário. Para inspecionar ou recarregar uma sessão ativa:

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

`reload` aplica a generation que já foi commitada. Se um comando como `argvus config apply-theme`, `accent`, `set`/`patch` ou uma mudança de bloco de widget-telemetry acabou de projetar a mudança, o reload restaura os consumidores afetados a partir do manifesto de projeção em vez de projetar de novo. Ele só projeta quando não existe plano pendente, por exemplo no startup da sessão. Se nenhuma seção relevante para o runtime mudou, ele termina com sucesso sem recarregar o Hyprland nem reiniciar serviços. O splash continua cobrindo o reload inteiro, porque ele começa antes da projeção, então um reload o mostra mesmo quando nada mudou. Quando existem mudanças, reaplica a integração da sessão e recarrega somente o compositor e as superfícies afetadas. Reloads repetidos são serializados e seções sem alteração não reiniciam seus consumidores. `apply-config` é um alias explícito dessa operação. O overlay do reload direto é estático e opaco enquanto o trabalho acontece, para que a área de trabalho intermediária não fique visível. Ele não substitui o logout quando é necessário reiniciar o compositor ou o ambiente de login.

Se a projeção não puder ser concluída, o reload para antes de reiniciar as superfícies do desktop. Consulte `argvus sessionctl logs` e execute `argvus config validate` antes de tentar novamente; isso evita deixar Waybar, notificações ou o Control Panel executando uma mistura antiga de temas após uma projeção falha.

O fluxo padrão usa greetd. Para a sequência de inicialização e a responsabilidade dos serviços, veja [Ciclo de vida em tempo de execução](/pt/docs/developer-guide/architecture/runtime-lifecycle/).
