---
title: TTY 세션
description: 가상 터미널에서 ARGVUS를 수동으로 시작하세요.
---
TTY에서 로그인한 후, 세션을 다음과 같이 시작하십시오:

```sh
argvus --start-desktop
```
이는 `argvus session`에서 지원되는 수동 진입점입니다. 그래픽 로그인과 동일한 `argvus start` 및 사용자 서비스 라이프사이클을 사용합니다.

결과 세션을 검사하거나 재시작하려면 `argvus sessionctl status`, `argvus sessionctl reload` 또는 `argvus sessionctl logs`를 사용하십시오.

## `exec argvus-tty`에서 마이그레이션

이전 버전에서는 `argvus-tty`를 `/usr/bin`에 설치했고, 일부 사용자는 exec argvus-tty와 함께 `~/.profile`에서 세션을 시작했습니다. 그 파일은 이제 비공개이며 더 이상  `exec argvus-tty` `PATH`에 없으므로 업그레이드 후 해당 줄은 실패합니다. 지원되는 진입점으로 교체하십시오:

```sh
exec argvus --start-desktop
```
`argvus tty`는 동일한 진입점입니다. 다음 TTY 로그인 전에 `~/.profile`, `~/.zprofile` 또는 `~/.bash_profile`에서 해당 줄을 제거하거나 업데이트하십시오.
