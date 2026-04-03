---
id: "003"
title: "기술 스택 및 의존성 분석"
category: agent
status: archived
created: 2026-03-11
summary: >
  personality 프로젝트의 Ruby 3.3.10/Rails 8.1.2 기술 스택, Gemfile 전체 gem 역할,
  Stimulus.js 8개 컨트롤러 기능, Kamal 배포 설정, 보안 도구를 초보자 관점에서 상세 분석.
keywords: [agent-report, tech-stack, gemfile, stimulus, tailwind, kamal, rails8]
modules: [javascript, gems, deployment]
---

# 기술 스택 및 의존성 분석

## 요약

personality 프로젝트는 Ruby 3.3.10 / Rails 8.1.2 기반의 성격검사 서비스로, 프론트엔드는 Tailwind CSS v4 + Stimulus.js + Importmap 조합을 사용하며 번들러 없이 동작한다. 배포는 Kamal 2.10.1로 Docker 컨테이너를 직접 서버에 올리는 방식이며, 데이터베이스는 SQLite(개발/테스트) + PostgreSQL(프로덕션) 이중 구조다. 보안은 brakeman + bundler-audit + rubocop의 3중 레이어로 CI 파이프라인에서 자동 검사한다.

---

## 상세 분석

### 1. Ruby 및 Rails 버전

| 항목 | 버전 | 출처 |
|------|------|------|
| Ruby | **3.3.10** | `.ruby-version:1`, `Dockerfile:11` |
| Rails | **8.1.2** | `Gemfile.lock:284` |
| Bundler | **2.5.22** | `Gemfile.lock:492` |

Rails 8.1.2는 2024~2025년 최신 버전으로, Solid 삼형제(solid_queue, solid_cache, solid_cable)가 기본 내장된 버전이다. 이전에는 Redis가 필요했던 기능들을 SQLite/DB만으로 처리할 수 있다.

---

### 2. Gemfile 전체 분석

#### 핵심 프레임워크 gem

| gem | 버전 (lock 기준) | 역할 | 왜 필요한가 |
|-----|----------------|------|------------|
| `rails` | 8.1.2 | 웹 프레임워크 전체 | 프로젝트의 근간. MVC 구조, 라우팅, DB 연결 등 모두 포함 |
| `puma` | 7.2.0 | 웹 서버 | 브라우저 요청을 받아서 Rails에 전달하는 문지기 역할 |
| `propshaft` | 1.3.1 | 에셋 파이프라인 | CSS, JS, 이미지 파일을 브라우저에 효율적으로 전달 (Sprockets 대체) |

출처: `Gemfile:4`, `Gemfile:6`, `Gemfile:10`

#### 데이터베이스 gem

| gem | 버전 | 역할 |
|-----|------|------|
| `sqlite3` | 2.9.0 | 개발/테스트 환경 DB 드라이버 |
| `pg` | 1.6.3 | 프로덕션 PostgreSQL 드라이버 (`:production` 그룹) |

출처: `Gemfile:8`, `Gemfile:44`

주목할 점: 개발은 SQLite로 가볍게 시작하고, 프로덕션에선 PostgreSQL로 전환하는 구조. `group :production do gem "pg" end` 패턴이 이를 구현한다.

#### 보안 gem - bcrypt

```ruby
# Gemfile:21
gem "bcrypt", "~> 3.1.7"
```

bcrypt는 비밀번호를 암호화하는 알고리즘 라이브러리다. Rails의 `has_secure_password` 기능이 내부적으로 bcrypt를 사용한다. 비밀번호를 plain text가 아닌 bcrypt 해시로 저장한다.

#### 프론트엔드 관련 gem

| gem | 버전 | 역할 |
|-----|------|------|
| `importmap-rails` | 2.2.3 | npm/webpack 없이 ES 모듈 import 지원 |
| `turbo-rails` | 2.0.23 | 페이지 전환 없이 부분 업데이트 (Hotwire) |
| `stimulus-rails` | 1.3.4 | Stimulus.js 컨트롤러 프레임워크 |
| `tailwindcss-rails` | 4.4.0 | Tailwind CSS v4 통합 |

출처: `Gemfile:12`, `Gemfile:14`, `Gemfile:16`, `Gemfile:18`

#### Solid 삼형제 gem (Rails 8 신기능)

| gem | 버전 | 역할 | 이전에는? |
|-----|------|------|----------|
| `solid_queue` | 1.3.2 | 백그라운드 잡 처리기 | Sidekiq + Redis 필요 |
| `solid_cache` | 1.0.10 | 캐시 저장소 | Redis 필요 |
| `solid_cable` | 3.0.12 | WebSocket 연결 관리 | Redis 필요 |

출처: `Gemfile:27-29`

Rails 8의 혁신: Redis 없이 DB(SQLite/PostgreSQL)만으로 위 3가지 기능 모두 구현 가능.

#### 배포 관련 gem

| gem | 역할 |
|-----|------|
| `kamal` (2.10.1) | Docker 기반 서버 배포 자동화 도구 |
| `thruster` (0.1.18) | Puma 앞에서 HTTP 캐싱/압축/X-Sendfile 처리하는 경량 프록시 |
| `bootsnap` (1.23.0) | 앱 부팅 시간 단축 (코드 캐싱) |

출처: `Gemfile:32`, `Gemfile:35`, `Gemfile:38`

thruster는 Nginx/Caddy 없이도 정적 파일 서빙과 HTTP 압축을 처리한다. Dockerfile의 마지막 CMD: `CMD ["./bin/thrust", "./bin/rails", "server"]` (`Dockerfile:77`)

#### 개발/테스트 gem

| gem | 버전 | 역할 |
|-----|------|------|
| `debug` | 1.11.1 | Ruby 표준 디버거 (breakpoint 설정) |
| `bundler-audit` | 0.9.3 | gem의 알려진 보안 취약점 검사 |
| `brakeman` | 8.0.2 | Rails 코드의 보안 취약점 정적 분석 |
| `rubocop-rails-omakase` | 1.1.0 | Rails 팀 공식 코드 스타일 린터 |
| `rspec-rails` | 8.0.3 | BDD 테스트 프레임워크 |
| `factory_bot_rails` | 6.5.1 | 테스트용 더미 데이터 팩토리 |
| `faker` | 3.6.0 | 이름/이메일 등 가짜 데이터 생성 |
| `web-console` | 4.2.1 | 에러 페이지에서 Rails 콘솔 직접 접근 |

출처: `Gemfile:47-68`

#### 특수 gem - tidewave

```ruby
# Gemfile:70
gem "tidewave", "~> 0.4.2", :group => :development
```

`tidewave`는 AI 코딩 도우미(Claude Code 등)가 Rails 앱과 직접 통신하기 위한 MCP(Model Context Protocol) 서버 gem이다. 개발 환경에서만 활성화된다.

---

### 3. 프론트엔드 스택: Tailwind + Stimulus + Importmap

#### 왜 이 조합인가?

```
Importmap → npm/webpack 불필요, 브라우저 native ES module import 사용
Stimulus  → 최소한의 JS로 HTML에 동적 기능 부여 (React 대비 10분의 1 복잡도)
Tailwind  → CSS 파일 없이 HTML 클래스만으로 스타일링
```

#### Importmap 동작 방식

```ruby
# config/importmap.rb:4-7
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
```

`pin`은 "이 npm 패키지 이름을 이 파일로 연결해라"는 뜻. Node.js 설치 불필요.

#### Tailwind CSS v4 특징

```css
/* app/assets/tailwind/application.css:1 */
@import "tailwindcss";

@theme {
  --color-cream: #FFF8F0;
  --color-blush: #FFE4D6;
  --font-sans: 'Pretendard Variable', Pretendard, ...;
}
```

v4는 `tailwind.config.js` 파일 대신 CSS `@theme` 블록에서 커스텀 컬러/폰트를 정의한다. 이 프로젝트는 cream, blush, sage, sky, lavender 등 부드러운 색상 팔레트와 한국어 폰트(Pretendard)를 커스텀 정의했다.

#### 개발환경 동시 실행

```
# Procfile.dev:1-2
web: bin/rails server
css: bin/rails tailwindcss:watch
```

Rails 서버 + Tailwind CSS 변경 감지를 동시 실행.

---

### 4. Stimulus 컨트롤러 8개 상세 분석

Stimulus의 기본 원리: HTML 요소에 `data-controller="xxx"` 속성을 붙이면, `xxx_controller.js`가 자동으로 그 요소에 연결된다.

#### (1) autosave_controller.js

**역할:** 성격검사 진행 상태를 브라우저의 `sessionStorage`에 저장/복원한다.

```javascript
// app/javascript/controllers/autosave_controller.js:4-5
static values = { key: String }

connect() {
  this.key = this.keyValue || "assessment_progress"
}
```

- `save(data)` → `sessionStorage.setItem(key, JSON.stringify(data))` (JSON으로 직렬화하여 저장)
- `load()` → `sessionStorage.getItem(key)` (저장된 데이터 복원)
- `clear()` → `sessionStorage.removeItem(key)` (완료 후 삭제)

**왜 필요한가:** 사용자가 설문 도중 실수로 뒤로가기를 눌러도 답변이 사라지지 않도록 보호한다.

#### (2) countdown_controller.js

**역할:** 설문 응답 시간을 측정하는 타이머. "카운트다운"이라는 이름과 달리, 실제로는 경과 시간(elapsed time)을 측정한다.

```javascript
// countdown_controller.js:15-17
form.addEventListener("submit", () => {
  field.value = Math.round(Date.now() - this.startTime)
})
```

폼 제출 시 `Date.now() - startTime` (밀리초 단위)을 hidden field에 기록. 서버는 이 응답 시간으로 품질 분석을 수행한다.

#### (3) likert_controller.js

**역할:** Likert 척도 문항의 UI를 관리한다.

**Likert 척도란?** "전혀 그렇지 않다 ~ 매우 그렇다" 5단계 선택지. 성격검사의 핵심 입력 방식.

```javascript
// app/javascript/controllers/likert_controller.js:3-5
static targets = ["form", "option", "skipField"]
```

- `select()`: 라디오 버튼 선택 시 시각적 피드백. 실제 스타일 변경은 CSS `:has(:checked)` 선택자가 담당
- `submit()`: 선택 후 200ms 딜레이로 폼 자동 제출 (시각적 피드백을 사용자가 확인할 시간 부여)
- `skip()`: 건너뛰기 → `skipField` 값을 "1"로 설정 후 제출

#### (4) progress_controller.js

**역할:** 설문 진행률 바(progress bar)에 CSS 트랜지션 애니메이션을 적용한다.

```javascript
// app/javascript/controllers/progress_controller.js:6-13
connect() {
  requestAnimationFrame(() => {
    if (this.hasBarTarget) {
      this.barTarget.style.transition = "width 0.5s ease-out"
    }
  })
}
```

`requestAnimationFrame`을 사용하는 이유: 브라우저 렌더링 타이밍에 맞춰 트랜지션을 적용해야 애니메이션이 실제로 보인다.

#### (5) questionnaire_controller.js

**역할:** 설문 전체 흐름을 조율하는 최상위 컨트롤러. 현재 스텁(stub) 상태. 실제 로직은 `autosave_controller`에 위임.

#### (6) spectrum_bar_controller.js

**역할:** 성격검사 결과 페이지에서 각 성격 차원의 스펙트럼 바를 순차적으로 애니메이션한다.

```javascript
// app/javascript/controllers/spectrum_bar_controller.js:8-13
this.barTargets.forEach((bar, index) => {
  const finalWidth = bar.dataset.finalWidth
  setTimeout(() => {
    bar.style.width = `${finalWidth}%`
  }, 1600 + (index * 200))
})
```

타이밍: 1600ms 기본 딜레이 후 각 바가 200ms 간격으로 순차 등장. `finalWidth`는 서버가 HTML의 `data-final-width` 속성에 미리 설정.

#### (7) tabs_controller.js

**역할:** 탭 UI 구현. `tab` 타겟(버튼)과 `panel` 타겟(콘텐츠)을 쌍으로 관리.

```javascript
// app/javascript/controllers/tabs_controller.js:4-6
static targets = ["tab", "panel"]
static classes = ["active", "inactive"]
```

`static classes`로 active/inactive 클래스를 HTML에서 설정받으므로, Tailwind 클래스를 JavaScript에 하드코딩하지 않는다.

#### (8) type_reveal_controller.js

**역할:** 성격 유형(예: INTJ, ENFP)을 극적으로 공개하는 애니메이션 컨트롤러. 현재 CSS `@keyframes` 애니메이션이 주역이며, JS 컨트롤러는 향후 확장을 위한 예비 구조.

---

### 5. Kamal 배포 구성

Kamal은 Basecamp가 만든 Docker 기반 배포 도구. Heroku 없이 직접 서버에 Docker 컨테이너를 올린다.

#### 서버 구성

```yaml
# config/deploy.yml:8-14
servers:
  web:
    - 192.168.0.1
```

단일 웹 서버 구성. 잡 서버는 주석 처리 → `SOLID_QUEUE_IN_PUMA: true`로 Puma 내에서 처리.

#### 이미지 레지스트리

```yaml
# config/deploy.yml:29-30
registry:
  server: localhost:5555
```

로컬 Docker 레지스트리(포트 5555) 사용 중.

#### 환경변수 관리

```yaml
# config/deploy.yml:40-46
env:
  secret:
    - RAILS_MASTER_KEY    # .kamal/secrets에서 읽어서 암호화 전송
  clear:
    SOLID_QUEUE_IN_PUMA: true
```

#### 편의 명령어

```yaml
# config/deploy.yml:64-67
aliases:
  console: app exec --interactive --reuse "bin/rails console"
  shell:   app exec --interactive --reuse "bash"
  logs:    app logs -f
  dbc:     app exec --interactive --reuse "bin/rails dbconsole --include-password"
```

`bin/kamal console` 한 줄로 프로덕션 Rails 콘솔 접속 가능.

#### Dockerfile 멀티스테이지 빌드

```
# Dockerfile:31
FROM base AS build   # 빌드 스테이지: gem 설치, 에셋 컴파일
FROM base            # 최종 스테이지: 빌드 산출물만 복사 → 이미지 크기 최소화
```

- `libjemalloc2` 설치: Ruby 메모리 할당기를 jemalloc으로 교체 (`Dockerfile:19,28`)
- 비루트 사용자 실행: `USER 1000:1000` (`Dockerfile:66`)

---

### 6. 보안 도구 및 CI 파이프라인

#### 보안 도구 3종

**1. Brakeman (8.0.2)**: Rails 전용 보안 취약점 스캐너. SQL 인젝션, XSS, 매스 어사인먼트 등을 소스코드 레벨에서 분석한다.

**2. bundler-audit (0.9.3)**: 설치된 gem들의 CVE 데이터베이스를 조회하여 알려진 보안 결함을 가진 버전이 있는지 확인한다.

**3. RuboCop + rubocop-rails-omakase (1.1.0)**: Rails 팀(DHH 포함)이 선호하는 "오마카세" 스타일 강제.

#### CI 파이프라인

```ruby
# config/ci.rb
CI.run do
  step "Setup",      "bin/setup --skip-server"
  step "Style: Ruby", "bin/rubocop"
  step "Security: Gem audit",    "bin/bundler-audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman code analysis",
       "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
end
```

CI 실행 순서: Setup → Ruby 스타일 → Gem 보안 → Importmap 보안 → 코드 보안

**주목**: 테스트(RSpec) 실행이 CI에 없다. `rspec-rails`가 설치되어 있으나 `config/ci.rb`에 RSpec 실행 스텝이 없다.

---

## 핵심 발견

1. **테스트가 CI에서 빠져있다**: `rspec-rails`가 설치되어 있으나 `config/ci.rb`에 `bin/rspec` 스텝이 없다. 보안/스타일 검사만 CI에서 실행 중.

2. **이중 DB 전략**: 개발은 SQLite, 프로덕션은 PostgreSQL(`group :production do gem "pg" end`).

3. **Stimulus 컨트롤러 중 2개가 스텁 상태**: `questionnaire_controller`와 `type_reveal_controller`가 미완성. 기능 확장을 위한 구조만 잡혀있다.

4. **countdown_controller의 실제 기능**: 이름은 countdown이지만 카운트다운이 아니라 응답 소요시간 측정기(elapsed time recorder).

5. **tidewave gem**: MCP 프로토콜로 AI 도구(Claude Code)가 직접 Rails 앱과 통신하는 실험적 gem이 개발 환경에 포함되어 있다.

---

## 초보자를 위한 핵심 포인트

1. **"번들러 없는 프론트엔드"의 의미**: Importmap 덕분에 Node.js, npm, webpack을 설치할 필요가 없다. `config/importmap.rb`의 `pin` 명령만으로 JS 패키지를 관리한다.

2. **Solid 삼형제 = Redis 대체**: Rails 8 이전에는 백그라운드 잡, 캐시, WebSocket을 위해 Redis 서버가 별도로 필요했다. `solid_queue`, `solid_cache`, `solid_cable`은 이를 SQLite/DB로 대체한다.

3. **bcrypt의 역할**: `gem "bcrypt"`는 `has_secure_password`를 사용하기 위한 필수 라이브러리다. 비밀번호를 절대 평문으로 저장하지 않고 bcrypt 해시로 저장한다.

4. **Kamal = Docker 배포 자동화**: `bin/kamal deploy` 한 줄로 Docker 이미지 빌드 → 레지스트리 업로드 → 서버에 배포까지 자동 처리한다.

5. **Stimulus 컨트롤러의 설계 원칙**: "HTML이 주인, JS가 조연." 실제 데이터는 서버가 HTML에 렌더링하고, Stimulus 컨트롤러는 그 데이터를 읽어 시각적 효과(애니메이션, 전환)만 담당한다.

---

## 참조 파일

| 파일 | 내용 |
|------|------|
| `Gemfile` | gem 의존성 선언 |
| `Gemfile.lock` | 실제 설치된 버전 잠금 |
| `.ruby-version` | Ruby 3.3.10 |
| `Dockerfile` | 멀티스테이지 빌드, jemalloc, 비루트 실행 |
| `config/deploy.yml` | Kamal 배포 설정 |
| `app/javascript/controllers/autosave_controller.js` | sessionStorage 자동저장 |
| `app/javascript/controllers/countdown_controller.js` | 응답 소요시간 측정 |
| `app/javascript/controllers/likert_controller.js` | Likert 척도 UI + 자동제출 |
| `app/javascript/controllers/progress_controller.js` | 진행률 바 애니메이션 |
| `app/javascript/controllers/spectrum_bar_controller.js` | 결과 스펙트럼 바 순차 애니메이션 |
| `app/javascript/controllers/tabs_controller.js` | 탭 전환 UI |
| `config/importmap.rb` | JS 패키지 pin 설정 |
| `config/ci.rb` | CI 스텝 정의 |
| `app/assets/tailwind/application.css` | Tailwind v4 테마 커스터마이징 |
