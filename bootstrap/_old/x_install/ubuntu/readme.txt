first_setup_ubuntu.sh - packages_cli.txt + install_pkg 방식 (apt)

--------------------------------------------------------------------
왜 brew bundle 방식을 쓰지 않았나
--------------------------------------------------------------------

Mac 쪽(mac/first_setup_mac.sh)은 Brewfile + `brew bundle`로 전환했다
(mac/readme.txt 참고). Ubuntu에서도 같은 걸 할 수 있는지 검토했는데:

  - Homebrew(Linuxbrew)가 Linux에서도 동작하고 `brew bundle`도 그대로
    쓸 수 있긴 하다. 하지만 지금은 apt 기반 workflow를 그대로 유지하고
    싶어서, 당분간은 packages_cli.txt + install_from_list() +
    install_pkg() 조합을 계속 쓰기로 했다.
  - apt 네이티브 대안(dpkg --get-selections 등)은 Brewfile만큼
    사람이 읽고 편집하기 좋은 포맷이 아니라서 채택하지 않았다.

--------------------------------------------------------------------
현재 동작
--------------------------------------------------------------------

1. `sudo apt update` (기존과 동일)

2. zsh 설치는 주석 처리되어 스킵된다 (conf/zsh/run.sh가 이미 앞
   단계에서 실행됐다고 가정 - 기존과 동일)

3. packages_cli.txt를 한 줄씩 읽어서 설치한다. "#" 주석과 빈 줄
   처리는 mac/readme.txt에서 설명한 것과 동일한 로직
   (line=${line%%#*}, xargs trim, [[ -z ]] continue)을 그대로 쓴다.

4. 각 줄에 대해 install_apt_entry()가 apt install을 시도한다.
     install_pkg "$canonical" "$candidate" 2>&1 | tee -a "$REPORT_FILE"
     status=${PIPESTATUS[0]}
   결과(성공/실패)를 화면 + REPORT_FILE(기본:
   ~/temp/ubuntu_setup_report_<타임스탬프>.txt)에 실시간으로 남기고,
   마지막에 "installed successfully (N)" / "failed (N)" 요약을
   append한다. mac 쪽과 동일하게 tee + PIPESTATUS 패턴을 쓰는 이유는
   파이프를 쓰면 `$?`가 tee의 상태가 돼버리기 때문이다.

--------------------------------------------------------------------
"이름이 2개 이상"인 경우 - fallback 설치 (신규)
--------------------------------------------------------------------

packages_cli.txt는 원래부터 "이름이 apt에서 다르면 name apt-name로
적는다"는 규칙이 있었다 (예: `fd fd-find`, `rg ripgrep`,
`go golang-go`). 기존 pkg_linux.sh는 이걸 "두 번째 이름을 무조건
실제 apt 패키지명으로 쓴다"로 처리했다 (install_pkg_linux() 안의
apt_name="${2:-$1}").

이번에 바꾼 부분: 이제는 각 줄에 적힌 이름들을 순서대로 하나씩
"시도"한다.
  - 첫 번째 이름으로 `apt install`을 시도한다.
  - 실패하면 (예: `apt install fd` -> 그런 패키지 없음) 다음 이름으로
    다시 시도한다 (`apt install fd-find`).
  - 성공하면 거기서 멈춘다. 전부 실패하면 그 줄 전체를 실패로 기록한다.
  - 줄에 이름이 3개 이상이어도 똑같이 순서대로 다 시도한다
    (install_apt_entry는 임의 개수의 후보를 받는다).

    install_apt_entry() {
        local names=("$@")
        local canonical="${names[0]}"
        for candidate in "${names[@]}"; do
            install_pkg "$canonical" "$candidate" ...
            [[ 성공 ]] && return
        done
        # 여기까지 왔으면 전부 실패
    }

conf/<name>/run.sh 조회는 항상 "첫 번째 이름"(canonical)을 기준으로
한다 - install_pkg()의 첫 번째 인자가 그대로 config script 경로에
쓰이기 때문에, 실제로 어떤 candidate 이름으로 설치에 성공했든
conf/fd/run.sh, conf/rg/run.sh처럼 원래 의도한 경로가 그대로 쓰인다.

--------------------------------------------------------------------
"이미 설치되어 있으면 skip" 을 여기서는 넣지 않은 이유
--------------------------------------------------------------------

Mac의 이전 install_from_list() 버전(brew bundle 전환 전)에서는
이미 설치된 패키지는 install_pkg 호출 자체를 건너뛰도록 만들었는데,
그 부작용으로 conf/<name>/run.sh가 재실행마다 자동으로 다시 적용되지
않게 됐다 (mac/readme.txt 참고).

Ubuntu 버전은 반대로 "run.sh도 돌아가야 한다"는 요구가 있었기 때문에,
이미 설치돼 있는지 미리 확인해서 건너뛰는 로직을 넣지 않았다. 대신
install_pkg는 매번 그대로 호출되고, apt install 자체가 이미 설치된
패키지에 대해서는 빠르게 "이미 최신 버전" 상태로 끝나므로, 결과적으로
conf/<name>/run.sh는 재실행 때마다 계속 다시 적용된다. report에는
"성공/실패"만 구분되고 "새로 설치됨 / 이미 있었음"은 따로 구분하지
않는다 - 필요해지면 나중에 추가할 수 있다.
