---
id: "001"
type: brief
title: "Web Tarot Draw — 웹사이트 전용 타로 드로우 모듈"
created: 2026-04-24
status: completed
quality_profile: standard
deep_critique: false
critique_docs: []
summary: >
  Rails 웹사이트에 MBTI/Assessment 진입점과 독립된 `Tarot::` 네임스페이스 라우터와 모듈 구조로
  타로 드로우 기능을 신설한다. 모바일(`mobile/lib/features/{draw,shuffle,deck,reading}`)의
  도메인 설계와 덱 데이터는 재사용하되, 엔진은 Ruby로 재구현하고 UX는 웹 특성(URL 공유·마우스/드래그·
  서버 세션 지속·SEO·Turbo Streams)에 맞춰 재설계한다.
keywords: [tarot, web, rails, turbo, namespace, module, draw, shuffle, deck, reading]
---

# Web Tarot Draw — 웹사이트 전용 타로 드로우 모듈

## Intent

사용자는 Rails 웹사이트에서 MBTI 자가진단과는 분리된 **타로 드로우 경험**을 제공받고자 한다. 요청의 핵심 세 축:

1. **진입점 분리** — 기존 MBTI 플로우(`sessions#new → assessments → questions → results`)와 라우터·컨트롤러·서비스 모두 독립.
2. **모듈화** — `Tarot::` 네임스페이스 아래 draw/shuffle/deck/reading 하위 모듈로 분리. Rails 컨벤션 준수.
3. **모바일 프레임 재사용 + 웹 특화** — `mobile/`의 클린 아키텍처 레이어링(entities/usecases/strategies/repositories)과 축적된 설계 자산(셔플 알고리즘, 덱 콘텐츠, 스프레드 레이아웃, 리딩 내러티브)을 가져오되, 구현체는 Ruby/Hotwire로 번역하고 웹에서만 가능한 UX(URL 공유, 서버 지속, SEO, 키보드/마우스)를 살린다.

핵심 동기는 **플랫폼별 최적화**다. 모바일의 햅틱·가속도·오프라인-퍼스트를 웹으로 억지로 옮기지 않고, 웹은 웹대로 강점을 발휘하는 별도 진입점으로 설계한다.

## Context

### 기존 Rails 백엔드 (server/)

- `config/routes.rb` 현재 라우트: `sessions`, `assessments` (+ nested `questions`), `results`, `accounts`, `consents`, `deletion_requests`, `admin::*`. **타로 관련 라우트는 없음.**
- `app/controllers/`는 평면 구조(`assessments_controller.rb` 등). namespace 하위는 `admin/`만 존재.
- `app/models/`: MBTI/자가진단 도메인 모델(`assessment`, `question`, `question_set`, `response`, `personality_type`, `domain_score`, `insight`, `profile`, `user`, `anonymous_session`, `consent`, `deletion_request`, `audit_log`). 타로 관련 모델 없음.
- `app/services/`: `compliance/`, `insights/`, `profiles/`, `quality/`, `scoring/` — MBTI 채점·프로파일링 서비스. 타로 없음.
- 스택: Rails 8+, PostgreSQL, RSpec, Hotwire/Turbo, Tailwind CSS (CLAUDE.md 기재).
- 비로그인 사용자 지원: `AnonymousSession` 모델이 이미 존재 — 세션 쿠키 기반 익명 지속.

### 모바일 타로 구조 (mobile/lib/features/)

- `draw/presentation/{pages, providers}` — 드로우 진입/조작 UI
- `shuffle/{data, domain, presentation}` — domain에 `entities, repositories, strategies, usecases`
- `deck/{data, domain, presentation}` — domain에 `entities, repositories`
- `reading/{data, domain, presentation}` — 해석 레이어
- `chat/presentation` — AI 타로챗 (별도 피처)
- 클린 아키텍처: feature 하위 data/domain/presentation 3계층 일관.

### 축적된 도메인 자산 (docs/)

- `docs/2_tarot_draw/01_shuffle_core/` (078 산출물) — 셔플 엔진, RNG 구현(Fisher-Yates + CSPRNG), 3D/물리 엔진 연구, 통합 결과 페이지, Ritual Experience Layer, 카드 물리 규격까지 **완료된 설계 자산**.
- `docs/2_tarot_draw/03_draw_experience_settings/` (060 산출물) — Layout redesign(spread layouts), Intent placement settings 완료.
- `docs/3_deck_content/02_universal_waite/` — Universal Waite 덱 이미지 자산 계획.
- `docs/3_deck_content/01_iching_holitzka/` — 보조 덱.

### 웹-모바일 비대칭 (재사용 불가 요소)

| 모바일 고유 | 웹 대체 |
|------------|---------|
| 가속도 센서 흔들기 | 마우스 드래그 + 셔플 버튼 |
| 햅틱 피드백 | 시각/청각(옵션) 피드백 |
| 3D 물리 엔진 (Rive/Forge2D) | CSS transform + Web Animations API |
| SQLite/Drift 오프라인-퍼스트 | PostgreSQL + 서버 세션 |
| 앱 내 네비게이션 | URL 경로 + 뒤로가기 |
| 단일 유저 기기 컨텍스트 | URL 공유, 탭/리로드 견고성 |

## Boundaries

### In Scope

| # | Item | Description |
|---|------|-------------|
| 1 | `Tarot::` 라우터 네임스페이스 | `namespace :tarot do ... end` 블록 신설. MBTI 라우트 영향 없음. 진입 URL은 `/tarot/*` |
| 2 | `Tarot::DrawsController` (draw 세션) | 드로우 세션 생성(`#new`, `#create`), 조회(`#show`), 공유(`#show` via token). RESTful |
| 3 | `Tarot::` 모델 모듈 | `app/models/tarot/{draw.rb, deck.rb, card.rb, spread.rb, reading.rb}` 등 namespace 하위 모델. 테이블명은 `tarot_draws`, `tarot_decks` 등 접두어 |
| 4 | `Tarot::` 서비스 모듈 | `app/services/tarot/{shuffle_service.rb, draw_service.rb, reading_service.rb}` — 셔플 RNG, 드로우 로직, 리딩 조립 |
| 5 | 셔플 엔진 (Ruby 재구현) | 모바일 설계(Fisher-Yates + `SecureRandom`) 알고리즘 재사용. 파라미터 동일. 서버사이드 결정성/감사성 확보 |
| 6 | 기본 스프레드 2종 | 원 카드(One Card) + 3카드(과거/현재/미래). 모바일 레이아웃 스키마 재활용 |
| 7 | Universal Waite 덱 (78장) | 단일 덱으로 MVP. 덱 데이터는 JSON seed → `tarot_decks`/`tarot_cards` 시드. 이미지 자산은 `app/assets/images/tarot/` 또는 ActiveStorage |
| 8 | Turbo 기반 드로우 UX | 셔플 → 컷 → 픽 플로우를 Turbo Frames/Streams로 매끄럽게. 전체 리로드 없이 단계 진행 |
| 9 | 공유 URL | 드로우 결과를 고정 토큰 URL(`/tarot/draws/:token`)로 공유. 비로그인 열람 가능 |
| 10 | 익명 세션 호환 | 기존 `AnonymousSession` 재사용. 로그인 없이 드로우 가능, 로그인 시 결과 귀속 |
| 11 | SEO·공유 메타 | 드로우 공유 페이지에 OG tag, 제목, 요약. 공개 크롤링 가능한 정적 페이지 (결과는 비인덱싱 옵션) |
| 12 | RSpec 테스트 | 요청/모델/서비스 스펙. 셔플 RNG 결정성 테스트(시드 고정) 포함 |

### Out of Scope

| # | Item | Reason |
|---|------|--------|
| 1 | 모바일 앱 동기화 | 모바일은 오프라인-퍼스트 독립 서비스. 계정 연동 시에도 웹-모바일 드로우 동기화는 별도 토픽 |
| 2 | AI 타로챗 연동 | `features/chat`에 대응하는 AI 해석은 `docs/5_ai/01_tarot_chat/` 별도 토픽. 웹 드로우 MVP는 정적 해석만 |
| 3 | 커스텀 덱 업로드 | 사용자가 자체 덱을 업로드하는 기능은 후속 |
| 4 | 복수 덱 전환 | MVP는 Universal Waite 고정. I Ching Holitzka 등 추가 덱은 후속(전환 지점은 마련) |
| 5 | 3D 물리 애니메이션 | 모바일 자산을 웹으로 포팅하지 않음. CSS/Web Animations로 간결한 모션만 |
| 6 | 가속도/햅틱 대응 | 웹 표준 범위 밖 혹은 비일관 지원. 명시적으로 제외 |
| 7 | Admin 타로 관리 UI | MVP는 seed 파일/rake task로 덱 관리. `/admin/tarot/*`는 후속 토픽 |
| 8 | 결제·유료 프리미엄 | 기능 외 |
| 9 | 다국어 번역 | MVP는 한국어 단일(기존 MBTI와 동일). i18n 구조만 적용, 번역은 후속 |
| 10 | 리딩 내러티브 확장 | 모바일 `reading` 피처의 심화 내러티브는 MVP 이후. MVP는 카드별 정방/역방 기본 의미 + 스프레드 포지션 의미 |

## Decisions

| # | Decision | Chosen | Rationale | Trade-off | Alternatives Considered |
|---|----------|--------|-----------|-----------|------------------------|
| 1 | **라우팅 분리 방식** | `namespace :tarot do resources :draws ... end` 전면 분리. 진입 URL `/tarot/*`, 컨트롤러 `Tarot::DrawsController` | 기존 평면 컨트롤러(`assessments_controller.rb`)에 타로를 끼워넣으면 이름 충돌·관심사 혼재 가능. namespace는 Rails 컨벤션상 도메인 분리의 표준. `admin/`이 이미 같은 패턴으로 존재해 일관성 확보 | URL이 `/tarot/*` 접두어로 길어짐. 라우트 helper도 `tarot_draw_path` 등 길어짐 | (a) scope :tarot(URL만 분리, 클래스는 평면) — 모듈화 요구에 미달 (b) concern만 사용 — 구조 분리 효과 미미 |
| 2 | **모바일-웹 공유 전략** | 도메인 설계(엔티티·유스케이스·스프레드 스키마)와 덱 데이터(JSON)만 공유. 코드는 각 플랫폼 네이티브 재구현 | Dart↔Ruby 코드 공유 불가능. `shared/` 디렉토리는 OpenAPI 스키마용 placeholder에 불과. 억지로 RPC/WASM 같은 공유 브리지를 만들면 복잡도만 폭증 | 셔플 엔진 로직을 두 번 작성하는 중복. 대신 테스트 벡터·골든 케이스로 동작 동등성 보장 | (a) Ruby gem으로 엔진 공통화 — 모바일이 Dart라 무의미 (b) gRPC/API로 서버가 셔플 전담 — 모바일 오프라인-퍼스트 깨짐 |
| 3 | **모듈 디렉토리 구조** | `app/{controllers,models,services,views}/tarot/*` Rails autoload 규약 기반 namespace. `app/views/tarot/draws/*.html.erb` | Rails 8+ Zeitwerk가 namespace를 디렉토리 트리로 강제. 별도 엔진(engine)을 뽑으면 과공학. 기존 `admin/` 패턴과 일관 | 타로만 위한 Rails engine(`packages/tarot_engine`)보다 결합도 높음. 추후 엔진 추출 시 리팩터 필요 | (a) Rails engine으로 분리 — 현 규모에서 YAGNI (b) 평면 + prefix 네이밍(`TarotDrawController`) — 컨벤션 위반 |
| 4 | **셔플 엔진 구현** | Ruby `SecureRandom` + Fisher-Yates. 서비스 객체 `Tarot::ShuffleService.call(deck:, seed: nil)`. seed 지정 시 결정론, 미지정 시 `SecureRandom.bytes` 엔트로피 | 모바일 RNG 연구(`055_Scope_rng_implementation`) 결과가 CSPRNG+Fisher-Yates. Ruby `SecureRandom`은 OS 엔트로피(OpenSSL/urandom) 기반 CSPRNG로 동등. 서버사이드 셔플은 결과 재현성과 감사 로그(드로우 기록) 모두 만족 | 클라이언트-사이드 "손의 움직임이 결과에 영향" 같은 제의적 UX 상실. 대신 시드를 세션+타임스탬프 해시로 "사용자 고유성" 표현 | (a) 클라 JS로 셔플 — 결과 위변조/디버그 어려움 (b) Ruby 자체 Mersenne Twister — CSPRNG 아님 |
| 5 | **셔플/컷 UX 모델** | 3단계 Turbo Stream 플로우: ①셔플(버튼/드래그 인터랙션 후 서버가 순열 고정) → ②컷(스택 분할 제스처 or 스킵) → ③픽(스프레드 포지션만큼 선택). 각 단계 전환은 Turbo Frame 부분 교체 | Hotwire/Turbo가 기존 스택. SPA 전환(React 등) 도입은 과공학. Turbo Streams면 전체 리로드 없이 단계 UX 달성. 드래그는 Stimulus 컨트롤러 | 3D 물리 셔플 시각 효과는 포기. CSS transform + 카드 스택 flip 정도만 | (a) 풀 SPA(Vue/React) — 프로젝트 일관성 깨짐 (b) 비동기 페이지 이동 — Turbo 대비 UX 열등 |
| 6 | **결과 공유 모델** | 드로우 생성 시 `shareable_token`(nanoid 21자) 부여. 공개 URL `/tarot/draws/:token`. 소유자는 `anonymous_session_id` 또는 `user_id`로 식별 | 웹 고유 강점 중 하나. 로그인 없이도 "친구에게 이 결과 보여주기" 가능. 토큰은 추측 불가 길이로 비의도적 노출 방지 | URL 유출 시 내용 열람 가능(의도된 동작). 프라이빗 모드는 후속에서 플래그 추가 | (a) 결과 페이지를 내부 세션에만 — 공유 불가로 웹 특성 포기 (b) 짧은 ID(4-6자) — 무작위 추측 가능 |
| 7 | **MVP 스프레드 범위** | 원 카드 + 3카드(과거/현재/미래) 2종. 추가 스프레드는 `Tarot::Spread` 엔티티에 레이아웃 스키마만 확장하면 되도록 설계 | 78개 셔플 문서 중 레이아웃 연구(`docs/2_tarot_draw/03_draw_experience_settings/005_Brief_layout_redesign.md`)가 슬롯 기반 확장 가능 설계. 원카드는 가장 낮은 진입 장벽, 3카드는 가장 보편적. 켈틱 크로스(10장) 등은 UX 복잡도 큼 | 풍성한 타로 경험 포기. 대신 단단한 기반으로 후속 스프레드 추가 비용 최소화 | (a) 켈틱 크로스 포함 — MVP 복잡도 초과 (b) 원 카드만 — 웹 드로우 단조 |
| 8 | **덱 데이터 시드** | `db/seeds/tarot/universal_waite.json`으로 78장 고정 시드. `rails db:seed` 또는 `rake tarot:seed`로 주입. 이미지는 `app/assets/images/tarot/universal_waite/*.jpg` (Rails asset pipeline) | Universal Waite는 퍼블릭 도메인. JSON이 덱 추가 시 PR만으로 가능하게 함. ActiveStorage는 단순 정적 이미지에 과공학 | 덱 관리 UI가 없어서 CMS 느낌은 아님. Admin 확장은 Out of Scope로 명시 | (a) DB에 직접 insert 스크립트 — 버전 관리 어려움 (b) ActiveStorage로 이미지 — 정적 자산에 불필요한 복잡도 |
| 9 | **세션/소유권 모델** | 기존 `AnonymousSession` 재사용. `Tarot::Draw`가 `belongs_to :owner, polymorphic: true` 또는 `anonymous_session` + `user`(nullable) 패턴. 로그인 시 익명 드로우 승계 서비스(`Tarot::OwnershipTransferService`) | MBTI와 동일 패턴 유지가 일관성·학습비용 최소화. polymorphic은 쿼리 복잡 → 2개 nullable FK 선호 | polymorphic의 유연성 포기. 후속에 소유자 타입 늘어나면 리팩터 | (a) 로그인 필수 — 타로 드로우 즉시성 상실 (b) polymorphic owner — 기존 코드 패턴과 괴리 |
| 10 | **리딩 내러티브 정적성** | MVP는 카드 정/역방 기본 의미 + 스프레드 포지션 의미의 정적 조합. AI 내러티브 연동은 `docs/5_ai/01_tarot_chat`에서 별도 처리 | AI 연동은 별도 토픽 + 비용·레이턴시 이슈. 정적 해석도 데이터만 잘 시드하면 충분한 가치 제공 | 개인화·깊이 있는 해석 부족 | (a) 처음부터 AI — 범위·비용 폭증 (b) 해석 없음 — 기능 미완 |
| 11 | **리딩 데이터 로컬라이즈 소스** | `tarot_card_meanings` 테이블에 (card_id, orientation, position_role, locale, text) 컬럼 구성. 한국어만 시드 | i18n 확장 가능 구조를 미리 마련하되 번역은 나중. 모바일 덱 자산과 동일 스키마로 맞출 여지 확보 | 번역 준비 오버헤드 | (a) Hash/YAML 상수 — DB 쿼리 유연성 포기 (b) 카드 모델에 직접 컬럼 — 확장 시 migration 폭증 |
| 12 | **Admin UI 경로** | MVP에서는 Admin UI 신설하지 않음. 기존 `namespace :admin`에 `tarot/*` 추가는 후속 토픽 | MVP에서 덱 관리는 seed/rake로 충분. Admin은 별도 UX/권한 설계 필요 | 운영자가 코드 배포 없이 덱 수정 불가 | (a) Admin 같이 구축 — 범위 폭증 |

## Open Questions

| # | Question | Impact | Status |
|---|----------|--------|--------|
| — | (없음 — 주요 결정 모두 자율 결정 완료) | — | — |

## Constraints

- **스택**: Rails 8+, PostgreSQL, RSpec, Hotwire/Turbo, Tailwind CSS. 이탈 금지.
- **보안**: 셔플은 서버 전용(`SecureRandom`). 클라 RNG 사용 금지. 공유 토큰은 추측 불가 길이.
- **개인정보**: 익명 세션 드로우는 기존 `AnonymousSession` retention 정책 준수. `deletion_requests` 플로우에 타로 드로우 삭제 연계.
- **성능**: 셔플·드로우 한 번당 DB 쓰기 최소화(단일 `Tarot::Draw` INSERT + `Tarot::DrawCard` 78장 중 뽑힌 n장만). 페이지 TTFB 500ms 이하 목표.
- **접근성**: WCAG AA. 키보드 내비게이션으로 셔플·픽 가능. 카드 이미지에 alt 텍스트. 색각 의존 금지.
- **저작권**: Universal Waite(1910)는 퍼블릭 도메인. 현대 브랜드 덱 사용 금지.
- **MBTI 격리**: 타로 라우트/컨트롤러/모델이 기존 MBTI 코드를 수정하지 않음. 공통 레이아웃(`layouts/application.html.erb`), 헤더/푸터, `ApplicationController`, `AnonymousSession` 이외 파일 변경 없음.

## Exit Criteria

- Brief가 `Tarot::` namespace, 모듈 경계, 모바일-웹 공유 전략, 셔플 엔진 방향, 스프레드 범위, 덱 시드, 공유 모델, 세션 모델을 모두 결정 상태로 포함한다.
- In/Out Scope 경계가 명확하며, In Scope 12개 항목 각각이 scope 단계에서 기술 분석 가능한 granularity다.
- Model Anchors가 모든 주요 결정을 falsifiable 지시로 번역한다.
- 모바일 프레임(레이어링·엔티티·스프레드 스키마)과 웹 특성(URL 공유·Turbo·익명 세션·SEO) 양쪽이 명시된다.

## Ideal Criteria

Quality Profile: **Standard** (요청 텍스트에서 "프로덕션/데모/프로토타입" 키워드 없음, Standard 기본 적용). Priority Dimensions: **Function + UX**(모듈화·웹 특성 살리기 강조 — UX 축 1단계 상향 유지).

| # | Criterion | References (In Scope #) | Type | Dimension |
|---|-----------|------------------------|------|-----------|
| 1 | 기존 `/` 루트 및 MBTI 라우트(`/assessments/*`, `/results/*`)가 타로 도입 전후로 동일하게 동작한다 | #1 | assertion | Robustness |
| 2 | `/tarot/*` 네임스페이스 하위 라우트만으로 타로 전체 플로우(드로우 생성→셔플→픽→결과 공유) 완결된다 | #1, #2 | assertion | Function |
| 3 | `app/controllers/tarot/`, `app/models/tarot/`, `app/services/tarot/`, `app/views/tarot/` 디렉토리에 namespace 규약대로 파일이 배치되고 Zeitwerk autoload가 정상 동작한다 | #3, #4 | assertion | Function |
| 4 | `Tarot::ShuffleService`는 동일 시드 입력 시 동일 카드 순열을 반환한다(결정성 테스트) | #5 | assertion | Robustness |
| 5 | `Tarot::ShuffleService`는 시드 미지정 시 `SecureRandom` 기반 엔트로피로 순열을 생성하며, 1000회 반복에서 통계적 편향이 검출되지 않는다 | #5 | assertion | Robustness |
| 6 | 원 카드·3카드 스프레드 각각이 드로우 생성→뷰 렌더링까지 동작하며, 스프레드 추가는 새 `Tarot::Spread` 레코드와 뷰 파셜 추가만으로 가능하다 | #6 | assertion | Function |
| 7 | Universal Waite 78장이 `db:seed` 실행만으로 `tarot_decks`/`tarot_cards`에 주입되고, 각 카드의 이미지·정방 의미·역방 의미가 조회된다 | #7, #11 | assertion | Function |
| 8 | 셔플→컷→픽 플로우가 Turbo Frame/Stream으로 전체 리로드 없이 진행되며, 키보드(Tab/Enter/Space)만으로 완결 가능하다 | #8 | assertion | UX |
| 9 | 셔플/픽 과정의 모션과 상태 변화가 사용자에게 "결과가 방금 결정된다"는 제의적 인지를 제공하는가? (정적 리스트 나열이 아닌 단계적 전개) | #8 | directional | UX |
| 10 | 드로우 결과가 고정 URL `/tarot/draws/:token`로 접근 가능하며, 비로그인 브라우저/시크릿 창에서 열람된다 | #9 | assertion | Function |
| 11 | 공유 URL 페이지가 OG meta(title, description, image)를 포함하고, `robots` 메타로 기본 비인덱싱(정책 옵션) | #11 | assertion | Function |
| 12 | 로그인 없는 사용자가 드로우를 생성·조회할 수 있고, 이후 로그인 시 기존 익명 드로우가 해당 유저 소유로 승계된다 | #10 | assertion | Function |
| 13 | 익명 타로 드로우가 기존 `deletion_requests` 흐름으로 삭제 가능하다 | #10 | assertion | Robustness |
| 14 | RSpec 요청/모델/서비스 스펙이 존재하고, 셔플 결정성·owner 승계·공유 토큰 접근의 핵심 경로를 커버한다 | #12 | assertion | Completeness |
| 15 | WCAG AA 기준을 충족한다: 색상 대비, 키보드 내비게이션, 카드 이미지 alt, 포커스 표시 | #8 | assertion | UX |
| 16 | MBTI 기존 경험(진단→결과)을 사용하는 사용자가 타로 경험이 별개 플로우임을 헤더/네비에서 즉시 인지 가능한가? | #1, #8 | directional | UX |

## Model Anchors

### 라우팅 및 namespace 경계

- `config/routes.rb`에 `namespace :tarot do ... end` 블록을 추가하되, 기존 `resources :assessments`, `resources :results`, `namespace :admin`는 수정하지 않는다. 블록 위치는 `resources :deletion_requests` 다음, `namespace :admin` 앞(주제 인접성) 또는 `namespace :admin` 뒤 중 하나로 일관되게 배치한다.
- 타로 컨트롤러는 모두 `Tarot::` 하위에 둔다. 예: `Tarot::DrawsController`, `Tarot::ReadingsController`, `Tarot::DecksController`(필요 시).
- 타로 URL helper는 `tarot_*` 접두어를 가진다. 예: `tarot_draws_path`, `new_tarot_draw_path`, `tarot_draw_path(@draw)`.

### 모듈 디렉토리 구조 (Zeitwerk autoload 준수)

- `app/controllers/tarot/*.rb`
- `app/models/tarot/*.rb` (예: `Tarot::Draw`, `Tarot::Deck`, `Tarot::Card`, `Tarot::Spread`, `Tarot::DrawCard`, `Tarot::CardMeaning`)
- `app/services/tarot/*.rb` (예: `Tarot::ShuffleService`, `Tarot::DrawService`, `Tarot::ReadingAssemblerService`, `Tarot::OwnershipTransferService`)
- `app/views/tarot/{draws, readings, shared}/*.html.erb`
- `app/helpers/tarot/*.rb` (필요 시)
- 파일 내부는 `module Tarot; class Draws < ApplicationController; end; end` 또는 Rails convention `class Tarot::DrawsController < ApplicationController` 중 프로젝트 기존 스타일을 따른다. `admin/` 하위 현 파일 컨벤션을 확인하여 일치시킨다.

### 테이블 네이밍

- 모든 타로 테이블은 `tarot_` 접두어. 예: `tarot_draws`, `tarot_decks`, `tarot_cards`, `tarot_spreads`, `tarot_draw_cards`, `tarot_card_meanings`.
- 모델은 `self.table_name = "tarot_draws"` 명시 불필요(Rails가 `Tarot::Draw` → `tarot_draws`로 자동 변환).

### 셔플 엔진 계약

- `Tarot::ShuffleService.call(deck:, seed: nil) → [Card, ...]` 순열 배열 반환.
- seed가 nil이면 `SecureRandom.bytes(16)` 기반 결정 후 사용된 seed를 `Tarot::Draw#shuffle_seed`로 저장(감사·재현 목적).
- seed 제공 시 `Random.new(seed_int)` 사용, 알고리즘은 Fisher-Yates(1회 패스). 정/역방 결정은 셔플 후 각 카드별 독립 bit(동일 RNG stream) 소비.
- 클라이언트 JS로 셔플 연산 금지. Stimulus 컨트롤러는 UI 인터랙션(드래그·버튼)만 담당하고 결과 순열은 항상 서버 응답.

### UX 플로우 계약

- 경로: `new_tarot_draw_path` → 스프레드 선택 → `create` (POST, `Tarot::DrawsController#create`) → `show` with Turbo Frames로 셔플→컷→픽 단계적 전개.
- 각 단계는 Turbo Stream 응답으로 프레임을 교체하고 전체 페이지 리로드 발생시키지 않는다.
- 키보드 접근성 필수: 모든 인터랙션을 Tab/Enter/Space/Arrow 키로 완결 가능.
- 3D/물리/햅틱/가속도 API 사용 금지. CSS transform, Web Animations API, Tailwind 애니메이션 유틸리티만 사용.

### 공유 URL 계약

- `Tarot::Draw#shareable_token`: nanoid 21자 (또는 `SecureRandom.urlsafe_base64(16)`). 인덱스 unique.
- `GET /tarot/draws/:token`로 접근 가능. `Tarot::DrawsController#show`에서 `params[:id]` 대신 `params[:token]`을 사용하거나 `to_param` 오버라이드.
- 공유 페이지에 OG meta(title, description, image URL). `robots: noindex, nofollow` 기본(후속 플래그로 변경 가능).

### 소유권·세션 계약

- `Tarot::Draw`는 nullable `user_id`와 nullable `anonymous_session_id` 양쪽을 가진다(XOR 체크 제약).
- 익명 사용자 드로우 생성: 현재 세션의 `AnonymousSession.id`를 FK로 기록.
- 로그인 시 `Tarot::OwnershipTransferService.call(anonymous_session:, user:)` 호출하여 해당 세션의 모든 드로우의 `user_id`를 채우고 `anonymous_session_id`는 그대로 유지(감사 목적) 또는 nullify(정책 결정은 scope 단계).
- `DeletionRequest` 플로우에 타로 드로우 삭제 훅 추가(scope에서 구체화).

### 덱 데이터 계약

- `db/seeds/tarot/universal_waite.json` 단일 파일. 스키마: `{ deck: { name, code: "universal_waite", license, language }, cards: [{ code: "major_00_fool", name_ko, name_en, arcana, suit, rank, image, upright_meaning, reversed_meaning, position_meanings? }, ...] }`.
- 이미지는 `app/assets/images/tarot/universal_waite/{major_00_fool,...}.jpg` 78장.
- `rails db:seed` 또는 `bin/rails tarot:seed` rake task 제공.
- 모바일 덱 JSON과 스키마 호환(최소 공통 필드: code, arcana, suit, rank, image path)으로 후속 통합 여지 확보.

### MBTI 격리 계약

- 기존 `ApplicationController`를 수정할 경우 타로·MBTI 공통 이익이 있는 범위로 한정(예: `AnonymousSession` 조회 helper). 타로 전용 로직은 `ApplicationController`에 추가 금지.
- `layouts/application.html.erb`에 타로 진입 링크를 추가하는 것은 허용. 기존 레이아웃 구조 변경은 금지.
- 기존 MBTI 컨트롤러/모델/서비스 파일 수정 금지.

### 비범위 명시

- 모바일 앱 동기화, AI 타로챗, 커스텀 덱 업로드, 복수 덱 전환, 3D/햅틱, Admin UI, 결제, 번역 확장은 Out of Scope. 이들 중 어느 것도 MVP 구현 요청에 포함되면 거부하고 별도 scope 요청 유도.

## Critique Integration

(--deep 모드 아님 — 이 섹션은 비어있음)
