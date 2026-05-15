# AGENTS.md

NoteCard는 Tuist 기반 모듈러 iOS 앱이다. 이 문서는 AI agent가 코드를 변경하기 전 반드시 확인해야 할 핵심 사항을 정리한다. 본문에서 명령은 모두 저장소 루트(`/Users/kimminsung/development/NoteCard`)에서 실행하는 기준이다.

## Stack

- UIKit + Combine + Core Data + Swift 5
- iOS 15.0 deployment target
- Tuist 4.x (modular project generation)
- 외부 의존성: Wisp 1.10.1 (검색 UI 라이브러리, SPM via Tuist Dependencies)
- 분석/로깅: 없음 (Analytics 모듈은 NoOp placeholder만 마련)

## Module structure

`Projects/` 하위 폴더가 곧 레이어다. 모듈 그래프는 단방향이며, 역방향 import는 컴파일 에러로 차단된다.

```
App (NoteCard, NoteCard-Eng)
 ├─ Domain   ← Data
 ├─ Domain, Data, DesignSystem, Shared, AnalyticsInterface
 ├─ Core/DesignSystem  → Shared
 ├─ Core/Shared
 ├─ Core/AnalyticsInterface
 └─ Core/AnalyticsImpl → AnalyticsInterface
```

- Repository **프로토콜은 Domain**이 소유하고 **구현은 Data**가 제공 (의존성 역전)
- 횡단 관심사(DesignSystem / Shared / Analytics)는 `Core/` 아래로
- Presentation은 현재 App 타겟 안에 그대로 (별도 Feature 모듈 분할은 후속 작업)
- 새 모듈 추가 시 `Tuist/ProjectDescriptionHelpers/ModulePaths.swift`의 `Module` enum과 `Layer` enum에 등록 필요

## Dev environment setup

```bash
mise install                              # 또는 brew install tuist (Tuist 4.x 필요)
tuist install                              # SPM 의존성 fetch
tuist generate --no-open                   # NoteCard.xcworkspace 생성
open NoteCard.xcworkspace                  # Xcode 열기
```

- `.xcodeproj` / `.xcworkspace`는 generated artifact라 git에 commit하지 않는다 (`.gitignore`에 포함됨). 직접 편집 금지 — 항상 `Project.swift` 수정 후 `tuist generate`.
- `Configs/Version.xcconfig`에 `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`이 있다. fastlane이 정규식 치환으로 편집하므로 형식(`KEY = value`)을 유지할 것.

## Build & test

```bash
# 평상시 개발 빌드 (한국어 데이터 sandbox)
xcodebuild build -workspace NoteCard.xcworkspace \
    -scheme NoteCard -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 영어 스크린샷용 빌드 (별도 bundle id로 시뮬레이터에 추가 설치됨)
xcodebuild build -workspace NoteCard.xcworkspace \
    -scheme NoteCard-Eng -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 단위 테스트 (Domain / Shared / NoteCardTests)
xcodebuild test -workspace NoteCard.xcworkspace \
    -scheme NoteCard -configuration Debug \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

- 두 App 타겟이 같은 sources / resources를 공유하고 **bundle id만 다르다** (`com.minsung.NoteCard` vs `com.minsung.NoteCard.eng`). 시뮬레이터에 두 앱이 별개로 설치되어 각자 Core Data sandbox를 가진다.
- Configuration은 `Debug` / `Release` 2개뿐. Display name은 NoteCard target Debug=`NoteCard(Dev)`, NoteCard target Release=`NoteCard`, NoteCard-Eng target=`NoteCard-Eng`.

## Core Data ⚠

Core Data는 가장 위험한 영역이다. 다음을 어기면 사용자 데이터 손실로 이어진다.

- **Bundle 접근**: `Bundle.main`이나 `Bundle(for: Self.self)`로 모델을 찾으면 안 된다 (staticFramework에서 main bundle을 반환). 반드시 `DataResources.bundle`(= `Bundle.module`) 사용. 참고: `Projects/Data/Sources/CoreData/CoreDataStack.swift`.
- **매핑 모델**: `.xcdatamodeld`와 `.xcmappingmodel`은 **같은 번들**에 함께 있어야 NSMigrationManager가 자동 검색한다. `Projects/Data/Project.swift`의 resources glob에 두 패턴 모두 포함되어 있음 — 절대 빼지 말 것.
- **`@objc(EntityName)` 어노테이션**: 모든 NSManagedObject 서브클래스에 부착되어 있다. 모듈명이 바뀌어도 Obj-C 런타임 클래스명이 고정되어 기존 .sqlite의 클래스 매핑을 유지. 새 entity 추가 시 동일하게 부착.
- **Migration**: Lightweight + Heavyweight(매핑 모델) 혼합 사용 중. 모델 변경 시 `Projects/Data/Tests/MigrationTests.swift`에 회귀 시나리오 추가.
- **현재 컨테이너**: `NoteCardCoreData` (active). `CardMemoCoreData`는 마이그레이션 source용 잔재 — 삭제하지 말 것.

## Naming gotchas

- ObjC runtime의 `Category` typedef와 충돌하므로 도메인 모델 `Category`는 호출부에서 **`Domain.Category`로 명시**한다. 새 코드에도 동일 규칙.
- Localization 호출은 `"key".localized()` 형태. 기본 bundle이 `SharedResources.bundle`이므로 다른 모듈에 자체 xcstrings를 두면 `bundle:` 인자를 명시 전달.

## Code conventions

- 모든 cross-module API는 명시적 `public`. 모듈 내부 detail은 `internal`(기본) 또는 `private` 유지.
- protocol 멤버에는 `public` 모디파이어를 붙이지 않는다 (Swift 컴파일러가 거부).
- protocol conformance를 가진 extension(`extension X: SomeProtocol`)에도 `public` 모디파이어 금지. 멤버에 개별 `public`을 붙일 것.
- `public class` 안의 `override` 메서드도 `public` 명시 (Swift 규칙).
- ViewController 등 App 타겟 내부 코드는 internal로 충분 (cross-module 노출 불필요).

## Commit / PR conventions

- 의미 단위로 분할 commit. 한 commit이 끝난 시점의 코드는 컴파일 통과 보장.
- 메시지 형식: `scope: 한 줄 요약` (예: `chore(tuist): ...`, `refactor(memo): ...`, `fix(coredata): ...`, `ci: ...`). 본문은 변경사항 bullet list. 줄글 장황 설명 X.
- Co-authored-by trailer는 AI 어시스턴트로 작업했을 때만 추가.
- PR base는 `main`. 본인이 작업한 브랜치는 push 후 직접 확인하고 PR 생성.
- Push는 사용자 확인 후 직접. 자동 push 금지.

## fastlane

```bash
bundle exec fastlane bump_version type:minor   # patch / minor / major
bundle exec fastlane bump_build
bundle exec fastlane verify_archive            # archive만, upload X
bundle exec fastlane beta                      # archive + TestFlight upload
```

- `bump_version`은 `Configs/Version.xcconfig`만 편집하고 자동 commit한다 (release 브랜치에서만 실행).
- bundler 2.5.11 필요. ruby 3.3.3 (rbenv) 환경에서 동작.
- CI에서는 `release.yml`이 자동 호출. 일반 push는 `ci.yml`(build + test)만 실행.

## Deferred / known limitations

- **Feature 모듈 분할**: Asset Symbol cross-module access 처리(`ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS_ACCESS_LEVEL = public`) 후 별도 작업으로 진행 예정.
- **Core Data 회귀 테스트**: v3 fixture `.sqlite` 미확보로 `MigrationTests`가 `XCTSkip` 상태. 모델 변경 시 사용자 시뮬레이터에서 fixture 추출 후 활성화.
