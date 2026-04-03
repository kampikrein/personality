---
id: "001"
type: scope
title: "하이브리드 모노레포 구조 전환"
created: 2026-03-15
complexity: simple
research_needed: false
research_reason: "git mv, Flutter scaffold, Makefile 모두 표준 패턴. 조사 불필요."
auto_run: false
intent: >
  Rails 백엔드를 server/로, Flutter 모바일을 mobile/로 분리하는
  하이브리드 모노레포 구조로 전환. 유저 관리는 Rails 백엔드에서 공유하고,
  personality(웹) + 타로(모바일) 두 서비스의 코드베이스를 한 저장소에서 관리.
summary: >
  단일 영역(프로젝트 구조 재편). Rails 파일을 server/로 git mv,
  mobile/ Flutter scaffold 생성, shared/ placeholder, 루트에 Makefile/docker-compose.yml 배치.
  docs/와 .claude/는 루트 유지.
keywords: [monorepo, rails, flutter, hybrid, restructure]
---

# 하이브리드 모노레포 구조 전환

## 작업 목표

**목표**: personality 프로젝트를 Rails + Flutter 하이브리드 모노레포로 재구성
**제약**: 기존 Rails 앱 기능 무손상, git 히스토리 보존 (git mv 사용)
**성공 기준**: 구조 전환 후 `cd server && bundle exec rails s` 정상 동작

## 접근 방향

접근법 3 (하이브리드) 채택. 역할 기반 디렉토리명 (`server/`, `mobile/`)으로 직관성 확보.
대안 1(Rails 루트 유지)은 루트가 지저분, 대안 2(`apps/`)는 추상적 — 둘 다 기각.

## Research 판단
- **판단**: 불필요
- **근거**: git mv, Flutter scaffold, Makefile 모두 표준 패턴. 기존 코드 내부 변경 없음.
- **파이프라인**: S → P → I(V)

## 설계

### 최종 디렉토리 구조

```
personality/                        ← 모노레포 루트
├── server/                         ← Rails 백엔드 (기존 코드 전체)
│   ├── app/
│   ├── bin/
│   ├── config/
│   ├── db/
│   ├── lib/
│   ├── spec/
│   ├── Gemfile
│   ├── Dockerfile
│   ├── Procfile.dev
│   └── ...
├── mobile/                         ← Flutter 앱 (신규 scaffold)
│   ├── lib/
│   ├── android/
│   ├── ios/
│   ├── test/
│   └── pubspec.yaml
├── shared/                         ← API 계약 (placeholder)
│   └── api-schema/
├── docs/                           ← 공유 문서 (현재 위치 유지)
├── .claude/                        ← AI 에이전트 설정 (현재 위치 유지)
├── .github/                        ← CI/CD (현재 위치 유지, 경로 업데이트)
├── hooks/                          ← OpenCode hooks (현재 위치 유지)
├── CLAUDE.md                       ← 프로젝트 지침 (내용 업데이트)
├── Makefile                        ← 크로스 프로젝트 명령어 (신규)
├── docker-compose.yml              ← 로컬 개발 오케스트레이션 (신규)
├── .gitignore                      ← 통합 (Rails + Flutter 패턴)
└── README.md                       ← 모노레포 안내 (내용 교체)
```

### 이동 대상 (server/ 로)

**디렉토리**: app/ bin/ config/ db/ lib/ log/ public/ script/ spec/ storage/ tmp/ vendor/ .kamal/ .ruby-lsp/
**파일**: Gemfile Gemfile.lock Rakefile config.ru Procfile.dev Dockerfile .dockerignore .rspec .rubocop.yml .ruby-version .env.example analysis-report.docx

### 루트 유지 대상

.claude/ docs/ .git/ .github/ .gitignore .gitattributes hooks/ CLAUDE.md README.md

### 내용 변경 필요 파일

| 파일 | 변경 |
|------|------|
| `.gitignore` | Rails 경로 `server/` 접두사 + Flutter `mobile/` 무시 패턴 |
| `CLAUDE.md` | 모노레포 구조 반영, 경로 업데이트 |
| `README.md` | 모노레포 소개 + 각 서브프로젝트 실행법 |
| `Makefile` | 신규: server/mobile 공통 명령어 |
| `docker-compose.yml` | 신규: Rails dev server + PostgreSQL |

### Dockerfile 경로 영향

Dockerfile이 `server/`로 함께 이동하므로 내부 COPY 경로는 변경 불필요.
Docker build 시 `docker build -f server/Dockerfile server/` 또는 Kamal의 build context만 수정.

## 체크포인트 & 컨텍스트 관리

| 체크포인트 | 산출물 | 컨텍스트 조치 | 판단 기준 |
|-----------|--------|-------------|----------|
| /scope 완료 | 이 문서 | 유지 | scope 탐색 파일 = makeplan에서 참조할 파일 (높은 overlap) |
| /makeplan 완료 | Plan 문서 | 유지 | plan에서 정의한 파일 = impl에서 수정할 파일 |
| /implementation 완료 | 커밋 | - | 완료 |
