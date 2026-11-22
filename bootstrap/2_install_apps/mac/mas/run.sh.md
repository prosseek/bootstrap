# `run.sh` 동작 설명

`run.sh`는 macOS에서 `masfile/essential.mas`의 App Store 앱을 설치하는 시작점이다.
실제 설치는 `install.sh`가 담당하고, `run.sh`는 관리자 비밀번호를 다루는 실행 환경만
준비한다. 구조는 `../brew/run.sh`와 같다.

- GUI에서 시작했을 때 Terminal로 넘겨 비밀번호를 입력받을 수 있게 한다.
- 설치 시작 시 관리자 인증을 한 번만 받고, 설치가 끝날 때까지 인증을 유지한다.
- `bash install.sh essential`을 호출한다.

## 왜 필요한가

mas 4.0.0부터 앱 설치와 업데이트에는 root 권한이 필요하다. 그래서 `mas install`을
실행하면 mas가 필요한 순간에 `Password:`를 묻는다. mas는 이미 유효한 `sudo` 인증이
있으면 그것을 쓰고, 없으면 비밀번호를 묻는다. 비밀번호는 `sudo` 프로세스로 바로
전달되며 mas가 보거나 저장하지 않는다.

`install.sh`만 실행하면 다음 문제가 생길 수 있다.

1. TextMate나 Finder처럼 TTY가 없는 환경에서는 비밀번호를 입력할 수 없다.
2. 앱이 많거나 큰 앱을 받는 중에 `sudo` 인증이 만료되면 설치 도중에 다시 묻는다.
3. 비밀번호 입력이 실패해도 App Store 로그인 문제처럼 보인다.

## 실행 방법

```bash
cd /Users/smcho/github/prosseek/bootstrap/bootstrap/2_install_apps/mac/mas
bash run.sh
```

TextMate나 Finder에서 실행해도 된다. 이 경우 `run.sh`가 Terminal을 열어 자신을 다시
실행하고, 비밀번호는 **시작할 때 한 번만** 입력한다.

> `sudo bash run.sh`처럼 전체를 root로 실행하면 안 된다. 일반 사용자로 실행하면
> mas가 기존 `sudo` 인증을 쓴다. App Store에는 미리 로그인해 두어야 한다 (자동화할 수 없다).

## 실행 순서

```text
run.sh 시작
  │
  ├─ 스크립트가 있는 mas/ 디렉터리로 이동
  ├─ TTY가 없음? → Terminal을 열어 run.sh를 다시 실행하고 종료
  ├─ sudo -v: 관리자 인증을 미리 받음 (실패하면 종료)
  ├─ 백그라운드에서 60초마다 sudo -n -v로 인증 유지
  └─ bash install.sh essential
       └─ 끝나면 trap이 백그라운드 프로세스를 종료
```

## `../brew/run.sh`와 다른 점

- BasicTeX 관련 설명이 없다. mas가 root를 쓰는 이유만 다룬다.
- Rosetta(x86_64)에서 arm64로 다시 시작하는 블록이 없다. mas는 arm64 바이너리라
  셸의 아키텍처와 상관없이 실행되고, Homebrew 설치는 `../brew/run.sh`가 이미 처리한다.
- Homebrew 설치(`ensure_brew`)를 하지 않는다. `install.sh`가 `load_brew`와 `mas`
  존재를 확인하고, 없으면 `../brew/run.sh`를 먼저 실행하라고 안내한다.

## 문제 해결

### 비밀번호 창을 취소했을 때

스크립트는 즉시 종료한다. 다시 `bash run.sh`를 실행하면 된다.

### `FAIL ... (App Store signed in? administrator password correct?)`

App Store 앱에 로그인했는지, 비밀번호를 정확히 입력했는지 확인한 뒤 다시 실행한다.
이미 설치된 앱은 `install.sh`가 건너뛴다.
