---
id: "003"
title: "Current Rails Stack Assets & Constraints"
category: agent
status: complete
created: 2026-04-24
summary: >
  Rails 8.1 HTML-first Hotwire app with SQLite (Solid stack), ~5.4k Ruby LOC,
  15 models, 13 controllers, 20 services, 27 ERB views, 8 Stimulus controllers,
  18 RSpec files. No prod DB on disk. No API endpoints. Core business value
  concentrated in ~1,850 LOC of scoring/profiles/insights/compliance services —
  portable. HTML/Hotwire UI, ActiveRecord encryption, SQLite JSON columns, and
  Solid Queue/Cache/Cable are non-portable and require full rewrite or substitution.
model: "sonnet"
reasoning_depth: "standard"
confidence: high
keywords: [agent-report, rails, sqlite, hotwire, solid, migration-feasibility]
---

# Current Rails Stack Assets & Constraints

## Progress
### Completed
- [x] Gemfile inventory
- [x] Config survey
- [x] Schema analysis
- [x] 11 models analyzed (15 total — 4 more than brief listed)
- [x] Controllers analyzed (8 app + 5 admin = 13 total)
- [x] Views/Stimulus/Hotwire quantified
- [x] Solid Queue/Cable actual-usage check
- [x] Test coverage survey
- [x] Kamal deploy config
- [x] SQLite production DB size
- [x] Non-portable idiom inventory

### Remaining
(none)

### Current Status
Complete.

## Summary

The server is a Rails 8.1.2 monolith that renders HTML via ERB + Hotwire (Turbo Frames + Stimulus), backed by SQLite with the Solid stack (Solid Queue / Solid Cache / Solid Cable) on three additional SQLite databases. Deploy is Kamal + Thruster to a single VM with a persistent Docker volume mounted at `/rails/storage`.

**Scale is modest**: 5,448 Ruby LOC in `app/`, 1,788 ERB LOC, 340 JS LOC. 15 models, 13 controllers, 20 service objects, 27 ERB templates, 8 Stimulus controllers, 18 RSpec files (~2,600 test LOC). 17 route declarations, all HTML-only — **there is no JSON API**.

**The portable core** is ~1,850 LOC of pure-function-ish service objects under `app/services/` (scoring, profiles, insights, quality, compliance). These contain the business value (psychometric calculations, type classification, policy enforcement, deletion cascade) and translate cleanly to TypeScript. They have no web/ORM concerns beyond reading `assessment.responses` and calling `.save!` on records.

**The non-portable surface** is the HTML UI layer (Hotwire Turbo Frame navigation in the assessment flow, Stimulus controllers, ERB templates all written in Korean/Tailwind), `ActiveRecord::encrypts` on `User#email/display_name`, SQLite `t.json` columns used heavily (9 columns across 5 tables), `http_basic_authenticate_with` for admin, and cookie-based anonymous sessions via Rails' session store.

**No production data exists on this machine**: `storage/production.sqlite3` is absent; only `development.sqlite3` (300 KB) and `test.sqlite3` (244 KB) exist. **Migration is effectively greenfield from a data perspective.**

**Zero background-job usage**: `app/jobs/` contains only the generated `ApplicationJob` base class. Solid Queue is configured in `deploy.yml` (`SOLID_QUEUE_IN_PUMA=true`) but nothing enqueues. The single recurring task is a `SolidQueue::Job.clear_finished_in_batches` self-cleanup. Scoring pipeline runs **inline** inside `ResultsController#show` (comment at `app/controllers/results_controller.rb:45-46` confirms `ScoringJob.perform_later` is commented out for MVP).

**Zero Action Cable usage**: no `app/channels/` directory exists. Solid Cable is configured but nothing broadcasts.

## Details

### Gemfile & Dependencies

**Rails 8.1.2** with the default Rails 8 Omakase stack. Key production gems:

| Gem | Version | Migration impact |
|-----|---------|------------------|
| rails | 8.1.2 | Replace entirely |
| sqlite3 | 2.9.0 | Replace with D1 driver |
| puma | 7.2.0 | Not applicable in Workers |
| propshaft | 1.3.1 | Not applicable (Workers has no asset pipeline) |
| importmap-rails | (pinned) | Replace with bundler / CF static |
| turbo-rails | (pinned) | Replace with SPA or MPA-style server HTML (no direct equivalent) |
| stimulus-rails | 1.3.4 | JS library — Stimulus itself CAN run client-side, but Rails-generated boot code cannot |
| tailwindcss-rails | 4.4.0 | Replace with standalone Tailwind build |
| bcrypt | 3.1.21 | D1 / Workers can use `@noble/hashes` or `bcryptjs` |
| solid_cache / solid_queue / solid_cable | (all unused in code) | Drop — no actual usage |
| kamal | 2.10.1 | Not applicable (Workers = serverless) |
| thruster | 0.1.18 | Not applicable |
| image_processing | 1.14.0 | Declared but unused (no Active Storage attachments in schema) |
| pg | 1.6.3 | Declared for `:production` group but production uses SQLite per `database.yml` — **dead weight** |

**Dev-only gems worth noting**: rspec-rails, factory_bot_rails, faker, brakeman, bundler-audit, debug, web-console, **tidewave (MCP bridge)**.

Gemfile.lock has 492 lines — moderately sized dep tree (~150 direct+transitive gems), standard for a Rails 8 fresh install.

### Configuration Files

| File | Purpose | Migration relevance |
|------|---------|---------------------|
| `config/application.rb` | Rails boot + **AR encryption keys** required via ENV in prod | Encryption keys move to Workers Secrets; must re-encrypt existing data (none exists) |
| `config/database.yml` | SQLite 4-database setup: primary + cache + queue + cable | Only primary matters for D1; cache/queue/cable drop |
| `config/cable.yml` | Solid Cable in prod, async in dev | Drop entirely — no channels |
| `config/cache.yml` | Solid Cache with 256MB cap | Drop — use Workers KV or skip |
| `config/queue.yml` | Solid Queue worker config | Drop — use CF Queues or Cron Triggers if needed |
| `config/recurring.yml` | One task: clear_solid_queue_finished_jobs | Drop with queue |
| `config/deploy.yml` | Kamal → `192.168.0.1`, docker registry `localhost:5555`, persistent volume `personality_storage:/rails/storage` | Replace entirely with `wrangler.toml` |
| `config/importmap.rb` | 4 pins (turbo, stimulus, stimulus-loading, controllers) | Replace with ESM bundler for SPA OR keep importmap-style if MPA on Workers |
| `config/environments/production.rb` | Standard Rails 8 production | Not applicable |
| `config/initializers/*.rb` | Only 4 initializers, all near-default (content_security_policy fully commented out) | Minimal — CSP + filter_parameter_logging + inflections + assets |
| `config/credentials.yml.enc` + `master.key` | Encrypted credentials | Migrate secrets to Workers Secrets |

**Admin password and AR encryption keys are ENV-driven in production** (`ADMIN_PASSWORD`, `AR_ENCRYPTION_PRIMARY_KEY`, `AR_ENCRYPTION_DETERMINISTIC_KEY`, `AR_ENCRYPTION_KEY_DERIVATION_SALT`) — see `config/application.rb:43-45` and `app/controllers/admin/base_controller.rb:7`.

### Database Schema

**14 tables, 220 lines in `db/schema.rb`**, schema version `2026_02_22_000005`. 20 migration files totaling 244 LOC.

Tables (row counts unknown — no prod DB present):

| Table | Columns | Indexes | FKs | JSON cols | Notes |
|-------|---------|---------|-----|-----------|-------|
| `alerts` | 10 | 2 | 0 | `metadata` | Admin monitoring |
| `anonymous_sessions` | 9 | 2 | user | — | Cookie-session backing; `session_token` UUID |
| `assessments` | 13 | 2 | session, question_set | — | Core state machine |
| `audit_logs` | 8 | 2 | polymorphic actor & resource (strings only, no FK) | `metadata` | Compliance trail |
| `consents` | 10 | 2 | session, user | — | GDPR-ish consent tracking |
| `deletion_requests` | 7 | 3 | session | — | GDPR deletion |
| `domain_scores` | 10 | 2 | assessment | — | Unique (assessment_id, domain) |
| `insights` | 6 | 2 | profile | `suggestions` | Unique (profile_id, context) |
| `personality_types` | 15 | 1 | — | `strengths`, `caution_patterns` | Seed data (16 MBTI-like codes) |
| `profiles` | 13 | 4 | session, assessment, personality_type | `score_vector`, `strengths`, `caution_patterns`, `suggested_actions` | Unique per assessment |
| `question_sets` | 5 | 1 | — | — | Versioning |
| `questions` | 10 | 2 | question_set | — | Unique (set, domain, position) |
| `responses` | 8 | 3 | assessment, question | — | Unique (assessment, question) |
| `users` | 7 | 1 | — | — | `email` deterministic-encrypted |

**14 foreign keys** declared — straightforward one-to-many and one-to-one. **No polymorphic associations via Rails** (AuditLog fakes it with string `actor_type/resource_type` columns, but there's no `belongs_to :actor, polymorphic: true` — the string just stores a type label and `AuditLog.record!` never dereferences it). **No STI.** **No Active Storage / Action Text tables** (just dead-weight gem inclusions).

**9 JSON columns** across 5 tables: `alerts.metadata`, `audit_logs.metadata`, `insights.suggestions`, `personality_types.caution_patterns` + `strengths`, `profiles.score_vector` + `strengths` + `caution_patterns` + `suggested_actions`. SQLite `t.json` stores text and Rails serializes — **D1 preserves this exactly (both are SQLite), and Rails' JSON handling is automatic at the AR layer, so any replacement ORM must handle JSON (de)serialization**.

### Domain Models (per-model analysis)

All 15 models read; brief said 11 — the extras are `application_record`, plus models in `concerns/` folders (which are empty). Summary by model:

| Model | Assocs | Validations | Callbacks | Scopes | Special | Port difficulty |
|-------|--------|-------------|-----------|--------|---------|-----------------|
| `Alert` | none | 3 inclusions | none | 2 | state-machine-like bang methods | **Easy** |
| `AnonymousSession` | belongs_to user (optional), 4 has_many dependent:destroy | token unique | `before_validation :generate_session_token` | — | SecureRandom.uuid | **Easy** |
| `ApplicationRecord` | — | — | — | — | `primary_abstract_class` | **Easy** (boilerplate) |
| `Assessment` | 2 belongs_to, 2 has_many, 1 has_one, all `dependent: :destroy` | status inclusion | `before_validation :set_defaults` (5 defaults) | 2 | 4 bang state methods, progress_percentage calc | **Easy-Medium** |
| `AuditLog` | — | action presence | — | 2 | class method `self.record!` — used by DeletionProcessor | **Easy** |
| `Consent` | 2 belongs_to optional | 3 inclusions + custom `has_session_or_user` | — | 2 | `revoke!` | **Easy** |
| `DeletionRequest` | belongs_to session | token unique + inclusion | `before_validation :set_defaults` | 2 (incl. `overdue`) | 3 bang methods | **Easy** |
| `DomainScore` | belongs_to | domain inclusion + scoped unique + numeric range | — | 1 | — | **Easy** |
| `Insight` | belongs_to profile | context inclusion + scoped unique | — | 1 | — | **Easy** |
| `PersonalityType` | `has_many profiles, dependent: :restrict_with_error` | code inclusion + unique | — | — | 16 valid codes enum array | **Easy** |
| `Profile` | 3 belongs_to, 1 has_many | assessment_id unique | — | — | **`delegate` of 8 attrs to `personality_type`** | **Easy** (delegates become helper fns) |
| `Question` | belongs_to, has_many | 4 inclusions / presence | — | 3 | — | **Easy** |
| `QuestionSet` | has_many questions (destroy), has_many assessments (restrict) | status inclusion | — | 1 | `self.current`, `activate!` with transaction | **Easy** |
| `Response` | 2 belongs_to | value 1..5, scoped unique | — | 3 (incl. `for_domain` join) | — | **Easy** |
| `User` | `has_secure_password`; 2 has_many | email regex + unique | — | 1 | **`encrypts :email, deterministic: true` + `encrypts :display_name`** | **Medium** — requires crypto scheme change |

**No concerns, no polymorphic, no STI, no Active Storage attachments, no Action Text, no broadcasts_to, no enums (they use string validation arrays instead).**

**Callbacks are minimal**: only 3 models have them, all `before_validation` for default-setting. No chains, no side effects, no cross-model callbacks.

**The `User.encrypts` (lines 4-5)** is the only non-trivial Rails-specific data concern. It uses ActiveRecord::Encryption with three separate keys (primary, deterministic, salt) — deterministic mode on `email` supports lookup by email. Any migration needs equivalent AES-GCM encryption with deterministic IV derivation on email.

### Controllers (per-controller analysis)

**13 controllers, ~500 Ruby LOC total**. All HTML-only — no `respond_to` with JSON branches, no API namespace.

| Controller | Actions | LOC | Complexity | Strong params | Rewrite difficulty |
|-----------|---------|-----|------------|---------------|--------------------|
| `ApplicationController` | `require_session!`, `current_session` helper | 32 | cookie session → AnonymousSession lookup | — | **Easy** |
| `AccountsController` | new, create | 28 | User.new → save → link session | `:email, :password, :password_confirmation` | **Easy** |
| `AssessmentQuestionsController` | show, update | 49 | find-or-init Response, save, advance index, redirect next/submit | `:value, :response_time_ms` | **Easy** |
| `AssessmentsController` | create, show, submit | 50 | state transitions, inline scoring trigger | — (no params) | **Easy** |
| `ConsentsController` | new, create, show, update | 61 | consent text versioning, default Korean strings | `:consent_type, :version, :granted` | **Easy** |
| `DeletionRequestsController` | new, create, show | 31 | DeletionRequest.build, save | — | **Easy** |
| `ResultsController` | show | 73 | **Orchestrates 8-step scoring pipeline inline in a transaction** | — | **Medium** (business logic + transaction + rescue) |
| `SessionsController` | new, create | 38 | SHA256 fingerprint, cookie set, auto-create assessment | — | **Easy** |
| `Admin::BaseController` | — | 13 | `http_basic_authenticate_with` + `skip_before_action :require_session!` | — | **Easy** (Basic Auth is trivial) |
| `Admin::DashboardController` | index, completion_rates, drop_off_analysis | 38 | **Raw SQL string aggregates** (`"SUM(CASE WHEN status='completed' ...)"`), `group(:question_set_id)` | — | **Medium** (SQL via ORM) |
| `Admin::QuestionSetsController` | full CRUD (7 actions) | 62 | standard Rails CRUD | `:name, :version, :active` (**bug: model doesn't have these fields — see Findings**) | **Easy** |
| `Admin::AlertsController` | index, show, update | 37 | standard | `:status, :resolved_at, :notes` | **Easy** |
| `Admin::AuditLogsController` | index, show | 19 | filter by params | — | **Easy** |

Admin auth is HTTP Basic via `ENV["ADMIN_USERNAME"]` / `ENV["ADMIN_PASSWORD"]` — no session, no user table for admins.

**The only non-trivial controller** is `ResultsController#show`, which orchestrates the scoring pipeline inline inside `ActiveRecord::Base.transaction` and calls 8 services in sequence (file: `app/controllers/results_controller.rb`, lines 20-67). This is where backend business logic concentrates at the HTTP layer. Everything else is standard Rails CRUD.

### Views & Hotwire Complexity

**27 ERB files, 1,788 LOC**. Breakdown:

- `layouts/`: 4 files (application, admin, mailer.html, mailer.text)
- `accounts/`: 1 (new)
- `admin/`: 9 (dashboard/index, alerts/index+show, audit_logs/index+show, question_sets/ x4)
- `assessments/`: 1 (show)
- `assessment_questions/`: 2 (show, _question)
- `consents/`: 1 (new)
- `deletion_requests/`: 2 (new, show)
- `results/`: 5 (show, _insight_card, _spectrum, _trust_notice, _type_hero)
- `sessions/`: 1 (new)
- `pwa/`: manifest.json.erb + service-worker.js (static PWA shell)

**Turbo Frame usage**: limited to the assessment question flow (2 files — `assessments/show.html.erb` and `assessment_questions/_question.html.erb`). The `<turbo-frame id="current_question">` is used to hot-swap questions without full page reload. The flow is: `likert#submit` → `requestSubmit()` → form POST → controller redirect → Turbo catches the new `<turbo-frame id="current_question">` and substitutes.

**No Turbo Stream usage** (no `turbo_stream.*` or `broadcasts_to` anywhere in the codebase — grep confirmed).

**Stimulus controllers (8 files, 167 LOC)**:

| Controller | Purpose | LOC | Cross-port equivalence |
|------------|---------|-----|------------------------|
| `autosave` | Form autosave | 34 | Straightforward Alpine/Stimulus/React hook |
| `countdown` | Measures response time (timestamp diff) → hidden input | 20 | Trivial |
| `likert` | Radio select + auto-submit + skip | 23 | Trivial |
| `progress` | Progress bar | 14 | Trivial |
| `questionnaire` | Container controller | 12 | Trivial |
| `spectrum_bar` | Score bar animation | 15 | Trivial |
| `tabs` | Tab switcher for insight contexts | 26 | Trivial |
| `type_reveal` | Staggered letter reveal animation | 10 | CSS-only with keyframes |
| `application` / `index` | Stimulus boot | 13 | Boilerplate |

**All Stimulus logic is pure client-side DOM manipulation** — no Turbo-specific integration beyond `form.requestSubmit()`. If the new frontend uses any Stimulus-compatible runtime, these controllers port nearly verbatim. If the new frontend is React/Svelte/Vue, they translate to trivial ~10-30 LOC components each.

**ERB idioms that don't port directly**:

- `form_with model: @user, url: account_path` — Rails URL helpers (`account_path`, `assessment_question_path`, etc.) are generated from `routes.rb`. Any replacement needs a URL builder.
- `button_to "결과 확인하기", submit_assessment_path(@assessment), method: :patch, data: { turbo_frame: "_top" }` — generates a form-wrapped button with CSRF; Turbo Frame target directives are Hotwire-specific.
- `csrf_meta_tags`, `csp_meta_tag` — Rails-specific; a new framework must handle CSRF/CSP.
- `stylesheet_link_tag :app, "data-turbo-track": "reload"` / `javascript_importmap_tags` — Propshaft/importmap output; replace with framework's asset tag.
- `content_for`, `yield :navbar`, `flash[:notice]` — ERB/Rails conventions.
- Tailwind classes with dynamic interpolation (`bg-<%= domain_colors[question.domain] %>/20`) — works with Tailwind JIT only if colors are pre-declared in safelist; port carries the same constraint.

All UI copy is in **Korean** (`body_ko`, Korean labels, Korean flash messages). The 16 personality type definitions in `db/seeds.rb` are all Korean + English — 326 LOC of seed content is domain content, not migration work.

### Background Jobs, Cache, Cable (Solid stack actual usage)

**Background jobs**: `app/jobs/` contains only `application_job.rb` (8 LOC, generated). **No custom jobs exist.** Scoring, deletion, alerts — all run inline. Commented-out `ScoringJob.perform_later(@assessment.id)` and `DeletionJob.perform_later(@deletion_request.id)` in two controllers confirm the MVP-inline-execution design.

**Cache**: `config/environments/production.rb:50` sets `config.cache_store = :solid_cache_store`. Grep of `app/` shows **no `Rails.cache.fetch`, `Rails.cache.write`, `Rails.cache.read` calls anywhere**. Solid Cache is configured but unused.

**Cable**: `app/channels/` directory does not exist. No `broadcasts_to` anywhere. Solid Cable is configured in `cable.yml` for prod but **unused**.

**Recurring**: `config/recurring.yml` declares one task — `SolidQueue::Job.clear_finished_in_batches` every hour at :12. This is Solid Queue self-cleanup; if Solid Queue is dropped, this disappears too.

**Net impact**: all three extra SQLite databases (`production_cache.sqlite3`, `production_queue.sqlite3`, `production_cable.sqlite3`) and all three Solid gems can be **dropped without functional loss** in the migration. The migration target needs NO equivalent of these unless/until real background work is introduced.

### Testing

**18 RSpec files, 2,641 LOC**. Breakdown:

- **Model specs**: 2 (`assessment_spec.rb` 229 LOC, `personality_type_spec.rb` 106 LOC) — 13 models are untested at model level.
- **Request specs**: 2 (`full_flow_spec.rb` 187 LOC end-to-end happy path, `sessions_spec.rb` 58 LOC) — no per-controller request spec coverage.
- **Service specs**: 14 files, 1,961 LOC
  - scoring: 5 files (969 LOC) — **well-tested**
  - compliance: 4 files (683 LOC) — **well-tested** (includes a `snapshot_spec.rb`)
  - profiles: 2 (160 LOC)
  - quality: 2 (186 LOC)
  - insights: 1 (63 LOC) — only ContextEngine tested; 5 context modules untested
- **System/feature specs**: 0 (no Capybara, no browser tests).
- **Support**: `factory_bot.rb`, `assessment_helpers.rb`, `factories.rb`.

**Migration relevance**: service-layer tests are **pure logic tests** (inputs → outputs on service objects) and the assertions translate to any language. They constitute a valuable test suite to port — the scoring/compliance logic is well-specified. The full_flow request spec exercises the HTML + cookie flow and would need to be rewritten against the new HTTP surface.

### Deployment (Kamal)

`config/deploy.yml` (120 LOC):

- Service name: `personality`
- Target: single server `192.168.0.1` (placeholder IP — suggests the prod deploy target is not yet provisioned)
- Registry: `localhost:5555` (local dev registry — also not yet externalized)
- Volume: `personality_storage:/rails/storage` (SQLite DBs + Active Storage local files)
- `SOLID_QUEUE_IN_PUMA=true` — runs job workers in-process
- Builder arch: `amd64`
- Secrets: `RAILS_MASTER_KEY` (from `.kamal/secrets`)
- Aliases defined: `bin/kamal console`, `shell`, `logs`, `dbc`

**This is a single-node VM deployment** — not multi-region, no external DB, no CDN, no managed queue. Migration to CF Workers+D1 changes the whole operational model (serverless, eventually-consistent D1 globally, no volume, no `kamal console`).

### SQLite Production Observations

`server/storage/` contains:

| File | Size | Purpose |
|------|------|---------|
| `.keep` | 0 B | placeholder |
| `development.sqlite3` | 307,200 B (300 KB) | Dev DB — last modified 3/15 |
| `test.sqlite3` | 249,856 B (244 KB) | Test DB |
| `production.sqlite3` | **absent** | — |
| `production_cache.sqlite3` | **absent** | — |
| `production_queue.sqlite3` | **absent** | — |
| `production_cable.sqlite3` | **absent** | — |

**No production database exists on this machine.** This means:

1. No data migration work is required for the primary DB — a fresh D1 database created from `db/schema.rb` + `db/seeds.rb` replaces it.
2. The migration is effectively **greenfield for data**. Only the 16 PersonalityType seed records and any admin-authored QuestionSets need to be recreated.
3. No Active Storage blobs to migrate (no `active_storage_*` tables in schema).

### Rails/Ruby Idioms Not Portable (table with location & port difficulty)

| Idiom | Location | Port difficulty | Notes |
|-------|----------|----------------|-------|
| `ActiveRecord::Base.transaction do ... end` with rescue/redirect inside | `results_controller.rb:21`, `deletion_processor.rb:31`, `question_set.rb:17` | **Easy** | D1 has batch transactions; Hono/Drizzle support transaction closures. Logic is standard. |
| `has_secure_password` (bcrypt) | `user.rb:2` | **Easy** | bcryptjs / @noble/hashes in Workers; same hash format compatible. |
| `ActiveRecord::encrypts :email, deterministic: true` + `:display_name` | `user.rb:4-5` | **Medium** | Custom AES-GCM with deterministic IV derivation from email for lookup; 3 keys from ENV. No existing encrypted data to preserve. |
| `before_validation :generate_session_token` / `:set_defaults` | `anonymous_session.rb:11`, `assessment.rb:13`, `deletion_request.rb:10` | **Easy** | Simple default-setting; move into create handler or factory. |
| `delegate :character_name_ko, ..., to: :personality_type` | `profile.rb:11-13` | **Easy** | Manual getter functions or join-loaded helpers. |
| `dependent: :destroy` cascades | 7 associations across 6 models | **Easy** | D1 foreign keys support `ON DELETE CASCADE`, or enforce in app layer (DeletionProcessor already does this explicitly). |
| `scope :active, -> { where(...) }` | 14 scopes total | **Easy** | Reusable query builder functions. |
| Rails session cookie (`session[:session_token]`) | `sessions_controller.rb:25`, `application_controller.rb:16` | **Medium** | Workers needs signed cookies manually (Hono has cookie middleware with signing). Rails-style encrypted-by-default cookies need equivalent HMAC scheme. |
| `csrf_meta_tags` / `protect_from_forgery` implicit | ERB + ApplicationController inherited | **Medium** | Rails generates + verifies per-session CSRF tokens automatically. Must be replicated (Hono has middleware, but token lifecycle must be designed). |
| `http_basic_authenticate_with` | `admin/base_controller.rb:6` | **Easy** | Hono middleware equivalent in ~10 LOC. |
| `stale_when_importmap_changes` ETag | `application_controller.rb:6` | **N/A** | Rails 8-specific; drop. |
| `form_with model:`, URL helpers (`assessment_question_path`) | Every ERB | **Medium** | Replace with client/server URL-builder utility. |
| `button_to ..., method: :patch, data: { turbo_frame: "_top" }` | Multiple views | **Medium** | Turbo Frame semantics don't exist in non-Hotwire frontends. If migration includes replacing Turbo with SPA, these become standard links/fetches. |
| Turbo Frame (`<turbo-frame id="current_question">`) | `assessments/show.html.erb`, `assessment_questions/_question.html.erb` | **Hard (semantically)** | Requires decision: keep Hotwire pattern on CF Workers (possible but unusual) vs rewrite assessment flow as SPA vs plain form POSTs with full reload. Not a code-level port — an architecture choice. |
| Stimulus controllers | `app/javascript/controllers/*.js` | **Easy** | Pure client-side JS; Stimulus works anywhere. Or rewrite as ~10-30 LOC React/Svelte components. |
| ERB `<%= %>` with Tailwind interpolation | Views | **Medium** | Replace with framework templating. Tailwind safelist concerns identical. |
| `t.json` columns with AR serialization | Schema (9 columns) | **Easy** | D1 stores as TEXT; ORM (Drizzle/Kysely/raw) handles JSON.stringify/parse. |
| `AuditLog.record!` class method | `audit_log.rb:7`, used in deletion_processor | **Easy** | Free function. |
| `SecureRandom.uuid` / `SecureRandom.hex(16)` | 3 places | **Easy** | `crypto.randomUUID()` / `crypto.getRandomValues()` in Workers. |
| `Digest::SHA256.hexdigest` | `sessions_controller.rb:15` | **Easy** | Web Crypto `crypto.subtle.digest('SHA-256', ...)`. |
| `Time.current` / `Time.now.to_f` | Throughout | **Easy** | `new Date()` / `Date.now()`. |
| Raw SQL aggregates in Rails query: `group(:x).select("... SUM(CASE ...)")` | `admin/dashboard_controller.rb:17-25` | **Easy-Medium** | Raw SQL is portable to D1 directly; or convert to query builder. |
| `joins(:question).where(questions: { domain: ... })` | `response.rb:11`, `scoring/normalizer.rb:66-68` | **Easy** | Drizzle/Kysely support joins; or raw SQL. |
| `find_each` (batched iteration) | `deletion_processor.rb:38, 58` | **Easy** | Pagination loop. |
| `find_or_initialize_by` / `find_or_create_by!` | Multiple places | **Easy** | Small helper or standard ORM feature. |
| `pluck(:id)` | `deletion_processor.rb:101` | **Easy** | `SELECT id` list. |
| Rails' auto-CSRF + cookie signing + form builder | Implicit | **Medium** | Must be replicated end-to-end in new stack. |
| Pretendard font + Tailwind arbitrary-value classes | `layouts/application.html.erb:19-21` | **Easy** | Copy assets. |
| PWA shell (`pwa/manifest.json.erb`, `pwa/service-worker.js`) | Generated by Rails | **Easy** | Serve as CF Workers static responses. |

## Key Findings

### Critical

**C1. Production database does not exist on this machine.**  
Evidence: `server/storage/` ls confirms only dev + test SQLite files; no `production.sqlite3`.  
Implication: **Data migration is not a blocking concern**. The real migration work is **code + infrastructure**, not data extraction. Rails-to-CF is effectively a rewrite-from-scratch from a data standpoint, except for PersonalityType seed data (16 rows, 326 LOC of seed Ruby).

**C2. The mobile app does not consume this server today.**  
Evidence: Brief + `routes.rb` (zero API routes) + no controllers with `respond_to :json`.  
Implication: Migration has **no API contract to preserve** — unlike a typical rewrite. The only consumer is the web browser rendering HTML. This radically reduces risk and lets Cycle 2 design the new API surface fresh.

### High

**H1. Scoring + insights + compliance services are the portable core (~1,850 LOC).**  
Evidence: `app/services/{scoring,profiles,insights,quality,compliance}/*.rb`.  
These are pure-logic service objects (Pearson correlation, Spearman-Brown correction, reliability composites, tone-filter regex rules, restricted-term scanning) that translate cleanly to TypeScript and preserve semantic meaning. They already have 1,961 LOC of spec coverage. **This is the highest-leverage portion of the migration: port the services first, build the thin HTTP layer around them.**

**H2. Hotwire Turbo Frame is confined to 2 templates (assessment question flow).**  
Evidence: grep found only `assessments/show.html.erb` and `assessment_questions/_question.html.erb` with `<turbo-frame>`.  
Implication: Migration does not need to "replace Hotwire everywhere" — only this one flow has Hotwire semantics. Options: (a) keep form-submit-redirect behavior but do full-page reloads (loses the frame-swap smoothness but is trivial), (b) replace with fetch + DOM swap client-side (~30 LOC), (c) rewrite as SPA. Not a blanket architecture rewrite.

**H3. No background jobs actually run.**  
Evidence: `app/jobs/` contains only ApplicationJob; scoring pipeline is inline (`results_controller.rb:45-46` comment confirms this); no `perform_later` calls anywhere in `app/`.  
Implication: Solid Queue config, queue SQLite database, and `JOB_CONCURRENCY` ENV all vanish. Migration does not need CF Queues for MVP. Eventual needs: deletion processor (if async is desired) and scoring (if it gets slow) — both could use CF Queues or scheduled workers at that point.

**H4. No Action Cable channels exist.**  
Evidence: No `app/channels/` directory.  
Implication: Solid Cable and its SQLite database are dead weight. No WebSocket / SSE migration work. If realtime is ever needed on CF, Durable Objects or CF Pub/Sub are the primitives.

**H5. `User.encrypts :email` with deterministic mode is the only non-trivial data-layer transformation.**  
Evidence: `user.rb:4`, `application.rb:43-45`.  
This requires equivalent AES-GCM with deterministic IV derivation from email (so login-by-email still works on encrypted column). Since no prod data exists, re-encryption is not a migration concern — but the new impl must produce the same encryption scheme if backward compatibility with any existing test data is desired. Realistically: start over, pick your own scheme.

### Medium

**M1. AuditLog's "polymorphic" pattern is string-only — easy to port.**  
`actor_type` and `resource_type` are plain strings, not Rails polymorphic associations. `AuditLog.record!` doesn't dereference them. A D1 table with the same string columns is a 1:1 port.

**M2. Admin auth is HTTP Basic, not a user session.**  
`admin/base_controller.rb:6`. A Hono middleware (~10 LOC) replicates this. No admin-user table exists; admin credentials live in ENV.

**M3. `admin/question_sets_controller.rb:59` permits `:name, :version, :active` but the `question_sets` schema has only `status, version_code, created_at, updated_at`.**  
Pre-existing bug unrelated to migration — strong params reference nonexistent columns. Worth flagging for the rewrite: either fix during port or carry forward.

**M4. Admin dashboard uses raw SQL aggregate in a `.select()`.**  
`admin/dashboard_controller.rb:17-25`: `SUM(CASE WHEN status = 'completed' ...)`. Portable to D1 directly (same SQLite dialect), but any abstraction layer (Drizzle/Kysely) may not have this as an ergonomic helper — fall back to raw SQL in D1.

**M5. Dev-time `tidewave` gem (MCP bridge) and `pg` prod dependency are noise.**  
`pg` is declared in `:production` but `database.yml` uses SQLite everywhere. Likely a leftover from Rails generator defaults. Not migration-relevant, but flagging for cleanup.

### Low

**L1. 9 view files in `admin/` use standard Rails scaffolding.** Easy to replicate as plain HTML forms posting to Hono routes.

**L2. Content Security Policy initializer is fully commented out.** No CSP enforcement today. CF Workers sets headers via response — different mechanism, but same level of effort (low).

**L3. Non-portable Rails helpers like `button_to`, `form_with`, `csrf_meta_tags` appear in every view.** Count: every one of the 27 ERB files uses at least one. Port replaces ERB entirely.

**L4. Importmap pins 4 things** — the replacement can use any bundler (esbuild/vite/rollup) trivially; importmap's browser-native ESM approach also works on CF Workers serving static JS.

**L5. Kamal-specific operational tooling (`bin/kamal console/shell/logs/dbc`) has no CF equivalent.** New ops playbook needs `wrangler tail`, D1 dashboard, Workers logs — substitution not translation.

## Recommendations

Directed at **Cycle 2 / Perspective 2 (CF stack research)** and **Cycle-3 synthesis**:

1. **Prioritize service-layer port first.** The ~1,850 LOC of service objects have the highest value-to-risk ratio: well-tested, self-contained, pure-logic. A TypeScript port of `Scoring::*`, `Profiles::ToneFilter`, `Compliance::RestrictedTerms`, `Insights::ContextEngine` + 5 modules can happen before any HTTP layer is designed, and the test suite provides ground truth. Perspective 2 should evaluate: does Hono + D1 + Drizzle (or Kysely or raw) cleanly support these as unit-testable TS modules? Yes in all configurations.

2. **Do not rewrite Hotwire globally — it's only 2 files.** Cycle 2 does not need to invent an SSR-over-Workers story for the whole app. It needs one decision on the assessment question flow: full-page reload vs fetch-swap vs SPA. Framing this as "Hotwire → Next.js" overstates the scope.

3. **No data migration plan is needed.** Cycle 2 can skip "how to export SQLite → D1" discussion beyond `wrangler d1 execute --file schema.sql`. The 16 PersonalityType seed records fit in one SQL file.

4. **Admin area can be deferred or dropped from v1.** It's HTTP Basic + 5 read-mostly screens with no custom auth model. Either port last or keep running the Rails admin pointed at a D1 read-replica, or drop entirely for MVP and rely on direct D1 queries.

5. **Solid Queue / Cache / Cable are not migration blockers.** Cycle 2 should evaluate CF Queues / KV / Durable Objects only against *future* needs (async deletion, async scoring, realtime) — not against current Rails features, because those features aren't used.

6. **`User.encrypts` is the only crypto concern; choose a scheme.** Cycle 2 should pick an AES-GCM scheme with deterministic IV for email (e.g., HKDF-derive IV from email+salt) and document it. No backward-compat constraint since no prod data exists.

7. **Flag: CSRF + cookie-session model must be re-implemented from scratch in Hono.** Rails does this invisibly via ApplicationController inheritance + form helpers. Hono has middleware but the token lifecycle (issue, store, verify, rotate) is the implementer's responsibility. This is medium-effort and worth dedicated design attention in Cycle 2.

8. **Flag for Perspective 3 (payment):** nothing in the Rails code touches payment — `Gemfile` has no payment gem, `routes.rb` has no payment route, no model references it. Payment integration is fully greenfield and does not interact with any existing Rails asset or schema constraint.

9. **Estimated per-area rewrite effort (ordinal, not calendar)**:
   - Models (15, ~250 LOC total excluding comments): **small** — 1 step, mostly mechanical.
   - Services (20, ~1,850 LOC): **medium** — needs careful port of Pearson/Spearman-Brown math and regex rules; tests verify.
   - Controllers (13, ~500 LOC): **small-medium** — standard request/response + one transaction orchestration.
   - Views (27 ERB, 1,788 LOC): **medium** — UI rewrite; Tailwind classes and Korean copy transfer.
   - Stimulus controllers (8, 340 LOC): **small** — trivial port.
   - Turbo Frame flow (2 templates): **small** — one decision + ~30 LOC.
   - AR encryption + CSRF + cookie-session: **medium** — the only three subtle-behavior items.
   - Tests (18 files, 2,641 LOC): **medium** — ports 1:1 for services; request specs rewrite entirely.

## References

| File Path | Role |
|-----------|------|
| `/Users/kampikrein/A/personality/server/Gemfile` | Gem inventory (70 LOC) |
| `/Users/kampikrein/A/personality/server/Gemfile.lock` | Full dep tree (492 LOC) |
| `/Users/kampikrein/A/personality/server/config/application.rb` | Rails boot + AR encryption key ENVs |
| `/Users/kampikrein/A/personality/server/config/database.yml` | 4-DB SQLite config |
| `/Users/kampikrein/A/personality/server/config/deploy.yml` | Kamal deploy config |
| `/Users/kampikrein/A/personality/server/config/routes.rb` | 17 HTML-only routes |
| `/Users/kampikrein/A/personality/server/config/environments/production.rb` | Production Rails settings |
| `/Users/kampikrein/A/personality/server/config/importmap.rb` | 4 pin entries |
| `/Users/kampikrein/A/personality/server/config/cache.yml` | Solid Cache config (unused in code) |
| `/Users/kampikrein/A/personality/server/config/queue.yml` | Solid Queue config (unused in code) |
| `/Users/kampikrein/A/personality/server/config/cable.yml` | Solid Cable config (unused in code) |
| `/Users/kampikrein/A/personality/server/config/recurring.yml` | One cleanup task |
| `/Users/kampikrein/A/personality/server/db/schema.rb` | 14 tables, 220 LOC |
| `/Users/kampikrein/A/personality/server/db/seeds.rb` | 16 PersonalityType records (326 LOC) |
| `/Users/kampikrein/A/personality/server/db/migrate/` | 20 migration files (244 LOC) |
| `/Users/kampikrein/A/personality/server/app/models/` | 15 model files |
| `/Users/kampikrein/A/personality/server/app/controllers/` | 8 app + 5 admin controllers |
| `/Users/kampikrein/A/personality/server/app/controllers/results_controller.rb` | Inline 8-step scoring pipeline (73 LOC) |
| `/Users/kampikrein/A/personality/server/app/services/scoring/` | 5 scoring services (455 LOC) |
| `/Users/kampikrein/A/personality/server/app/services/insights/` | 7 insight services (640 LOC) |
| `/Users/kampikrein/A/personality/server/app/services/profiles/` | 3 profile services (276 LOC) |
| `/Users/kampikrein/A/personality/server/app/services/quality/` | 2 quality services (172 LOC) |
| `/Users/kampikrein/A/personality/server/app/services/compliance/` | 3 compliance services (274 LOC) |
| `/Users/kampikrein/A/personality/server/app/views/` | 27 ERB templates, 1,788 LOC |
| `/Users/kampikrein/A/personality/server/app/javascript/controllers/` | 8 Stimulus controllers, 167 LOC |
| `/Users/kampikrein/A/personality/server/app/jobs/application_job.rb` | Only job file (base class, 8 LOC) |
| `/Users/kampikrein/A/personality/server/spec/` | 18 spec files, 2,641 LOC |
| `/Users/kampikrein/A/personality/server/storage/` | Dev + test SQLite DBs only; **no prod DB** |

## Communication Log

| # | Direction | Peer | Summary | Stage |
|---|-----------|------|---------|-------|
| 1 | → P2 (CF stack) | — | No existing API contract to preserve; JSON shape can be designed fresh. Recommend Hono + Drizzle + D1 evaluation specifically against the service layer (scoring math + regex filters) porting cleanly. | Findings complete |
| 2 | → P2 (CF stack) | — | Solid Queue/Cache/Cable are configured but have zero actual usage — do NOT frame migration around replacing them. | Findings complete |
| 3 | → P2 (CF stack) | — | Turbo Frame is only in 2 templates (assessment question flow); do not design a full Hotwire-on-Workers story. | Findings complete |
| 4 | → P2 (CF stack) | — | `User.encrypts :email, deterministic: true` requires equivalent AES-GCM with deterministic IV derivation for login-by-email. Design choice needed. | Findings complete |
| 5 | → P2 (CF stack) | — | CSRF + cookie-session model is currently implicit via Rails; must be re-implemented explicitly in Hono. Flag as medium-effort design item. | Findings complete |
| 6 | → P3 (payment) | — | Payment is fully greenfield. No existing Rails code, gem, route, or schema interacts with payment. No constraints from current backend. | Findings complete |
| 7 | → Synthesis | — | No production database exists on disk. Migration is data-greenfield. Only PersonalityType seed (16 rows in `db/seeds.rb`) needs recreation. | Findings complete |
