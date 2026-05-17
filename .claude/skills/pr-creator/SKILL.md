---
name: pr-creator
description: 사용자가 PR을 생성해달라고 부탁한 경우에 실행. 현재 브랜치를 main에 머지하기 위한 PR을 생성. push되지 않았으면 push 후 PR 작성. PR은 배경 / 변경사항 / 테스트 방법 / 리뷰 노트(선택) / 스크린샷(선택) 섹션으로 구성하며 핵심만 간결하게.
---

# pr-creator

현재 작업 브랜치를 main에 머지하기 위한 PR을 만든다. 본문은 장황한 줄글 대신 핵심만 bullet list로 나열.
PR을 작성할 때의 대전제는 리뷰어가 이해하기 편하도록 하는 것. - 리뷰어가 맥락을 알기 힘든 단어, 표현 사용은 지양하되, 필요한 경우에는 용어를 풀어서 설명할 것.

## 작업 흐름

1. **현재 브랜치 확인**
   - `git branch --show-current`로 작업 브랜치 확인. main이면 PR 생성 거부 (어디로 머지할지 모호).
   - `git log main..HEAD --oneline`로 포함될 commit 목록 확인.
   - working tree clean인지 `git status`로 확인 (uncommitted 변경 있으면 commit 먼저 또는 사용자에게 확인).

2. **Push 여부 확인**
   - `git status -sb` 또는 `git rev-parse --abbrev-ref --symbolic-full-name @{u}`로 upstream 여부 확인.
   - upstream 없거나 ahead 상태면 `git push -u origin <branch>`로 push.

3. **PR 본문 구성**
   - 아래 템플릿 사용. 빈 섹션은 생략.
   - 리뷰 노트 / 스크린샷은 선택. 해당 변경이 있을 때만 포함.
   - 본문은 줄글 X, 항목별 bullet list.

4. **`gh pr create` 호출**
   - `--base main --head <current_branch> --title "..." --body "$(cat <<'EOF' ... EOF)"`
   - 생성된 PR URL 출력으로 보고.

## PR 템플릿

```markdown
## 배경
(변경의 동기 한두 줄. 이슈 / 컨텍스트가 있으면 링크. 자명하면 생략.)

## 변경사항
- 변경사항은 markdown 형식의 bullet list 로 작성.
- 계층 구조가 있는 정보는 bullet으로 계층 표시
- 변경된 사항을 적음. 이 항목에서 상세한 구현 방법이나 성과를 이야기하지 않음.

## 테스트 방법
- 단계 1 (명령 또는 동작 확인 절차)
- 단계 2

## 리뷰 노트
- 리뷰어가 특별히 신경써야 할 부분
- 의도된 깨짐 또는 후속 작업 예고

## 스크린샷
| Before | After |
|---|---|
| 이미지 | 이미지 |
```

## 모호함 해소 — `AskUserQuestion` 사용 시점

- PR 제목 / 배경 문구가 모호할 때 (commit 메시지만으로 추정 불가)
- 테스트 방법이 자명하지 않을 때 (수동 QA 단계 / 자동 테스트 명령 무엇을 적을지)
- 리뷰 노트가 필요한 변경인지 모호할 때 (위험 요인이 있는지)
- 스크린샷이 필요한 UI 변경인지 모호할 때 (있는데 누락하면 리뷰 어려움)
- 머지 대상이 main이 아닐 때 (예: release 브랜치 머지)

## 금지 사항

- 줄글로 장황한 본문 작성 금지. 항상 bullet list.
- 빈 섹션을 그대로 두지 말 것 (해당 없으면 섹션 자체 생략).
- 사용자 확인 없이 push --force 금지.
- main에서 PR 생성 금지 (어디로 머지할지 알 수 없음).
- commit / push 도중 컴파일 깨짐 상태로 PR 만들지 말 것.
