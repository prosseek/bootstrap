first_setup_mac.sh - 최종 방식: Brewfile + brew bundle

--------------------------------------------------------------------
현재 동작
--------------------------------------------------------------------

1. Homebrew가 없으면 설치한다. (기존과 동일)

2. zsh 설치는 주석 처리되어 스킵된다. (conf/zsh/run.sh가 이미 앞
   단계에서 따로 실행됐다고 가정 - 기존과 동일)

3. "$SCRIPT_DIR/Brewfile"을 읽는다.
     - 파일이 없으면: 다른(이미 세팅이 끝난) Mac에서
       `brew bundle dump --file="$BREWFILE"`로 생성해서 여기로
       가져오라는 안내 메시지를 출력하고 종료(exit 1)한다. 이 스크립트
       자신은 Brewfile을 대신 만들어주지 않는다 - 최신 상태의 Brewfile은
       "이미 설치가 끝난 기준 머신"에서 덤프해오는 게 맞다고 판단했다.
     - 파일이 있으면: `brew bundle install --file="$BREWFILE" --verbose`
       한 줄로 taps / brew formula / cask / mas(App Store) / vscode
       extension / npm / uv 패키지까지 Brewfile에 적힌 모든 걸 설치한다.
       (실제로 지금 Brewfile에는 이 모든 타입이 다 들어있다.)

4. brew bundle의 출력(2>&1)을 tee로 화면에 보여주면서 동시에
   ~/temp/mac_setup_report_<타임스탬프>.txt에 기록한다. `--verbose`를
   쓰기 때문에 이미 설치된 항목도 로그에 나타나므로, 에러가 하나도
   없어도 이번 실행에서 무엇이 이미 있었고 무엇이 새로 설치됐는지
   report 파일에서 확인할 수 있다.
     brew bundle install --file="$BREWFILE" --verbose 2>&1 | tee -a "$REPORT_FILE"
     STATUS=${PIPESTATUS[0]}
   실패가 있었으면 마지막에 "⚠️ brew bundle exited with status N"을
   출력하고, 스크립트도 같은 코드로 exit한다.

--------------------------------------------------------------------
왜 이렇게 바뀌었나 (히스토리)
--------------------------------------------------------------------

원래는 packages_cli.txt / packages_gui.txt / packages_mas.txt 세
목록 파일 + install_from_list() / install_pkg() 조합으로 brew
formula, cask, mas 앱을 각각 한 줄씩 파싱해서 설치했다. 이 방식은:
  - "#" 주석과 빈 줄을 직접 파싱해서 걸러내야 했고 (line=${line%%#*},
    xargs trim, [[ -z ]] continue 등)
  - 이미 설치된 패키지를 skip하고 report에 남기는 로직도 brew/cask/mas
    타입별로 직접 만들어야 했고
  - report도 [brew]/[cask]/[mas] 그룹으로 직접 나눠서 만들어야 했다.

한 번은 반대로 이 세 파일 + install_from_list()를 brew bundle로
바꾸는 걸 검토했다가, install_pkg()가 설치 후 conf/<name>/run.sh
(dotfile symlink 등)까지 실행해주는데 brew bundle은 그 단계를 전혀
모른다는 이유로 보류한 적이 있다.

이후 다시 논의한 결과: 그 dotfile symlink 재실행은 어차피 수동으로
한 번씩 해도 되는 정도의 일이라 판단해서, brew bundle 방식으로
완전히 전환하기로 결정했다. 대신 아래 항목은 감수하기로 한 트레이드
오프다.

  ⚠ conf/<name>/run.sh 가 더 이상 first_setup_mac.sh 실행마다
    자동으로 재적용되지 않는다. 특정 패키지의 dotfile을 다시 강제로
    symlink하고 싶으면 해당 conf/<name>/run.sh (또는
    OS_specific/Mac/<name>/run.sh)를 직접 실행해야 한다.

  ⚠ mas 자체를 사전에 체크/설치하는 코드도 이제 없다. 대신
    `brew bundle dump`가 mas를 이미 brew formula로 설치해 둔 머신에서
    실행되면 Brewfile 안에 자동으로 `brew "mas"` 줄이 포함되고,
    brew bundle이 taps/brew를 mas 항목보다 먼저 처리하기 때문에
    보통은 문제없이 동작한다. Brewfile에 `brew "mas"`가 빠진 채
    mas 항목만 있는 경우는 예외적인 상황이라 별도로 다루지 않는다.

packages_cli.txt / packages_gui.txt / packages_mas.txt는 더 이상
스크립트에서 쓰이지 않는다. 삭제하지 않고 참고용으로
mac/_obsolete/ 아래로 옮겨뒀다.

--------------------------------------------------------------------
Brewfile의 주석/공백 처리 (참고)
--------------------------------------------------------------------

Brewfile은 Homebrew Bundle이 읽는 Ruby DSL이라서 Ruby 문법을 그대로
따른다.
  - "#"로 시작하면 그 줄 끝까지 주석 처리된다 (줄 전체 주석, 인라인
    주석 둘 다 가능).
  - 빈 줄은 Ruby 파서가 그냥 무시하므로 자유롭게 넣어서 섹션을
    구분해도 된다.
즉 packages_cli.txt 때처럼 line=${line%%#*} / xargs trim /
[[ -z "$line" ]] && continue 같은 코드를 직접 짤 필요가 없다 -
brew bundle이 Brewfile을 파싱할 때 전부 알아서 처리해준다. 이게
이번 전환에서 스크립트가 훨씬 단순해진 핵심 이유다.
