---
name: commit-creator
description: 사용자가 커밋을 요청할 경우 실행. 현재 변경사항(staged + unstaged)을 의미 단위로 분할해 commit한다. 변경이 여러 의미로 쪼개져 있으면 여러 번 commit. 기존 commit에 합치는 게 더 자연스러우면 rebase로 squash. 매 commit 끝에서 컴파일 통과를 보장.
---

# commit-creator

현재 working tree의 변경사항을 의미가 살아있는 최소 단위로 commit한다. PR 리뷰어가 commit 순서를 따라가며 작업 흐름을 유추할 수 있게 만드는 것이 목표.
커밋 메시지를 작성할 때의 대전제는 리뷰어가 이해하기 편하도록 하는 것. - 맥락을 알기 힘든 단어, 표현 사용은 지양

## 작업 흐름

1. **현재 상태 파악**
   - `git status` / `git diff` / `git diff --staged` / `git log --oneline -10`로 변경량과 이전 흐름 확인.
   - 변경된 파일들을 의미 단위로 그룹화 (한 묶음 = 한 commit).

2. **의미 분할 검토**
   - "한 commit이 한 의미"를 만족하는지 본인이 판단.
   - 의미가 모호하거나 분할 방법이 여러 가지면 **`AskUserQuestion`으로 사용자에게 확인**. 예: "변경이 X(파일 A·B)와 Y(파일 C)로 보이는데, 분리하시겠어요?"

3. **기존 commit과 합칠지 결정**
   - 이번 변경이 **직전 commit의 의도와 동일**하다면 (예: 같은 작업의 후속 마무리) `git commit --amend`.
   - **더 이전 commit과 동일 의도**라면 `git rebase -i`로 fixup/squash. 단 **commit 사이에 의존성이 있으면 합치지 말 것** — 중간 commit이 동작에 의존한다면 별개 commit 유지.
   - 합칠지 모호하면 사용자에게 질문.

4. **각 commit 만들기**
   - 한 의미 단위씩 stage → commit.
   - 메시지 형식:
     ```
     scope: 한 줄 요약 (50자 내외)

     - 변경사항 1
     - 변경사항 2
     - 변경사항 3
     ```
   - scope는 저장소 기존 패턴 따라가기 (`chore(tuist)`, `refactor(memo)`, `fix(coredata)`, `ci`, `docs`, `test` 등).
   - description은 줄글 X, bullet list로 변경사항 나열.
   - AI 작업 시 `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>` trailer 추가.

5. **컴파일 검증**
   - 모든 commit이 끝난 시점에 컴파일 통과해야 함.
   - 검증 방법이 프로젝트마다 다르므로 명시되지 않았으면 사용자에게 질문 (예: "컴파일 검증으로 `xcodebuild build`를 돌릴까요?")
   - NoteCard의 경우: `tuist generate --no-open && xcodebuild build -workspace NoteCard.xcworkspace -scheme NoteCard -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`.

6. **사용자 확인 요청**
   - 모든 commit 후 `git log --oneline -<N>`으로 결과 보고.
   - push 여부는 묻지 말 것 — push는 사용자 직접.

## 모호함 해소 — `AskUserQuestion` 사용 시점

- 변경 분할 방식이 둘 이상 합리적일 때
- 어떤 기존 commit과 합칠지 모호할 때
- commit 메시지의 scope나 요약이 명확하지 않을 때
- 컴파일 검증 명령이 사전에 합의되지 않았을 때
- working tree에 의도되지 않은 변경(예: 임시 디버그 코드, 우연히 변경된 파일)이 있을 때

## 금지 사항

- 줄글로 장황한 commit description 작성 금지. 항상 bullet list.
- 의미가 다른 변경을 한 commit에 묶지 말 것.
- 사용자 명시 없이 force push 또는 published commit amend 금지.
- 컴파일 깨진 상태로 commit 종료 금지.
- `--no-verify`로 pre-commit hook 우회 금지.
