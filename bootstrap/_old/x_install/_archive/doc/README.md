# First CLIs - Cross-Platform Package Installer

자동으로 macOS와 Linux에서 필수 CLI 도구들을 설치하는 간단한 스크립트입니다.

## 사용법

```bash
cd /Users/smcho/github/prosseek/setup/_first_clis
./run.sh
```

스크립트가 자동으로:
1. 시스템 환경 체크 (OS, package managers)
2. **Linux에서 빌드 도구 설치** (pkg-config, libssl-dev, build-essential)
3. **Linux에서 npm을 사용자 디렉토리로 설정** (sudo 불필요)
4. **필요한 도구 자동 설치** (snap, cargo, npm 등)
5. 패키지 설치
6. 결과 요약 출력

## Install 함수 사용법

```bash
# 기본 사용 (모든 플랫폼에서 같은 이름)
install tmux

# apt에서 이름이 다른 경우
install fd fd-find              # brew: fd, apt: fd-find
install rg ripgrep              # brew: rg, apt: ripgrep

# Linux에서 대안 설치 명령 사용
install yazi "snap install yazi --classic"
install mdcat "cargo install mdcat"
install marp-cli "npm install -g @marp-team/marp-cli"

# Mac 전용 앱
install wezterm --cask          # Linux에서는 자동으로 건너뜀
```

## Linux 사전 준비 (선택사항)

`run.sh`가 자동으로 대부분의 설정을 처리합니다:
- npm을 사용자 디렉토리로 설정
- Rust 패키지 빌드에 필요한 **빌드 도구 자동 설치**:
  - `build-essential` (gcc, g++, make)
  - `pkg-config` (라이브러리 정보)
  - `clang`, `libclang-dev` (LLVM/Clang 컴파일러)
  - `libssl-dev` (OpenSSL 개발 라이브러리)
- **필요한 도구 자동 설치**: 패키지 설치 시 필요한 snap, cargo, npm이 없으면 자동 설치

더 많은 패키지를 설치하려면 다음 도구들을 먼저 설치하세요:

```bash
# Snap (보통 이미 설치됨)
sudo apt install snapd

# Rust/Cargo (mdcat, tree-sitter용)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env

# Node.js/npm (marp-cli, mermaid-cli용)
# run.sh가 자동으로 npm을 사용자 디렉토리로 설정합니다
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
```

## 설치되는 패키지

### 필수 도구 (apt로 설치)
- **tmux** - 터미널 멀티플렉서
- **neovim, vim** - 텍스트 에디터
- **fzf** - 퍼지 파인더
- **fd** (fd-find) - 빠른 파일 검색
- **rg** (ripgrep) - 빠른 텍스트 검색
- **zoxide** - 스마트 디렉토리 점프
- **eza** - 향상된 ls
- **bat** - 향상된 cat
- **entr** - 파일 변경 감지
- **mc** - Midnight Commander

### 선택적 도구 (snap, cargo, npm)
- **yazi** (snap) - 터미널 파일 매니저
- **glow** (snap) - Markdown 뷰어
- **mdcat** (cargo) - Markdown cat
- **marp-cli** (npm) - Markdown 프레젠테이션
- **mermaid-cli** (npm) - 다이어그램 생성
- **tree-sitter** (cargo) - 파서 생성기

### Mac 전용 앱 (Linux에서 자동 건너뜀)
- appcleaner, antinote, aerospace
- macvim-app, emacs, wezterm
- font-meslo-lg-nerd-font, karabiner-elements

## 예상 결과

### macOS
```
✅ Successfully installed (28):
  ✓ marp-cli, tmux, neovim, vim, fzf, fd, zoxide, yazi, ...
  ✓ appcleaner, wezterm, emacs, ...
```

### Linux (모든 도구 설치 시)
```
✅ Successfully installed (20):
  ✓ tmux, neovim, vim, fzf, fd, zoxide, eza, bat, rg, entr, mc
  ✓ yazi, glow, mdcat, tree-sitter, marp-cli, mermaid-cli

❌ Failed to install (8):
  ✗ appcleaner (Mac-only)
  ✗ wezterm (Mac-only)
  ...
```

### Linux (snap만 사용 가능)
```
✅ Successfully installed (14):
  ✓ tmux, neovim, vim, fzf, fd, zoxide, eza, bat, rg, entr, mc
  ✓ yazi, glow

❌ Failed to install (4):
  ✗ mdcat (cargo not installed)
  ✗ tree-sitter (cargo not installed)
  ✗ marp-cli (npm not installed)
  ✗ mermaid-cli (npm not installed)

Common reasons for failure:
  - cargo not installed: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
  - npm not installed: curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
```

## 파일 구조

```
_first_clis/
├── run.sh              # 메인 실행 스크립트 (패키지 목록 여기에!)
├── install.sh          # 간단한 install 함수 정의
└── README.md           # 이 파일

_code/
├── sys_check.sh        # 시스템 환경 체크
└── get_system_info.sh  # OS 감지 유틸리티
```

## 새 패키지 추가하기

`run.sh` 파일의 PACKAGE INSTALLATION 섹션에 추가하면 됩니다:

```bash
# 1. 모든 플랫폼에서 같은 이름
install new-package

# 2. apt 이름이 다른 경우
install brew-name apt-name

# 3. Linux에서 대안 설치 필요
install package-name "snap install package-name"
install package-name "cargo install package-name"
install package-name "npm install -g package-name"

# 4. Mac 전용 앱
install mac-app --cask
```

## 장점

✅ **간단함**: 복잡한 설정 파일 없음, run.sh만 보면 모든 것을 알 수 있음  
✅ **명확함**: 각 패키지가 어떻게 설치되는지 한눈에 보임  
✅ **유연함**: 새 패키지 추가가 쉬움  
✅ **스마트함**: OS 자동 감지, 도구 체크, 실패 원인 안내  
✅ **자동 설정**: Linux에서 npm과 빌드 도구를 자동으로 설정 (sudo 최소화)  

## 문제 해결

### npm 권한 오류 (EACCES: permission denied)

**증상:**
```
npm error code EACCES
npm error syscall mkdir
npm error path /usr/lib/node_modules/@marp-team
npm error errno -13
```

**원인:** npm이 시스템 디렉토리에 쓰기 권한이 없음

**해결 방법:** `run.sh`가 자동으로 해결합니다!
- Linux에서 `run.sh` 실행 시 npm을 자동으로 사용자 디렉토리(`$HOME/.npm-global`)로 설정
- PATH도 자동으로 추가됨 (현재 세션 + shell 설정 파일)
- sudo 없이 npm global 패키지 설치 가능

수동으로 설정하려면:
```bash
cd ~/github/prosseek/setup/_first_clis
chmod +x configure_npm.sh
./configure_npm.sh
```

-> /Users/chos5/github/prosseek/setup/_lib/configure/configure_npm.sh on 2026-04-15

### cargo install 오류 (OpenSSL)

**증상:**
```
error: failed to run custom build command for `openssl-sys v0.9.111`
Could not find directory of OpenSSL installation
```

**원인:** OpenSSL 개발 라이브러리가 없음

**해결 방법:** `run.sh`가 자동으로 해결합니다!
- Linux에서 `run.sh` 실행 시 자동으로 빌드 도구 설치:
  - `build-essential`, `pkg-config`, `clang`, `libclang-dev`, `libssl-dev`

수동으로 설치하려면:
```bash
sudo apt install -y build-essential pkg-config clang libclang-dev libssl-dev
```

### WSL2에서 snap 패키지

**동작 방식:**

WSL2에서는 snap을 사용하지 않고 자동으로 apt로 대체합니다.

```bash
# WSL2에서 실행 시:
./run.sh

# 출력:
⚠  WSL2 detected: Skipping snap (not recommended for WSL2)
→ Using alternative installation methods instead
→ Installing yazi via apt...
✓ Successfully installed yazi
```

**이유:**
- WSL2에서 snap은 systemd 필요 (복잡한 설정)
- 성능 문제 (느림)
- 불안정할 수 있음
- apt로 충분히 대체 가능

### "snap: command not found"
```bash
sudo apt install snapd
sudo systemctl start snapd
```

### "cargo: command not found"
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
```

### "npm: command not found"
```bash
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt install -y nodejs
```

### 시스템 환경 체크만 하고 싶다면
```bash
source ~/github/prosseek/setup/_code/sys_check.sh
sys_check
```
