---
title: 그래픽 세션
description: 그래픽 로그인 흐름을 통해 ARGVUS를 시작하십시오.
---
그래픽 진입점은 `argvus session`입니다. 이 점은 세션 환경을 설정하고 `argvus start`로 위임하며, 이것은 사용자 관리자에 가져와 패키지화된 또는 사용자 Hyprland Lua 구성 파일을 검증하고, 감지된 그래픽 호환성 설정을 적용하며, Hyprland를 실행하고 컴포지터 준비가 완료될 때까지 기다립니다.

로그는 `~/.local/state/argvus/session.log`에 작성됩니다. 그리터는 로그인 전 자체 사용자로 실행되므로 로그인 전 출력은 `/run/argvus-greeter/session.log`에 보관되며 세션 시작 시 `session.log`에 추가됩니다. Hyprland에서 발생하는 시작 경고가 세션 로그에 나타나지 않을 때 이 파일을 먼저 확인하세요.

세션은 로그인 관리자(예: source_profile=false와 함께 사용하는 greetd)가 환경 변수를 내보내지 않더라도 셸 `PATH` 환경 변수가 합리적인 기본값으로 설정되도록 보장합니다. 이는 Hyprland가 시작 시 사용하는  `source_profile=false` `hyprland-dialog`와 같은 유틸리티를 자식 프로세스가 찾을 수 있도록 보장합니다.

Hyprland가 준비되면 `argvus sessionctl`이 `argvus-session.target`을 시작합니다. 이 대상은 작업 표시줄, 제어판, 알림, 바탕화면, 유휴 처리, 클립보드, SSH 에이전트, 시크릿 서비스 공급자 및 관련 서비스를 시작합니다. 로그인 인계부터 이러한 서비스가 시작되고 바탕화면과 작업 표시줄이 화면에 표시될 때까지 단일 로딩 스피너가 화면에 유지됩니다(최대 1.5초 추가). Hyprland를 실행하기 전에 `argvus-start`은 설정 투영(`argvus-config.service`)을 대기열에 넣고, 이는 컴포지터 시작 중에 실행되며, 그리터의 DRM 인계 표면이 디스플레이를 해제하도록 요청합니다(`/usr/lib/argvus/greeter/handoff --send release`); 해당 표면이 실행되면 먼저 `loginctl activate`으로 세션을 활성화하여 Hyprland가 백그라운드의 VT에서 시작되지 않도록 합니다. 그런 다음 세션 스피너는 해당 표면에 Hyprland의 첫 프레임을 가린 오버레이를 제거하라고 지시합니다.

데스크탑이 준비된 후, 세션은 TTY, ARGVUS Greeter 및 기타 로그인 관리자를 위해 `argvus welcome --if-needed`를 실행합니다. 사용자별 진행 기록 `opened`, 완료 또는 닫기가 없는 한 통합 제어 센터 환영 페이지를 엽니다. 첫 번째 성공적인 렌더링은 `opened`를 `${XDG_STATE_HOME:-$HOME/.local/state}/argvus/welcome/progress.json`에 저장하여 이후 로그인 시 다시 열리는 것을 방지합니다. 이는 `/etc/skel`에 의존하지 않습니다. 해당 기록이 없는 기존 계정도 자동으로 한 번 열립니다. 렌더링 전에 실패하면 다음 로그인 시 다시 시도할 수 있습니다. 수동 `argvus welcome`는 계속 사용할 수 있습니다.

`PATH`는 해당 디렉터리가 존재할 경우 `~/.local/bin`와 `~/.cargo/bin`도 앞쪽에 추가되므로, 그곳에 설치된 도구들은 합성기(compositor)와 서비스에서 볼 수 있습니다. `EDITOR`와 `VISUAL`는 제어 센터 기본 앱(`TERMINAL_EDITOR`)에서 설정한 기본 터미널 편집기로 설정되며, 시스템드(user manager), D-Bus 활성화 및 Hyprland에 내보내어 세션에서 실행되는 터미널과 서비스가 이를 상속받습니다. SSH 에이전트(`argvus-ssh-agent.service`, `openssh`에서 가져옴)는 `$XDG_RUNTIME_DIR/ssh-agent.socket`에서 대기하고 `SSH_AUTH_SOCK`를 사용자 매니저에 게시합니다. ARGVUS 에이전트가 시작되면 사용자 매니저에서 `SSH_AUTH_SOCK`를 대체합니다. gnome-keyring 또는 gcr와 같은 다른 에이전트가 소켓을 소유해야 하는 경우 `systemctl --user mask argvus-ssh-agent.service`로 ARGVUS 유닛을 비활성화하십시오. Hyprland 종료 시 중지되므로, 로그아웃 후 이러한 인터페이스가 고아 프로세스로 남지 않습니다.

시크릿 서비스 공급자는 `argvus-secret-service.service`입니다. 이는 secrets 구성 요소만으로 상류 `gnome-keyring-daemon.service`를 시작하므로, SSH 키를 제공하지 않으며  `secrets` `SSH_AUTH_SOCK`는 `argvus-ssh-agent.service`가 소유한 상태로 유지됩니다. `gnome-keyring`가 설치되지 않은 경우 유닛은 건너뜁니다. 패키지는 선택적 의존성으로 `gnome-keyring`를 선언하며, CalDAV 비밀번호를 저장하는 `argvus-taskbar-calendar`도 마찬가지입니다. ARGVUS는 PAM을 변경하지 않으므로, 로그인 시 키링이 잠금 해제되지 않습니다. 키링을 사용하는 첫 번째 애플리케이션이 키링 비밀번호를 요청하며, 그때 로그인 컬렉션이 생성됩니다. 상태는 `argvus sessionctl secret-service-status`로 확인할 수 있으며, 누락됨, 중지됨, 실행 중, 잠김 또는 잠금 해제됨을 보고합니다. KWallet 또는 KeePassXC가 대신 시크릿 서비스를 소유하게 하려면, ARGVUS 유닛을 `systemctl --user mask argvus-secret-service.service`로 비활성화하십시오. 세션이 종료되면 공급자는 중지됩니다.

세션은 또한 자신의 Wayland 및 데스크톱 환경 변수를 systemd 사용자 관리자에 가져옵니다. 실행 중인 세션을 검사하거나 다시 로드하려면:

```sh
argvus sessionctl status
argvus sessionctl logs
argvus sessionctl reload
```

`reload`은 이미 커밋된 세대를 적용합니다. 만약 `argvus config apply-theme`, `accent`, `set`/`patch` 같은 명령어나 위젯 텔레메트리 블록 변경이 단순히 변경을 예상만 했다면, 리로드는 다시 예상하는 대신 변경된 소비자를 예상 매니페스트에서 복원합니다. 보류 중인 계획이 없을 때만 예측을 수행하며, 예를 들어 세션 시작 시가 이에 해당합니다. 런타임 관련 섹션이 변경되지 않았다면, Hyprland를 리로드하거나 서비스를 재시작하지 않고 정상적으로 종료됩니다. 변경이 존재하면, 세션 통합을 다시 적용하고 영향받은 컴포지터와 데스크탑 서페이스만 리로드합니다. 스플래시는 표면을 재생성할 때만 리로드를 커버합니다: Waybar 바(작업 표시줄이나 위젯 텔레메트리)의 재시작, 제어판의 재시작, 또는 대체 `full` 계획의 경우입니다. 테마, 강조 색상, 효과, 글꼴, 창 배치 및 배경화면 변경은 제자리에서 리로드됩니다(`argvus config theme-runtime consumers` 및 `wallpaper`, Hyprland의 `/reload`) 스플래시 없이 진행됩니다. 아무 작업도 없을 때의 리로드는 아무것도 표시하지 않습니다. 반복적인 리로드는 직렬 처리되며 변경되지 않은 섹션은 그 소비자를 재시작하지 않습니다. `apply-config`는 이 작업을 위한 명시적 별칭입니다. 표시될 때, 작업이 진행되는 동안 리로드 스플래시는 불투명하여 중간 데스크톱이 노출되지 않습니다. 이는 합성기나 로그인 환경을 재시작해야 할 때 로그아웃을 대체하는 것이 아닙니다.

투영을 완료할 수 없는 경우, 리로드는 데스크톱 표면을 재시작하기 전에 중지됩니다. `argvus sessionctl logs`를 확인하고 다시 시도하기 전에 `argvus config validate`를 실행하세요; 이는 실패한 테마 투영이 Waybar, 알림, 제어판을 테마가 혼합된 상태로 실행된 채로 남기는 것을 방지합니다.

기본 로그인 통합은 greetd입니다. [Greeter](/docs/components/argvus-greeter/) 및 [세션 문제 해결](/docs/user-guide/troubleshooting/session-startup/)를 참조하세요.

서비스 소유권 및 시작 순서에 대해서는 [Runtime lifecycle](/docs/developer-guide/architecture/runtime-lifecycle/)를 참조하십시오.

## 나이트 라이트

`argvus-session`는 `hyprsunset>=0.4.0`에 의존하며 두 번째 데몬을 활성화하지 않고 세션 대상을 통해 상위 사용자 서비스를 시작합니다. `argvus-night-light-init.service`는 진입 시 저장된 상태를 적용합니다. 타이머는 매 분과 시계/시간대 변경 후 고정된 로컬 일정을 평가합니다. 일정이 꺼져 있는 경우 주기적인 확인은 수동 상태를 변경하지 않습니다. 상위 서비스는 로그아웃 시 `graphical-session.target`을 따릅니다.

패키지화된 드롭인은 `--identity`와 `XDG_CONFIG_HOME`/`XDG_CONFIG_DIRS` 서비스-로컬을 사용하여 Hyprsunset를 시작하며, `/usr/share/argvus/session/config/night-light`를 가리킵니다. 이 구성에는 기본 프로필이 포함되어 있지 않습니다. 이는 충돌하는 스케줄러와 업스트림 6000 K 기본에서의 시작을 방지합니다. 설치된 동안 ARGVUS 외부의 업스트림 서비스에도 적용됩니다; 개인 Hyprsunset 파일은 보존됩니다. 사용자 systemd 오버라이드는 우선 적용될 수 있습니다. 패키지 설치는 HOME에 쓰기를 수행하지 않습니다. 설정은 `/displays/night_light`에, 오버라이드는 `$XDG_RUNTIME_DIR/argvus/night-light/`에 있습니다; `argvus config display night-light status`를 참조하십시오.

세션은 환경을 가져오기 전에 로그인한 사용자의 `$XDG_CONFIG_HOME/locale.conf`(기본 `~/.config/locale.conf`)에서 LANG을 로드합니다. 이는 TTY 및 그래픽 로그인 관리자에 적용됩니다. 언어 변경은 로그아웃 후 다시 로그인해야 적용됩니다; `/etc/locale.conf`는 수정되지 않습니다.

유효한 사용자 `LANG`가 없으면, 호스트 로케일이 포르투갈어일지라도 세션은 영어로 시작됩니다. 생성될 때 `en_US.UTF-8`를 사용하고, 그렇지 않으면 `C.UTF-8`를 사용하며, 사용자 구성을 생성하지 않습니다. 로케일 결정은 구성 프로젝션 및 데스크탑 시작 전에 이루어집니다. 세션은 상속된 `LC_ALL`를 제거하고 systemd 사용자 및 D-Bus 활성화 환경의 언어 변수를 대체하며, `LANGUAGE`를 포함합니다. 동일한 locale.conf의 지역 범주는 유지됩니다. 기존 ARGVUS 언어 파일은 무시됩니다.

세션은 Hyprland 시작 전에 개인 TZ 할당을 `$XDG_CONFIG_HOME/environment.d/20-timezone.conf`에서 읽고 이를 사용자 서비스 및 D-Bus 환경으로 가져옵니다. zoneinfo 이름을 검증하고 파일을 실행하지 않습니다. 새로운 로그인을 통해 애플리케이션에 시간대 변경 사항이 적용됩니다.

## 창 버튼 및 애플리케이션 바

최소화는 예약된 `special:argvus-minimized` 작업 공간을 사용합니다. 해당 작업 공간을 수동으로 사용하지 마십시오. `argvus windows service` 프로세스는 컴포지터 인스턴스별 런타임 레지스트리에 `$XDG_RUNTIME_DIR/argvus` 아래에서 정체, 원래 작업 공간/모니터, 지오메트리, 전체 화면/최대화 및 고정 상태를 기록합니다. 기록은 서비스 재시작이나 설정 다시 불러오기 후에도 남아 있지만, 컴포지터 세션 간에는 공유되지 않습니다. 창을 닫으면 해당 기록이 삭제됩니다. 모니터가 사라지면 복원은 사용 가능한 출력으로 수행됩니다. 누락되었거나 복구 막대가 실패하면 새로운 최소화가 차단되며, 복원이 실패하면 기록과 복구 막대가 유지됩니다.

세션은 `argvus-windows.service` 및 `argvus-window-bar.service`를 소유합니다. 후자는 Tile에서 자신의 Waybar 자식을 대기 상태로 유지합니다. hyprbars 플러그인은 `argvus-hyprland`에서 번들로 제공되며, x86_64에서 Hyprland 0.57.0 ABI용으로 빌드되었습니다; 사용자의 홈 디렉토리에서 컴파일되지 않았습니다. 컴포지터 ABI 업데이트 시 플러그인을 다시 빌드하십시오. 세션은 중국어, 일본어 및 한국어를 포함한 10개의 ARGVUS 언어에 대해 선택된 UTF-8 로케일을 전파합니다. 카탈로그 선택은 `argvus i18n`가 처리하며, 시스템 로케일 사용 가능 여부와 폰트 폴백은 별도의 요구 사항입니다.
