brew list --cask > my-apps.txt
cat my-apps.txt | xargs brew install --cask
grep -v '^#' my-apps.txt | grep -v '^$' | xargs brew install --cask
grep -Ev '^(#|$)' my-apps.txt | xargs brew install --cask

# All the forumla
#brew list --formula > my-cli-tools.txt
# Only leaves
brew leaves > my-cli-tools.txt
grep -Ev '^(#|$)' my-cli-tools.txt | xargs brew install

# TAP
# 1. Tap 백업
brew tap > taps.txt

# 2. Tap 복원 (저장소만 추가)
grep -Ev '^(#|$)' taps.txt | xargs -L1 brew tap

# 3. 그 다음에 패키지 설치
grep -Ev '^(#|$)' my-cli-tools.txt | xargs brew install
grep -Ev '^(#|$)' my-apps.txt | xargs brew install --cask

---

## Github

sudo mv /usr/local/bin/gh /usr/local/bin/gh-old
brew install gh
brew install --cask dbeaver-community