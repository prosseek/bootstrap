# mas 앱 중 brew cask로 옮길 수 있는 것

작성: 2026-11-15. cask 이름은 기억에 의존한 **후보**이다. 아래 "확인 방법"으로 실제 존재 여부를 확인한 뒤 옮긴다.

## 1. 기준: mas와 cask 중 무엇을 쓰나

기본은 **cask**, App Store에만 있거나 App Store로 이미 구매한 앱은 **mas**. 같은 앱을 둘 다 설치하지 않는다.

| | brew cask | mas (App Store) |
|---|---|---|
| 로그인 | 필요 없음 | Apple ID 로그인 필요, 구매 내역 필요 |
| 업데이트 | 앱 자체 또는 `brew upgrade --cask` | App Store 자동 |
| 새 버전 | 빠름 | 심사 때문에 늦을 수 있음 |
| 샌드박스 | 보통 없음 (기능 제한 적음) | 필수 (일부 기능 빠짐) |
| 라이선스 | 개발자 사이트 키 | Apple ID에 묶임 |
| 새 컴퓨터 설치 | Brewfile 한 줄 | 로그인 후 `mas` |

같은 앱을 둘 다 설치하면 안 되는 이유: `/Applications`의 이름이 겹쳐 설치가 막히고, 설정 위치가 달라
(`~/Library/Containers/` 대 `~/Library/Application Support/`) 판을 바꾸면 설정이 따라오지 않으며,
유료 앱은 App Store 구매와 개발자 라이선스가 호환되지 않는 경우가 많다.

## 2. 후보: cask가 있을 가능성이 높은 앱

| 분류 | App Store 앱 | cask |
|---|---|---|
| 편집/노트 | iA Writer | `ia-writer` |
| | CotEditor | `coteditor` |
| | Marked 2 | `marked` |
| | Craft | `craft` |
| | Bear | `bear` |
| | Day One | `day-one` |
| | Drafts | `drafts` |
| | Goodnotes | `goodnotes` |
| | Simplenote | `simplenote` |
| | UpNote | `upnote` |
| | reMarkable | `remarkable` |
| 생산성 | Things | `things` |
| | Xmind | `xmind` |
| | Readest | `readest` |
| Microsoft | Word, Excel, PowerPoint | `microsoft-word`, `microsoft-excel`, `microsoft-powerpoint` |
| | OneDrive | `onedrive` |
| 유틸리티 | Keka | `keka` |
| | Maccy | `maccy` |
| | Yoink | `yoink` |
| | DaisyDisk | `daisydisk` |
| | GrandPerspective | `grandperspective` |
| | Find Any File | `find-any-file` |
| | BetterSnapTool | `bettersnaptool` |
| | Commander One | `commander-one` |
| | Dropzone | `dropzone` |
| | Hidden Bar | `hiddenbar` |
| | TextSniper | `textsniper` |
| 기타 | Windows App | `windows-app` |
| | KakaoTalk | `kakaotalk` |

잘 모르겠는 앱(확인 필요): Kindle, SideNotes, Supernote Partner, Synalyze It!, SnippetsLab, FastestVPN, Amphetamine

cask가 없을 앱(App Store 전용으로 보임): Xcode, Keynote, Pages, Numbers, Grammarly for Safari, MagicGlance,
Folder Preview, New File Menu, Peek, Chronicle Pro, Disk Doctor 등 나머지.

## 3. 확인 방법 (brew가 있는 컴퓨터에서)

```zsh
for c in ia-writer coteditor marked craft bear day-one drafts goodnotes simplenote upnote remarkable \
         things xmind readest microsoft-word microsoft-excel microsoft-powerpoint onedrive \
         keka maccy yoink daisydisk grandperspective find-any-file bettersnaptool commander-one \
         dropzone hiddenbar textsniper windows-app kakaotalk kindle sidenotes snippetslab; do
  brew info --cask "$c" >/dev/null 2>&1 && echo "OK    $c" || echo "NONE  $c"
done
```

`OK`여도 deprecated나 disabled일 수 있다 (예: `cakebrew`는 deprecated이고 설치가 실패했다).
옮기기 전에 `brew install --cask <이름>`을 한 번 실행해 본다.

## 4. 옮기기 전에 확인할 것

- **유료 앱**(Things, Bear, Day One, Craft, Drafts, Goodnotes, Xmind, Dropzone, BetterSnapTool, Commander One 등):
  App Store 구매가 개발자 사이트 판에 이어지지 않는 경우가 많다. 이미 구매했다면 mas에 둔다.
- **무료이거나 개발자 라이선스가 있는 앱**(Keka, Maccy, Hidden Bar, CotEditor, Microsoft 앱, OneDrive,
  Windows App, KakaoTalk 등)이 옮기기 쉽다. Keka와 Maccy의 App Store판은 유료 후원판일 수 있다.
- 설정이 따라오지 않는다 (샌드박스 컨테이너에서 Application Support로 바뀜). 필요하면 설정을 내보낸다.
- `masfile/`에서 같은 앱이 여러 파일에 중복돼 있다(Craft, SnippetsLab, reMarkable, Supernote Partner,
  Yoink, Keka, TextSniper, MagicGlance 등). 옮기든 남기든 **한 군데에만** 둔다.

## 5. 옮기는 순서

1. 3번 명령으로 `OK`인 앱을 고른다.
2. 무료이거나 App Store 구매가 없는 앱만 정한다.
3. `brew/brewfile/Brewfile.*`에 `cask "<이름>"`을 추가하고, `mas/masfile/Masfile.*`에서 그 줄을 지운다.
4. Brewfile 주석에 한 줄 이유를 남긴다 (예: `# was mas: free, no sandbox`).
5. 이미 설치된 앱을 바꾸는 경우: 앱 설정을 백업하고, App Store판을 지운 뒤 `brew install --cask`로 설치한다.
