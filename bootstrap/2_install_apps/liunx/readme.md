# fd

2. 왜 이 설정(run.sh)이 필요한가?
--------------------------------------------------
- macOS (Homebrew):
  `brew install fd`로 설치하면 바이너리가 `/opt/homebrew/bin/fd`로 생성되어 추가 설정이 필요 없습니다.

- Linux (Ubuntu/Debian apt):
  전통적인 유닉스 플로피 디스크 포맷 유틸리티(`fdutils`의 `fd`)와의 이름 충돌을 피하기 위해,
  apt 패키지에서는 실행 파일 이름을 강제로 `fdfind`로 변경하여 배포합니다.
  따라서 `fd`라는 명령어로 호출하기 위해서는 `~/.local/bin/fd`로 심볼릭 링크를 걸어주어야 합니다.