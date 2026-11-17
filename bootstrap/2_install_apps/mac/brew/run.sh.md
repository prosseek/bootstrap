# `run.sh` 동작 설명

`run.sh`는 macOS에서 이 디렉터리의 필수 Homebrew 항목을 설치하는 시작점이다.
실제 항목 설치는 `install.sh`가 담당하고, `run.sh`는 다음과 같은 실행 환경을
준비한다.

- GUI에서 시작했을 때 Terminal로 넘겨 `sudo`가 비밀번호를 받을 수 있게 한다.
- Apple Silicon Mac에서 Rosetta(x86_64)로 시작한 경우 arm64 셸로 다시 시작한다.
- 설치 시작 시 관리자 인증을 한 번만 받고, 설치가 끝날 때까지 인증을 유지한다.
- Homebrew가 없으면 먼저 설치한다 (`ensure_brew`, `_common/lib.sh`). 이미 받아 둔 `sudo` 인증을 쓰므로 비밀번호를 다시 묻지 않는다. (예전에는 `1_first_step/mac/2_run.sh`의 9번 단계였고, `setup_mac/_Mac`으로 옮기면서 이쪽으로 이동했다.)
- `brewfile/essential.brewfile`에 정의된 필수 항목 설치를 시작한다.

## 일반적인 실행 방법

Terminal에서는 다음처럼 실행한다.

```bash
cd /Users/smcho/github/prosseek/bootstrap/bootstrap/2_install_apps/mac/brew
bash run.sh
```

TextMate, Finder 또는 TTY가 없는 다른 GUI 환경에서 실행해도 된다. 이 경우
`run.sh`가 macOS Terminal을 자동으로 열고, 그 Terminal 안에서 자신을 다시
실행한다. 관리자 비밀번호가 필요하면 **설치 시작 시 한 번만** 새 Terminal에서
입력한다.

> `sudo bash run.sh`처럼 스크립트 전체를 root로 실행하면 안 된다. Homebrew는
> 일반 사용자로 실행해야 하며, 관리자 권한은 BasicTeX 같은 설치 프로그램이
> 필요한 순간에만 `sudo`를 통해 사용한다.

## 실행 순서

```text
run.sh 시작
  │
  ├─ 스크립트가 있는 brew/ 디렉터리로 이동
  │
  ├─ TTY가 없음?
  │    └─ macOS Terminal을 열어 run.sh를 다시 실행하고, 현재 프로세스 종료
  │
  ├─ Apple Silicon에서 Rosetta(x86_64)로 실행됨?
  │    └─ arm64 Bash로 run.sh를 다시 실행
  │
  ├─ sudo -v로 관리자 인증을 미리 확인
  │
  ├─ 백그라운드에서 sudo 인증 캐시를 주기적으로 갱신
  │
  ├─ ensure_brew: Homebrew가 없으면 설치
  │
  └─ bash install.sh essential
       └─ brewfile/essential.brewfile의 항목을 순서대로 설치
```

## 1. 작업 디렉터리 고정

스크립트는 처음에 자신의 위치인 `brew/` 디렉터리로 이동한다. 따라서 어느
디렉터리에서 실행해도 아래 상대 경로가 같은 위치를 가리킨다.

```bash
cd "$(dirname "${BASH_SOURCE[0]}")"
```

## 2. TTY가 없을 때 Terminal에서 다시 실행

BasicTeX cask는 macOS Installer를 실행하며 관리자 권한이 필요하다. Homebrew는
이때 `sudo`를 호출한다. 그러나 GUI 앱에서 스크립트를 실행하면 표준 입력 또는
출력이 터미널(TTY)에 연결되어 있지 않을 수 있다. 그런 환경에서는 `sudo`가
비밀번호를 읽을 곳이 없어 다음과 같이 실패한다.

```text
sudo: a terminal is required to read the password
```

`run.sh`는 표준 입력과 출력을 검사한다.

```bash
if [ ! -t 0 ] || [ ! -t 1 ]; then
```

TTY가 하나라도 없으면 `osascript`를 사용해 macOS Terminal을 열고, 그 안에서
동일한 `run.sh`를 `exec`로 시작한다. 명령문은 환경 변수로 Terminal에 전달하므로
공백 등이 있는 경로도 셸 인용 규칙에 맞게 처리한다. 원래 GUI 프로세스는 Terminal
실행 요청 후 종료한다.

Terminal 안에서 다시 시작된 프로세스는 TTY를 가지므로 이후 `sudo`가 정상적으로
비밀번호 프롬프트를 표시할 수 있다.

## 3. Rosetta로 시작했을 때 arm64로 전환

Apple Silicon Mac에서 Intel용 앱(TextMate 등)이 스크립트를 시작하면 하위 셸도
`x86_64`로 실행될 수 있다. `/opt/homebrew` Homebrew는 이런 Rosetta 환경에서
설치를 거부할 수 있다.

`run.sh`는 다음 조건을 모두 만족하면 자신을 arm64 Bash로 다시 실행한다.

- 현재 아키텍처가 `x86_64`
- Mac이 실제로 Apple Silicon (`hw.optional.arm64`가 `1`)
- 아직 arm64 재시작을 하지 않음

`BREW_RUN_ARM_RESTART=1` 환경 변수는 재시작이 반복되는 것을 막는다. Intel Mac은
두 번째 조건을 만족하지 않으므로 이 부분을 건너뛴다.

## 4. 시작 시 관리자 인증

BasicTeX가 목록 중간에 있어도 설치가 한참 진행된 뒤 비밀번호를 묻지 않도록,
`run.sh`는 앱 설치 전에 다음을 실행한다.

```bash
sudo -v
```

이 명령은 root 셸을 열거나 비밀번호를 저장하지 않는다. macOS `sudo`의 인증
타임스탬프만 갱신한다. 아직 인증되지 않았다면 이 시점에서 한 번 비밀번호를
요청한다. 인증에 실패하거나 취소하면 스크립트는 설치를 시작하지 않고 종료한다.

## 5. 긴 설치 중 인증 유지

`sudo` 인증은 기본적으로 일정 시간이 지나면 만료된다. BasicTeX보다 먼저 설치할
항목이 많으면 인증이 만료되어 다시 프롬프트가 나타날 수 있다.

그래서 `run.sh`는 백그라운드 프로세스를 하나 시작한다. 이 프로세스는 60초마다
다음을 실행한다.

```bash
sudo -n -v
```

`-n` 옵션은 비대화형 모드이다. 즉 비밀번호를 다시 묻지 않으며, 이미 받은 인증
캐시만 갱신한다. 캐시를 쓸 수 없으면 조용히 종료한다. 스크립트가 끝나거나
중단될 때는 `trap`이 이 백그라운드 프로세스를 종료한다.

따라서 비밀번호를 디스크, 스크립트 변수, 표준 입력에 저장하거나 전달하지 않는다.

## 6. `install.sh essential` 호출

준비가 끝나면 아래 명령이 실행된다.

```bash
bash install.sh essential
```

`install.sh`는 `brewfile/essential.brewfile`을 읽어 항목을 한 줄씩 처리한다.
이미 설치된 항목은 건너뛰고, `/Applications`에 수동 설치된 앱이 있으면 덮어쓰지
않는다. 실패한 항목이 있어도 나머지 설치를 계속하고 마지막에 결과를 요약한다.

현재 `essential.brewfile`에는 다음과 같은 BasicTeX 항목이 포함되어 있다.

```ruby
cask "basictex"
```

이 항목에서 Homebrew가 macOS Installer를 실행할 때, 앞 단계에서 확보하고 유지한
`sudo` 인증이 사용된다.

## 문제 해결

### Terminal이 열리지 않을 때

macOS의 자동화 권한 또는 Terminal 실행이 제한된 환경일 수 있다. Terminal을 직접
열어 `brew/` 디렉터리로 이동한 뒤 `bash run.sh`를 실행한다.

### 관리자 비밀번호 창을 취소했을 때

스크립트는 즉시 종료한다. 다시 `bash run.sh`를 실행하면 된다.

### BasicTeX만 재시도하고 싶을 때

전체 목록을 다시 처리하지 않고 Terminal에서 다음을 실행할 수 있다.

```bash
brew install --cask basictex
```

다만 일관된 실행 환경과 사전 인증이 필요하면 `bash run.sh`를 다시 실행하는 편이
권장된다. 이미 성공한 항목은 `install.sh`가 건너뛴다.
