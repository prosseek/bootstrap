# zsh
sudo apt update
sudo apt install zsh git curl

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
