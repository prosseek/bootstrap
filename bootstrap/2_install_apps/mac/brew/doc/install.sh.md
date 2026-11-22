# `install.sh` 동작 설명

`install.sh`는 `brewfile/<카테고리>.brewfile` 하나를 카테고리 단위로 읽어 Homebrew 항목을 설치한다.
보통 `run.sh`가 환경을 준비한 뒤 호출하지만, 단독으로 실행해도 된다.

```bash
bash install.sh essential   # essential.brewfile 만
bash install.sh             # 인자 없음: brewfile/*.brewfile 전부
```

카테고리를 추가하려면 `brewfile/<이름>.brewfile`을 만들면 된다. 스크립트는 바꾸지 않는다.

## 한 줄씩 처리하는 이유

`brew bundle`을 파일 전체에 실행하면 무엇을 건너뛰고 무엇을 설치했는지 알기 어렵다.
그래서 Brewfile의 각 줄을 임시 Brewfile에 하나씩 넣어 `brew`에 두 번 넘긴다.

1. `brew bundle check --file=한줄` — 종료 코드 0이면 이미 설치됨 → `skip`
2. `brew bundle --file=한줄` — 설치

줄은 파일 순서대로 처리하므로 `tap` 줄은 그 tap이 필요한 항목보다 앞에 둔다.
빈 줄과 `#`으로 시작하는 주석 줄은 무시한다.

## 출력

| 표시 | 의미 |
|------|------|
| `skip` | brew로 이미 설치됨, 아무것도 안 함 |
| `exists` | cask의 앱이 이미 `/Applications`에 있음(수동 설치). 건드리지 않음 |
| `installed` | 없어서 지금 설치함 |
| `FAIL` | 없었고 설치도 실패함 |

카테고리마다 `OK`(FAIL 없음) 또는 `FAIL`이 붙고, 마지막에 요약 표가 출력된다.
한 앱이 실패해도 나머지는 계속 진행하며(`set -e` 미사용), 실패는 마지막에 보고한다.
다시 실행해도 안전하다. 설치된 것은 건너뛴다.

## `exists` 판정 (`cask_app_exists`)

`brew bundle check`는 brew가 직접 설치한 것만 안다. 직접 설치한 앱은 "미설치"로 보이고,
`brew install --cask`는 `It seems there is already an App at /Applications/...`라며 멈춘다.
그래서 cask를 설치하기 전에 `brew info --cask --json=v2`로 cask가 담고 있는 `.app` 이름을 알아내
디스크에 있는지 확인한다. (`APP_DIR`로 위치를 바꿀 수 있고, JSON을 읽을 때만 `python3`을 쓴다.)

## 마지막 줄이 설치되지 않던 문제 (수정됨)

### 증상

Brewfile 맨 끝 줄 뒤에 줄바꿈(빈 줄)이 없으면 그 마지막 줄이 설치되지 않았다.
예: `essential.brewfile`의 끝이 `cask "iina"` 였을 때 `iina`만 출력도 설치도 되지 않고 요약은 `OK`로 끝났다.

### 원인

`while IFS= read -r line` 루프에서 마지막 줄에 개행이 없으면 `read`가 `line`에 값을 채우고도
종료 코드 1(EOF)을 반환한다. 루프가 그 값을 처리하기 전에 끝나 버린다.

### 수정

```bash
while IFS= read -r line || [ -n "$line" ]; do
```

`read`가 실패해도 `line`에 내용이 남아 있으면 한 번 더 처리한다. 이제 Brewfile 끝에
빈 줄을 따로 넣지 않아도 마지막 줄까지 처리된다.
