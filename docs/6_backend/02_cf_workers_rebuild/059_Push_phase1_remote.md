---
id: "059"
type: push
title: "Phase 1 Remote Push"
created: 2026-05-02
traces_brief: "021"
traces_qualify: "058"
cycle: 10
phase_scope: "phase-1-conversion"
status: completed
confidence: high
summary: >
  Phase 1 conversion 작업물 GitHub origin/main에 push 완료. push 직전 root node_modules
  contamination 발견 → git filter-repo로 history 재작성 후 force-with-lease push. node_modules는
  GitHub remote에 단 한 번도 올라가지 않음. .git 크기 139M → 54M (60% 감소).
keywords: [push, remote, github, filter-repo, node_modules, history-rewrite]
---

# Phase 1 Remote Push

## Verdict

**SUCCESS** — `fe897bf..a381002 main -> main`. branch tracking 설정 완료.

## Pre-Push Issue Discovery

push 직전 점검에서 commit `6da3671 feat: apps/workers — 8519개 파일 자동 커밋`이 root `node_modules/` 디렉토리(acorn, drizzle-kit, esbuild, miniflare 등)를 포함했음을 발견.

원인:
- root `.gitignore`에 `apps/workers/node_modules/`만 등록되어 있고 root `node_modules/` 패턴이 누락
- npm workspace hoisting으로 root에 node_modules 디렉토리 생성됨
- auto-commit hook이 8519 파일 일괄 커밋

## Resolution Path — Option A (history rewrite)

대안 검토:
- A: history rewrite (filter-repo) — node_modules가 GitHub에 단 한 번도 안 올라감
- B: untrack commit + push — node_modules가 history에 영구 잔존
- C: push 보류

선택: **A** (사용자 결정). 첫 push + 단독 작업자 환경이라 history rewrite 위험 거의 없음.

## Execution Steps

1. `brew install git-filter-repo` — 도구 설치
2. backup branch `backup-before-filter` 생성
3. 초기 시도: `git filter-repo --path apps/workers/node_modules --invert-paths --force`
   - 결과: commit hash 변경 없음 — path 오인 발견 (실제 commit된 path는 root `node_modules/`)
4. root `.gitignore`에 `node_modules/` 추가 + commit
5. 정정 명령: `git filter-repo --path node_modules --invert-paths --force`
   - 188 commits 재작성, hash 모두 변경 (e.g. 63d2d48 → a381002)
6. remote 재추가 (`git remote add origin https://github.com/kampikrein/personality.git`)
7. `git fetch origin` — origin/main 상태 확인 (filter-repo로 history 분기)
8. `git push -u origin main --force-with-lease` — 안전 force push
9. branch tracking 재설정

## Verification

| 항목 | 결과 |
|------|------|
| HEAD에 node_modules 존재 | 없음 (`git ls-tree` 빈 출력) |
| 모든 ref에 node_modules path | 없음 (`git log --all --name-only \| grep node_modules` 0 hit) |
| .git 크기 | 139M → 54M (60% 감소) |
| origin/main 동기화 | a381002 (push 완료) |
| backup branch | `backup-before-filter` 유지 (filter-repo 함께 rewrite되어 동일 hash) |

## Phase 2 Carryover (push 관련)

- backup branch 정리 (Phase 2 진입 시 또는 즉시) — `git branch -D backup-before-filter`
- root `.gitignore`의 `node_modules/` 패턴 유지 검증 (향후 자동 commit hook contamination 방지)
- GitHub Actions secret 등록 (Brief 021 § Out of Scope 5 — Phase 2 cutover)
- `apps/workers/.dev.vars` 절대 commit 금지 — 이미 `.gitignore`에 등록되어 있으나 Phase 2 secret 처리 시 재확인

## References

- Brief 021 (Phase 1 sub-anchor): `021_Brief_conversion_phase1.md`
- Qualify 058: `058_Qualify_phase1_production.md` (GO-WITH-CONDITIONS)
- Eval 057: `057_Eval_phase1_overall.md` (SUFFICIENT)
- 사용자 결정 기록: 옵션 A 선택 (history rewrite via filter-repo)
