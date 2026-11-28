```
- conf/zsh/zsh/path/ 또는 conf/zsh/zsh/env/의 설정을 바꾼 뒤, 열려 있는 현재 터미널에 적용할 때
- 현재 셸이 ZSH_ENV_DONE=1을 상속받아, 단순히 zsh를 실행해도 zprofile을 다시 읽지 않을 때
- 예: EDITOR, RIPGREP_CONFIG_PATH, THIS_VERSION, Homebrew PATH 설정을 바꾼 경우
각 명령의 역할은:
- unset ZSH_ENV_DONE: “이미 환경 초기화를 끝냈다”는 표식을 지웁니다.
- exec zsh: 현재 셸 프로세스를 새 zsh로 교체합니다. 새 zsh의 zshrc가 표식이 없음을 보고 zprofile을 읽고, 다시 표식을 설정합니다. exec라서 불필요하게 중첩된 자식 셸도 남지 않습니다.
새 로그인 터미널을 처음 여는 경우에는 원래 zprofile이 읽히므로 필요 없습니다. 설정 파일 수정 후 기존 셸을 갱신하는 용도입니다. path는 중복 제거(typeset -U path)도 하므로 이 재초기화 과정에서 같은 경로가 계속 늘어나지 않도록 되어 있습니다.

네. **일반적으로 터미널 창이나 탭을 새로 열면 설정이 다시 적용되므로**, 그 뒤에 원래 실행하려던 `bash` 명령을 다시 실행해도 됩니다.
다만 완전히 같은 동작은 아닙니다. `unset ZSH_ENV_DONE; exec zsh`는 **현재 터미널의 셸**을 교체해 설정을 다시 읽습니다. 새 터미널은 별도의 셸을 시작하며, 기존 셸에서 직접 설정한 변수나 작업 상태는 가져오지 않습니다.
한 가지 예외는 tmux처럼 이미 실행 중인 서버에서 새 셸을 여는 경우입니다. 서버가 예전의 `ZSH_ENV_DONE=1`을 갖고 있으면 새 셸이 이전 환경을 상속해 변경사항을 건너뛸 수 있습니다. 이때는 해당 셸에서 아래 두 줄을 실행하면 됩니다.

tmux도 새 창이나 pane을 만들 때 **새 셸 프로세스를 실행합니다**. 문제는 셸을 새로 만들지 않아서가 아니라, 그 셸이 **이미 실행 중인 tmux 서버의 환경을 상속**한다는 데 있습니다.
예를 들어 tmux 서버가 시작될 때 `ZSH_ENV_DONE=1`을 갖고 있었다면, 나중에 새 pane을 만들어도 그 표시가 새 셸에 전달될 수 있습니다. 그러면 새 zsh의 `zshrc`는 환경 설정이 이미 끝났다고 판단해 `zprofile`을 건너뜁니다.
단, 새 셸이 **로그인 셸**로 시작된다면 `zshrc`보다 먼저 `zprofile`을 직접 읽으므로 이 문제가 발생하지 않습니다. 실제 동작은 tmux의 셸 설정과 환경에 따라 달라집니다.
앞서 제가 “새 터미널이면 설정이 다시 적용된다”고 한 설명도 이 점을 단순화했습니다. 새 터미널에서 시작한 셸이 비로그인 셸이고 오래된 환경을 상속한다면 같은 문제가 생길 수 있습니다.
```

그리고 `bash`가 실행되지 않은 원인이 PATH 설정 변경 때문이라면 재시작으로 해결될 수 있지만, 다른 원인이라면 오류가 그대로 남을 수 있습니다.
```

unset ZSH_ENV_DONE
exec zsh

# Basic

sudo apt install git curl vim
sudo apt install fd-find fzf

# Python

curl -LsSf https://astral.sh/uv/install.sh | sh
> installing to /home/smcho/.local/bin

## PyTorch

uv venv --python 3.12
source .venv/bin/activate
uv pip install torch torchvision torchaudio \
  --index-url https://download.pytorch.org/whl/cpu

# zsh
sudo apt update
sudo apt install zsh 

## Oh My Zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

## Change Shell
chsh -s "$(command -v zsh)"

# Avahi
sudo apt install avahi-utils

# SSH
sudo apt update
sudo apt install openssh-server
sudo systemctl enable --now ssh

sudo ufw status
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status verbose

# Docker

sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl status docker          # 실행 확인 (보통 자동 시작)
sudo docker run hello-world           # 동작 테스트
sudo usermod -aG docker $USER         # sudo 없이 사용 (재로그인 필요)

## Ollama
sudo apt install -y zstd
curl -fsSL https://ollama.com/install.sh -o install.sh
less install.sh      # 내용 확인 (선택)
sh install.sh

## For Notebook - prevent sleeping

sudo mkdir -p /etc/systemd/logind.conf.d
sudo tee /etc/systemd/logind.conf.d/server-mode.conf <<'EOF'
[Login]
HandleLidSwitch=ignore
HandleLidSwitchExternalPower=ignore
HandleLidSwitchDocked=ignore
IdleAction=ignore
EOF
sudo systemctl restart systemd-logind

### Light Off
sudo apt install brightnessctl
brightnessctl set 0                                   # 백라이트 끄기
sudo sh -c 'TERM=linux setterm --blank force < /dev/tty1'