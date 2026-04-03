---
id: "001"
type: research
title: "루비온레일즈 서버 구동 및 운영 안내서"
created: 2026-02-23
summary: >
  Ruby 3.3.10 / Rails 8.1.2 / SQLite3(개발) · PostgreSQL(프로덕션) 환경의
  서버 구동과 운영에 필요한 명령어, 설정, 트러블슈팅을 정리한 안내서.
keywords: [Rails, Ruby, 서버운영, PostgreSQL, SQLite3]
---

# 루비온레일즈 서버 구동 및 운영 안내서

날짜: 2026-02-23
대상: 개발자, 운영자
환경: Ruby 3.3.10 / Rails 8.1.2 / SQLite3(개발) · PostgreSQL(프로덕션)

---

## 1) 프로젝트 기술 스택 요약

| 항목 | 내용 |
|------|------|
| 언어 | Ruby 3.3.10 |
| 프레임워크 | Rails 8.1.2 |
| 웹 서버 | Puma (기본 포트 3000) |
| 개발 DB | SQLite3 (`storage/development.sqlite3`) |
| 프로덕션 DB | PostgreSQL (`pg` gem) |
| CSS | Tailwind CSS (tailwindcss-rails) |
| JS | Importmap + Hotwire (Turbo + Stimulus) |
| 에셋 파이프라인 | Propshaft |
| 백그라운드 작업 | Solid Queue |
| 캐시 | Solid Cache |
| WebSocket | Solid Cable |
| 테스트 | RSpec + FactoryBot + Faker |
| 배포 | Kamal (Docker 기반) |

---

## 2) 최초 환경 설정

### 2-1. 사전 요구사항

```bash
# Ruby 버전 확인 (.ruby-version 파일 기준)
ruby -v
# → ruby 3.3.10 이어야 함

# rbenv 사용 시 버전 설치
rbenv install 3.3.10
rbenv local 3.3.10

# Bundler 설치
gem install bundler
```

### 2-2. 의존성 설치 및 DB 초기화 (한 번에)

```bash
bin/setup
```

`bin/setup`이 수행하는 작업:
1. `bundle install` — Gem 의존성 설치
2. `bin/rails db:prepare` — DB 생성 + 마이그레이션 적용
3. 로그 및 임시파일 정리 (`log/`, `tmp/`)
4. 개발 서버 자동 시작 (`bin/dev`)

> **팁:** 서버 시작 없이 설정만 할 때는 `--skip-server` 플래그 사용
> ```bash
> bin/setup --skip-server
> ```

> **팁:** DB를 완전히 초기화할 때는 `--reset` 플래그 사용 (데이터 모두 삭제)
> ```bash
> bin/setup --reset
> ```

---

## 3) 개발 서버 구동

### 3-1. 권장 방법: `bin/dev`

```bash
bin/dev
```

`bin/dev`는 **foreman**을 통해 `Procfile.dev`에 정의된 프로세스를 동시에 실행합니다.

```
# Procfile.dev
web: bin/rails server       # Puma 웹 서버
css: bin/rails tailwindcss:watch  # Tailwind CSS 실시간 빌드
```

두 프로세스가 동시에 동작하므로 CSS 변경사항이 즉시 반영됩니다.

> foreman이 설치되지 않은 경우 `bin/dev` 실행 시 자동으로 설치합니다.

### 3-2. 포트 변경

```bash
PORT=4000 bin/dev
```

### 3-3. 웹 서버만 단독 실행

```bash
bin/rails server
# 또는
bin/rails s
```

### 3-4. 서버 재시작

```bash
bin/rails restart
```

`tmp/restart.txt` 파일을 갱신해 Puma에 재시작 신호를 보냅니다.

---

## 4) 데이터베이스 관리

### 4-1. 기본 DB 명령어

```bash
# DB 생성
bin/rails db:create

# 마이그레이션 실행
bin/rails db:migrate

# 시드 데이터 적재
bin/rails db:seed

# DB 생성 + 마이그레이션 + 시드 (한 번에)
bin/rails db:setup

# DB 초기화 (삭제 후 재생성 + 마이그레이션 + 시드)
bin/rails db:reset

# 마이그레이션 상태 확인
bin/rails db:migrate:status

# 가장 최근 마이그레이션 롤백
bin/rails db:rollback

# N 단계 롤백
bin/rails db:rollback STEP=3
```

### 4-2. 데이터베이스 파일 위치

| 환경 | 파일 경로 |
|------|----------|
| development | `storage/development.sqlite3` |
| test | `storage/test.sqlite3` |
| production (primary) | `storage/production.sqlite3` |
| production (cache) | `storage/production_cache.sqlite3` |
| production (queue) | `storage/production_queue.sqlite3` |
| production (cable) | `storage/production_cable.sqlite3` |

> **Rails 8 특징:** Solid Cache/Queue/Cable은 별도 SQLite DB 파일을 사용합니다. 프로덕션에서도 Redis 없이 운영 가능합니다.

### 4-3. Rails 콘솔 (DB 직접 조작)

```bash
# 개발 환경 콘솔
bin/rails console
# 또는
bin/rails c

# 특정 환경 콘솔
RAILS_ENV=production bin/rails c

# 샌드박스 모드 (모든 변경사항이 롤백됨)
bin/rails c --sandbox
```

---

## 5) Puma 웹 서버 설정

`config/puma.rb`에서 설정합니다.

```ruby
# 스레드 수: 기본 3 (환경변수로 조절 가능)
threads_count = ENV.fetch("RAILS_MAX_THREADS", 3)
threads threads_count, threads_count

# 포트: 기본 3000 (환경변수로 조절 가능)
port ENV.fetch("PORT", 3000)
```

### 주요 환경변수

| 변수 | 기본값 | 설명 |
|------|--------|------|
| `PORT` | 3000 | 수신 포트 |
| `RAILS_MAX_THREADS` | 3 | Puma 스레드 수 |
| `WEB_CONCURRENCY` | 1 | Puma 워커(프로세스) 수 |
| `SOLID_QUEUE_IN_PUMA` | (미설정) | Puma 내에서 Solid Queue 실행 여부 |

---

## 6) 코드 품질 및 보안 검사

### 6-1. CI 전체 실행 (권장)

```bash
bin/ci
```

CI 실행 순서:
1. `bin/setup --skip-server` — 환경 준비
2. `bin/rubocop` — Ruby 코드 스타일 검사
3. `bin/bundler-audit` — Gem 보안 취약점 감사
4. `bin/importmap audit` — JS 의존성 취약점 감사
5. `bin/brakeman` — Rails 보안 정적 분석

### 6-2. 개별 실행

```bash
# 코드 스타일 검사 (RuboCop)
bin/rubocop

# 자동 수정 가능한 문제 자동 수정
bin/rubocop -a

# Gem 보안 취약점 감사
bin/bundler-audit

# Brakeman 보안 분석
bin/brakeman --quiet --no-pager
```

---

## 7) 테스트 실행

프레임워크: **RSpec** + FactoryBot + Faker

```bash
# 전체 테스트
bundle exec rspec

# 특정 파일
bundle exec rspec spec/models/user_spec.rb

# 특정 라인
bundle exec rspec spec/models/user_spec.rb:42

# 태그로 필터링
bundle exec rspec --tag focus
```

`.rspec` 파일 설정:
```
--require spec_helper
```

---

## 8) 에셋 빌드

### Tailwind CSS

```bash
# 개발: 파일 변경 감지 + 자동 빌드
bin/rails tailwindcss:watch

# 프로덕션: 최적화 빌드 (minify)
bin/rails tailwindcss:build
```

### Importmap (JavaScript)

```bash
# 임포트맵 상태 확인
bin/importmap json

# JS 패키지 취약점 감사
bin/importmap audit

# 패키지 추가
bin/importmap pin <패키지명>

# 패키지 제거
bin/importmap unpin <패키지명>
```

---

## 9) 로그 관리

```bash
# 개발 로그 확인 (실시간)
tail -f log/development.log

# 로그 파일 초기화
bin/rails log:clear

# 로그 레벨 변경 (환경변수)
RAILS_LOG_LEVEL=debug bin/dev
```

로그 레벨: `debug` → `info` → `warn` → `error` → `fatal`

---

## 10) 임시 파일 정리

```bash
# tmp/ 디렉토리 정리 (캐시, 세션 등)
bin/rails tmp:clear

# 로그 + 임시파일 동시 정리
bin/rails log:clear tmp:clear

# 에셋 캐시 초기화
bin/rails assets:clobber
```

---

## 11) 유용한 Rails 명령어

```bash
# 라우트 목록 확인
bin/rails routes

# 특정 경로 라우트 검색
bin/rails routes -g user

# 모든 미들웨어 목록
bin/rails middleware

# 환경 정보 출력
bin/rails about

# 제너레이터 목록
bin/rails generate --help
# 또는
bin/rails g --help

# 모델 생성 예시
bin/rails g model User name:string email:string

# 컨트롤러 생성 예시
bin/rails g controller Users index show
```

---

## 12) 디버깅

```bash
# 개발 서버는 원격 디버그 허용 상태로 시작됩니다 (bin/dev 기준)
# RUBY_DEBUG_OPEN=true
# RUBY_DEBUG_LAZY=true

# 코드에 디버거 삽입
debugger  # 코드 내 원하는 위치에 추가

# rdbg로 원격 연결 (별도 터미널)
rdbg --attach
```

---

## 13) 트러블슈팅

### 서버가 시작되지 않을 때

```bash
# 포트 충돌 확인
lsof -i :3000

# PID 파일 잠금 해제
rm tmp/pids/server.pid

# 번들 이슈
bundle install

# DB 초기화 필요 시
bin/rails db:prepare
```

### Tailwind CSS가 적용되지 않을 때

```bash
# CSS 강제 재빌드
bin/rails tailwindcss:build

# bin/dev로 watch 모드 재시작
bin/dev
```

### 마이그레이션 충돌 시

```bash
# 현재 스키마 버전 확인
bin/rails db:version

# 마이그레이션 상태 전체 확인
bin/rails db:migrate:status

# 특정 버전으로 롤백
bin/rails db:migrate:down VERSION=20260101000000
```

---

## 부록: 빠른 참조

```bash
# === 개발 시작 ===
bin/setup           # 최초 설정 (의존성 + DB + 서버)
bin/dev             # 서버만 시작

# === DB ===
bin/rails db:migrate        # 마이그레이션
bin/rails db:rollback       # 롤백
bin/rails c                 # 콘솔

# === 품질 검사 ===
bin/ci              # 전체 CI
bin/rubocop         # 코드 스타일
bundle exec rspec   # 테스트

# === 청소 ===
bin/rails log:clear tmp:clear
bin/rails restart
```
