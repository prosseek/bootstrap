# Cork Build Script

GitHub에서 Cork 소스코드를 자동으로 가져와서 컴파일하는 스크립트입니다.

Cork는 **Tuist**를 사용하는 프로젝트입니다. Tuist는 Xcode 프로젝트 파일을 생성하는 도구입니다.

## 사전 요구사항

### 1. Xcode Command Line Tools 설치

```bash
xcode-select --install
```

### 2. Xcode 라이선스 동의 (필요시)

```bash
sudo xcodebuild -license accept
```

### 3. Tuist 설치 (자동으로 설치됨)

스크립트가 자동으로 Tuist를 설치하지만, 수동으로 설치하려면:

```bash
brew install --cask tuist
```

## 사용 방법

```bash
# 디렉토리 이동
cd /Users/chos5/github/prosseek/setup/Mac/cork

# 스크립트 실행 권한 부여
chmod +x build-cork.sh

# 스크립트 실행
./build-cork.sh
```

## 스크립트가 하는 일

1. **환경 체크**
   - Xcode Command Line Tools 확인
   - git 확인

2. **Tuist 설치**
   - Tuist가 없으면 자동으로 설치

3. **소스코드 다운로드**
   - GitHub에서 Cork 클론
   - 또는 기존 저장소 업데이트

4. **Xcode 프로젝트 생성**
   - Tuist로 Cork.xcodeproj 또는 Cork.xcworkspace 생성

5. **컴파일**
   - xcodebuild로 Release 빌드
   - ~/temp/cork-build/DerivedData에서 작업

6. **설치**
   - 빌드된 Cork.app을 /Applications로 복사
   - 선택적으로 빌드 파일 정리

## 빌드 위치

- **소스코드**: `~/temp/cork-build/Cork`
- **생성된 프로젝트**: `~/temp/cork-build/Cork/Cork.xcworkspace` (또는 .xcodeproj)
- **빌드 산출물**: `~/temp/cork-build/DerivedData`
- **최종 설치**: `/Applications/Cork.app`

## Tuist란?

[Tuist](https://tuist.io/)는 Xcode 프로젝트를 코드로 관리하는 도구입니다.

- **Project.swift**: Xcode 프로젝트 설정을 코드로 정의
- **tuist generate**: 실제 .xcodeproj/.xcworkspace 파일 생성

Cork는 Tuist를 사용하여 프로젝트를 관리하므로, 빌드하기 전에 먼저 `tuist generate`로 Xcode 프로젝트를 생성해야 합니다.

## 문제 해결

### "xcrun: error: invalid active developer path"

```bash
xcode-select --install
```

### "Agreeing to the Xcode/iOS license"

```bash
sudo xcodebuild -license accept
```

### "tuist: command not found"

```bash
brew install --cask tuist
```

### 빌드 실패

1. Xcode가 설치되어 있는지 확인
   ```bash
   xcodebuild -version
   ```

2. Tuist 버전 확인
   ```bash
   tuist version
   ```

3. Cork의 README.md 확인
   ```bash
   cd ~/temp/cork-build/Cork
   cat README.md
   ```

## 보안 경고

빌드 후 처음 실행 시:

1. **"Cork.app can't be opened"** 에러가 나면:
   - System Settings > Privacy & Security
   - "Open Anyway" 클릭

2. 또는 터미널에서:
   ```bash
   xattr -cr /Applications/Cork.app
   ```

## 업데이트

Cork를 최신 버전으로 업데이트:

```bash
# 스크립트를 다시 실행하면 자동으로 업데이트됨
./build-cork.sh
```

## 장점

- ✅ 완전 무료 (데모 제한 없음)
- ✅ 최신 버전 사용 가능
- ✅ 소스코드 직접 확인 가능
- ✅ 커스터마이징 가능

## 단점

- ❌ 컴파일 시간 소요 (5-10분, Tuist 생성 포함)
- ❌ Xcode + Tuist 설치 필요
- ❌ 자동 업데이트 없음 (수동으로 스크립트 재실행)

## 대안

컴파일이 번거로우면:

```bash
# Cakebrew (무료)
brew install --cask cakebrew

# 또는 터미널 사용
brew leaves
brew list --cask
```

## 참고 링크

- Cork GitHub: https://github.com/buresdv/Cork
- Tuist 공식 사이트: https://tuist.io/
- Tuist 문서: https://docs.tuist.io/
