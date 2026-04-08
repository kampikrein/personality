---
id: "002"
type: plan
title: "하이브리드 모노레포 구조 전환 플랜"
created: 2026-03-15
traces_scope: "001"
summary: >
  Rails 파일을 server/로 git mv, mobile/ Flutter scaffold 생성,
  shared/ placeholder, 루트에 Makefile/docker-compose.yml 배치.
  CI/CD 및 .gitignore 경로 업데이트.
keywords: [monorepo, rails, flutter, git-mv, restructure]
---

# 002 — 하이브리드 모노레포 구조 전환 플랜

## Goal

현재 루트에 산재한 Rails 파일을 `server/`로 이동하고, `mobile/`(Flutter), `shared/`(API 계약) 디렉토리를 추가하여 하이브리드 모노레포 구조를 완성한다. git 히스토리를 보존하고, 이동 후 `cd server && bundle exec rails s`가 정상 동작해야 한다.

## Scope

### Included
| # | Item | Description |
|---|------|-------------|
| 1 | Rails → server/ 이동 | git mv로 모든 Rails 파일/디렉토리 이동 |
| 2 | .gitignore 재작성 | server/ 접두사 + Flutter 패턴 |
| 3 | CI/CD 경로 업데이트 | ci.yml, dependabot.yml |
| 4 | CLAUDE.md 업데이트 | 모노레포 구조 반영 |
| 5 | README.md 교체 | 모노레포 안내 |
| 6 | Makefile 생성 | 크로스 프로젝트 명령어 |
| 7 | docker-compose.yml 생성 | PostgreSQL dev 서비스 |
| 8 | mobile/ scaffold | 최소 Flutter 프로젝트 구조 |
| 9 | shared/ placeholder | API 스키마 디렉토리 |

### Excluded
| Item | Reason/Timeline |
|------|-----------------|
| Flutter 기능 구현 | 구조 세팅만 집중 (사용자 지시) |
| Rails API 엔드포인트 | 타로 백엔드는 별도 Phase |
| Tarot:: 모델 추가 | 별도 Phase |
| Kamal deploy.yml 수정 | 컨테이너 내부 경로는 변경 불필요, 배포 시 별도 대응 |

## Structural Decisions

> No structural decisions required — 접근법 3(하이브리드)이 사용자에 의해 이미 확정됨.

---

## File Change Summary

### Modified Files
| # | File Path | Change Description |
|---|-----------|-------------------|
| 1 | `.gitignore` | Rails 경로에 server/ 접두사, Flutter/mobile 패턴 추가 |
| 2 | `.github/workflows/ci.yml` | 모든 job에 `working-directory: server` 추가 |
| 3 | `.github/dependabot.yml` | bundler directory: "/" → "/server" |
| 4 | `CLAUDE.md` | 모노레포 구조 설명 추가 |
| 5 | `README.md` | 모노레포 안내로 전체 교체 |

### New Files
| # | File Path | Description |
|---|-----------|-------------|
| 1 | `Makefile` | server/mobile 공통 명령어 |
| 2 | `docker-compose.yml` | PostgreSQL dev 서비스 |
| 3 | `mobile/pubspec.yaml` | Flutter 프로젝트 정의 |
| 4 | `mobile/lib/main.dart` | 최소 Flutter 엔트리포인트 |
| 5 | `mobile/.gitignore` | Flutter 표준 무시 패턴 |
| 6 | `shared/api-schema/.gitkeep` | Placeholder |
| 7 | `shared/README.md` | API 스키마 디렉토리 설명 |

---

## Step 1 — server/ 디렉토리 생성 및 Rails 파일 이동

### Approach

`mkdir server` 후 `git mv`로 Rails 관련 파일/디렉토리를 일괄 이동. git mv는 rename으로 인식되어 히스토리가 보존된다.

### Commands

```bash
# 1. server 디렉토리 생성
mkdir server

# 2. Rails 디렉토리 이동
git mv app bin config db lib log public script spec storage tmp vendor server/

# 3. 숨김 디렉토리 이동
git mv .kamal server/
git mv .ruby-lsp server/

# 4. Rails 파일 이동
git mv Gemfile Gemfile.lock Rakefile config.ru server/
git mv Procfile.dev Dockerfile .dockerignore server/
git mv .rspec .rubocop.yml .ruby-version server/

# 5. 기타 파일 이동
git mv .env.example server/ 2>/dev/null || true
git mv analysis-report.docx server/ 2>/dev/null || true
```

### Considerations

- `git mv`는 대상 디렉토리가 존재해야 함 → `mkdir server` 선행 필수
- `.env*` 파일은 .gitignore 대상이므로 tracked 상태가 아닐 수 있음 → `2>/dev/null || true`로 안전 처리
- `analysis-report.docx`는 일회성 산출물이나 Rails 프로젝트 맥락이므로 server/로 이동

---

## Step 2 — .gitignore 재작성

### Current Code
```gitignore
# .gitignore (현재 — 루트 기준 Rails 경로)
/.bundle
/.env*
/log/*
/tmp/*
!/log/.keep
!/tmp/.keep
/tmp/pids/*
!/tmp/pids/
!/tmp/pids/.keep
/storage/*
!/storage/.keep
/tmp/storage/*
!/tmp/storage/
!/tmp/storage/.keep
/public/assets
/config/*.key
/app/assets/builds/*
!/app/assets/builds/.keep
.agents/
.opencode/
.cursor/
.claude/*
!.claude/agents/
!.claude/agent-memory/
```

### After Code
```gitignore
# .gitignore (모노레포 — server/ 접두사)

# === Server (Rails) ===
server/.bundle
server/.env*
server/log/*
!server/log/.keep
server/tmp/*
!server/tmp/.keep
server/tmp/pids/*
!server/tmp/pids/
!server/tmp/pids/.keep
server/storage/*
!server/storage/.keep
server/tmp/storage/*
!server/tmp/storage/
!server/tmp/storage/.keep
server/public/assets
server/config/*.key
server/app/assets/builds/*
!server/app/assets/builds/.keep

# === Mobile (Flutter) ===
mobile/.dart_tool/
mobile/.packages
mobile/.pub-cache/
mobile/.pub/
mobile/build/
mobile/.flutter-plugins
mobile/.flutter-plugins-dependencies
mobile/android/.gradle/
mobile/android/local.properties
mobile/ios/Pods/
mobile/ios/.symlinks/

# === IDE / AI tool configs ===
.agents/
.opencode/
.cursor/
.claude/*
!.claude/agents/
!.claude/agent-memory/

# === OS ===
.DS_Store
```

---

## Step 3 — CI/CD 경로 업데이트

### 3a. ci.yml

각 job에 `defaults.run.working-directory: server` 추가. `ruby/setup-ruby`에는 `working-directory: server` input 추가. lint job의 `hashFiles` 경로에 `server/` 접두사.

### Current Code
```yaml
# .github/workflows/ci.yml:8-20
jobs:
  scan_ruby:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v6

      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Scan for common Rails security vulnerabilities using static analysis
        run: bin/brakeman --no-pager

      - name: Scan for known security vulnerabilities in gems used
        run: bin/bundler-audit
```

### After Code
```yaml
# .github/workflows/ci.yml (전체 교체)
name: CI

on:
  pull_request:
  push:
    branches: [ main ]

jobs:
  scan_ruby:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: server
    steps:
      - name: Checkout code
        uses: actions/checkout@v6
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          working-directory: server
          bundler-cache: true
      - name: Scan for common Rails security vulnerabilities using static analysis
        run: bin/brakeman --no-pager
      - name: Scan for known security vulnerabilities in gems used
        run: bin/bundler-audit

  scan_js:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: server
    steps:
      - name: Checkout code
        uses: actions/checkout@v6
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          working-directory: server
          bundler-cache: true
      - name: Scan for security vulnerabilities in JavaScript dependencies
        run: bin/importmap audit

  lint:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: server
    env:
      RUBOCOP_CACHE_ROOT: tmp/rubocop
    steps:
      - name: Checkout code
        uses: actions/checkout@v6
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          working-directory: server
          bundler-cache: true
      - name: Prepare RuboCop cache
        uses: actions/cache@v4
        env:
          DEPENDENCIES_HASH: ${{ hashFiles('server/.ruby-version', 'server/**/.rubocop.yml', 'server/**/.rubocop_todo.yml', 'server/Gemfile.lock') }}
        with:
          path: server/${{ env.RUBOCOP_CACHE_ROOT }}
          key: rubocop-${{ runner.os }}-${{ env.DEPENDENCIES_HASH }}-${{ github.ref_name == github.event.repository.default_branch && github.run_id || 'default' }}
          restore-keys: |
            rubocop-${{ runner.os }}-${{ env.DEPENDENCIES_HASH }}-
      - name: Lint code for consistent style
        run: bin/rubocop -f github
```

### 3b. dependabot.yml

### Current Code
```yaml
# .github/dependabot.yml:3-6
- package-ecosystem: bundler
  directory: "/"
```

### After Code
```yaml
- package-ecosystem: bundler
  directory: "/server"
```

---

## Step 4 — CLAUDE.md 업데이트

### Current Code
```markdown
# personality 프로젝트

성격 포탈 웹 서비스 — 자기 이해, 타인 수용, 자유 추구.
Ruby on Rails 7+, PostgreSQL, RSpec, Hotwire/Turbo, Tailwind CSS.
```

### After Code
```markdown
# personality 프로젝트

성격 포탈 + 타로 모바일 — 자기 이해, 타인 수용, 자유 추구.

## 모노레포 구조
- `server/` — Rails 8+ 백엔드 (PostgreSQL, RSpec, Hotwire/Turbo, Tailwind CSS)
- `mobile/` — Flutter 모바일 앱 (타로 + 성격 서비스, 구조만 세팅됨)
- `shared/` — API 계약 (OpenAPI 스키마, placeholder)
- `docs/` — 공유 문서 (산출물 중앙화)
```

나머지 CLAUDE.md 내용(위임 판단, 에이전트, 오케스트레이션 등)은 변경 없음.

---

## Step 5 — README.md 교체

### After Code
```markdown
# personality

성격 포탈 + 타로 모바일 서비스 — 자기 이해, 타인 수용, 자유 추구.

## 구조

```
personality/
├── server/     Rails 백엔드 (API + 웹)
├── mobile/     Flutter 모바일 앱
├── shared/     API 스키마 (공유 계약)
└── docs/       프로젝트 문서
```

## 시작하기

### Server (Rails)

```bash
cd server
bundle install
bin/rails db:prepare
bin/dev
```

### Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

### 전체 (Makefile)

```bash
make setup        # 전체 의존성 설치
make server-start # Rails 개발 서버
make server-test  # RSpec 실행
make mobile-run   # Flutter 실행
```
```

---

## Step 6 — Makefile 생성

### After Code
```makefile
# Makefile (프로젝트 루트)
.PHONY: help setup server-start server-test server-console mobile-run

help: ## Show available commands
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

setup: ## Install all dependencies
	cd server && bundle install
	@if command -v flutter >/dev/null 2>&1; then cd mobile && flutter pub get; else echo "Flutter SDK not found. Skipping mobile setup."; fi

server-start: ## Start Rails development server
	cd server && bin/dev

server-test: ## Run Rails test suite
	cd server && bundle exec rspec

server-console: ## Open Rails console
	cd server && bin/rails console

mobile-run: ## Run Flutter app
	cd mobile && flutter run
```

---

## Step 7 — docker-compose.yml 생성

### After Code
```yaml
# docker-compose.yml (프로젝트 루트)
# 로컬 개발용 PostgreSQL. Rails dev는 로컬 실행 (bin/dev).
services:
  db:
    image: postgres:16
    environment:
      POSTGRES_USER: personality
      POSTGRES_PASSWORD: password
      POSTGRES_DB: personality_development
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  pgdata:
```

---

## Step 8 — mobile/ Flutter scaffold

최소 구조만 생성. 실제 Flutter 개발은 차후.

### 8a. mobile/pubspec.yaml
```yaml
name: personality_mobile
description: "Personality + Tarot mobile app"
version: 0.1.0

environment:
  sdk: ^3.0.0
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true
```

### 8b. mobile/lib/main.dart
```dart
import 'package:flutter/material.dart';

void main() {
  runApp(const PersonalityApp());
}

class PersonalityApp extends StatelessWidget {
  const PersonalityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personality',
      home: const Scaffold(
        body: Center(
          child: Text('Personality + Tarot'),
        ),
      ),
    );
  }
}
```

### 8c. mobile/.gitignore
```gitignore
.dart_tool/
.packages
.pub-cache/
.pub/
build/
.flutter-plugins
.flutter-plugins-dependencies
.metadata
*.iml
.idea/
android/.gradle/
android/local.properties
ios/Pods/
ios/.symlinks/
```

---

## Step 9 — shared/ placeholder

### 9a. shared/api-schema/.gitkeep
빈 파일.

### 9b. shared/README.md
```markdown
# shared/

서버(Rails)와 모바일(Flutter) 간 공유 계약.

## api-schema/
OpenAPI 스키마 파일이 위치할 디렉토리.
서버 API 엔드포인트 추가 시 여기에 스키마를 정의하여 모바일과 계약을 공유합니다.
```

---

## Considerations & Trade-offs

### Alternative Approaches
- **git subtree / submodule**: 별도 repo로 분리 후 연결. 현 단계에서 과잉 — 기각.
- **monorepo 도구 (Nx, Turborepo)**: Rails+Flutter는 빌드 시스템이 완전 독립이므로 불필요 — 기각.

### Potential Risks
| Risk | Mitigation |
|------|-----------|
| git mv 후 Rails 내부 경로 깨짐 | Rails는 상대경로 사용. 앱 내부 require/import에 절대경로 없음 확인 완료 |
| CI 캐시 무효화 | hashFiles 경로를 server/ 접두사로 업데이트 |
| Kamal 배포 깨짐 | deploy.yml은 server/ 내부에 있으므로 `cd server && bin/kamal deploy`로 실행 |

### Backward Compatibility
- 기존 Rails 기능: 100% 보존. 내부 코드 변경 없음.
- 외부 참조: CI, Dependabot 경로만 업데이트.

## Implementation Checklist

- [x] Step 1: mkdir server + git mv (디렉토리, 파일, 숨김파일)
- [x] Step 2: .gitignore 재작성 (server/ + mobile/ 패턴)
- [x] Step 3a: ci.yml 경로 업데이트 (working-directory: server)
- [x] Step 3b: dependabot.yml directory 업데이트
- [x] Step 4: CLAUDE.md 첫 섹션 업데이트
- [x] Step 5: README.md 교체
- [x] Step 6: Makefile 생성
- [x] Step 7: docker-compose.yml 생성
- [x] Step 8: mobile/ scaffold (pubspec.yaml, main.dart, .gitignore)
- [x] Step 9: shared/ placeholder
- [x] Final: cd server && bundle exec rspec → 266 examples, 0 failures

## Verification Assertions

| Level | Assertion | Verification Method | Expected Result |
|-------|-----------|-------------------|-----------------|
| L2-CLI | Rails 서버 기동 | `cd server && bundle exec rails s` | 정상 시작 (exit 0) |
| L2-CLI | RSpec 테스트 통과 | `cd server && bundle exec rspec` | 기존 테스트 전체 통과 |
| L2-CLI | Git 상태 정상 | `git status` | tracked 파일 모두 server/ 하위에 정상 존재 |
| L2-CLI | 루트 깔끔 | `ls` 결과 확인 | server/ mobile/ shared/ docs/ + 루트 설정 파일만 존재 |

## References

| Resource | Path/URL | Related Content |
|----------|---------|-----------------|
| Scope 문서 | docs/09_monorepo_setup/001_Scope_hybrid_monorepo.md | 구조 설계 및 이동 대상 목록 |
| 타로 PRD | docs/003_gemini_deep_research.md | 모바일 타로 앱 요구사항 |
| 비전 로드맵 | docs/08_비전스코핑/006_Synthesis_종합스코프.md | 4-Phase 실행 로드맵 |

---

## Session Log (auto-appended)

| # | Type | Duration | Tokens |
|---|------|----------|--------|
| 1 | user-ai-exchange | 0s | 0 |
| 2 | user-ai-exchange | 19s | 76045 |
| 3 | user-ai-exchange | 11s | 40778 |
| 4 | user-ai-exchange | 10s | 42195 |
| 5 | user-ai-exchange | 9s | 44183 |
| 6 | user-ai-exchange | 14s | 46529 |
| 7 | user-ai-exchange | 5s | 48356 |
| 8 | user-ai-exchange | 9s | 50568 |
| 9 | user-ai-exchange | 13s | 105037 |
| 10 | user-ai-exchange | 12s | 54453 |
| 11 | user-ai-exchange | 11s | 55874 |
| 12 | user-ai-exchange | 12s | 57359 |
| 13 | user-ai-exchange | 14s | 58996 |
| 14 | user-ai-exchange | 13s | 60582 |
| 15 | user-ai-exchange | 8s | 61831 |
| 16 | user-ai-exchange | 11s | 63033 |
| 17 | user-ai-exchange | 29s | 202688 |
| 18 | user-ai-exchange | 11s | 140060 |
| 19 | user-ai-exchange | 11s | 71985 |
| 20 | user-ai-exchange | 9s | 147944 |
| 21 | user-ai-exchange | 14s | 76148 |
| 22 | user-ai-exchange | 19s | 0 |
| 23 | user-ai-exchange | 10s | 41780 |
| 24 | user-ai-exchange | 13s | 45110 |
### Metrics

| Metric | Value |
|--------|-------|
| Duration | 341150s |
| Total Tokens | 1591534 |
| Input Tokens | 71 |
| Output Tokens | 8834 |
| Cache Read | 1202235 |
| Cache Creation | 380394 |
