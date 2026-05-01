/**
 * test/setup.ts — vitest global setup hook (GREEN phase)
 *
 * @cloudflare/vitest-pool-workers 환경에서 실행됨.
 * migration SQL을 ?raw import로 읽어 D1 in-memory에 적용한다.
 *
 * Plan 034 Risk mitigation:
 *   - node:fs 접근 불가 → Vite ?raw import 사용 (동작 확인됨)
 *   - PRAGMA foreign_keys: D1 miniflare에서 OFF가 실제로 동작하지 않음
 *     → defer_foreign_keys=TRUE 내부 구현 사용 (FK는 항상 ON)
 *     → 테스트가 사용하는 모든 parent row를 fixture로 생성
 *   - d1_migrations 테이블 → wrangler 호환 방식으로 생성
 *   - D1 exec() 제약: 멀티라인 statement 불가 → prepare().run() 사용
 */

import { env } from "cloudflare:test";
import { beforeAll } from "vitest";
// Vite ?raw import — Workers 런타임에서 파일 내용을 문자열로 인라인
import migrationSQL from "../migrations/0000_thin_spyke.sql?raw";
import migration0001SQL from "../migrations/0001_special_mad_thinker.sql?raw";

// seeds
import { seed } from "../src/db/seed";

beforeAll(async () => {
  // 1. FK OFF로 시작 (fixture 생성 시 FK 제약 우회)
  await env.DB.prepare("PRAGMA foreign_keys = OFF").run();

  // 2. migration SQL 적용 (drizzle-kit generate 산출)
  // D1 prepare().run()으로 각 statement 실행
  // --> statement-breakpoint 구분자로 분할
  const statements = migrationSQL
    .split("--> statement-breakpoint")
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  for (const statement of statements) {
    await env.DB.prepare(statement).run();
  }

  // 2b. migration 0001 SQL 적용 (BetterAuth 컬럼 확장)
  const statements0001 = migration0001SQL
    .split("--> statement-breakpoint")
    .map((s) => s.trim())
    .filter((s) => s.length > 0);

  for (const statement of statements0001) {
    await env.DB.prepare(statement).run();
  }

  // 3. d1_migrations 추적 테이블 생성 (wrangler 호환)
  await env.DB.prepare(
    "CREATE TABLE IF NOT EXISTS d1_migrations (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL)"
  ).run();

  // 4. d1_migrations에 적용 기록 삽입 (멱등 — INSERT OR IGNORE)
  await env.DB.prepare(
    "INSERT OR IGNORE INTO d1_migrations (name) VALUES ('0000_thin_spyke.sql')"
  ).run();
  await env.DB.prepare(
    "INSERT OR IGNORE INTO d1_migrations (name) VALUES ('0001_special_mad_thinker.sql')"
  ).run();

  // 5. seed 실행 (PersonalityType × 16)
  //    personality_types id=1이 생성됨 (ENFP가 첫 번째)
  await seed(env.DB);

  // 6. Fixture rows 생성 (FK OFF 상태에서 실행)
  //    D1 miniflare에서 PRAGMA foreign_keys = OFF가 실제로 동작하지 않음.
  //    따라서 모든 FK 의존성을 올바른 순서로 삽입.
  //
  //    INSERT OR IGNORE 패턴으로 멱등 실행

  // 6a. question_sets: id=1
  await env.DB.prepare(
    "INSERT OR IGNORE INTO question_sets (id, version_code, status, created_at, updated_at) VALUES (1, 'qset_fixture_v1', 'active', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
  ).run();

  // 6b. anonymous_sessions: id=1,2,3,4 (unique session_token 필요)
  for (let i = 1; i <= 4; i++) {
    await env.DB.prepare(
      `INSERT OR IGNORE INTO anonymous_sessions (id, session_token, created_at, updated_at) VALUES (${i}, '_fixture_session_${String(i).padStart(3, "0")}', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).run();
  }

  // 6c. assessments: id=1,2,3,4,100,200,150,250,901
  //    unique_constraints 테스트: assessment_id=100, 200
  //    unique_constraints insights 테스트: profile_id=150, 250 → assessment_id=150, 250
  //    json_columns 테스트: assessment_id=1,2,3,4
  //    profiles fixture(id=999) 전용: assessment_id=901
  const assessmentIds = [1, 2, 3, 4, 100, 150, 200, 250, 901];
  for (const aid of assessmentIds) {
    const sessionId = aid <= 4 ? aid : 1;
    await env.DB.prepare(
      `INSERT OR IGNORE INTO assessments (id, anonymous_session_id, question_set_id, status, created_at, updated_at) VALUES (${aid}, ${sessionId}, 1, 'completed', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).run();
  }

  // 6d. questions: id=1 (responses 테스트용)
  await env.DB.prepare(
    "INSERT OR IGNORE INTO questions (id, question_set_id, domain, position, body_ko, polarity, created_at, updated_at) VALUES (1, 1, 'energy', 1, 'fixture question', 'positive', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
  ).run();

  // 6e. profiles: id=100, 200, 999
  //    unique_constraints 테스트: profile_id=100, 200 → insights FK용
  //    json_columns 테스트: profile_id=999 → insights FK용
  //    personality_type_id: seed()로 생성된 ENFP의 실제 id를 조회
  //    assessment_id: 100→100, 200→200, 999→901 (1~4는 json_columns profiles 테스트 전용)
  // profiles fixture: type_code를 '_FXT_' 접두사로 설정하여
  //   json_columns 테스트의 'WHERE type_code = ENFP/ENFJ/ENTP/ENTJ' 조회와 충돌 방지

  // seed() 후 ENFP의 실제 id 조회
  const enfpRow = await env.DB.prepare(
    "SELECT id FROM personality_types WHERE code = 'ENFP' LIMIT 1"
  ).first<{ id: number }>();
  const personalityTypeId = enfpRow?.id ?? 1;

  const profileFixtures: [number, number, number, string][] = [
    [100, 1, 100, "_FXT_100"],   // id, anonymous_session_id, assessment_id, type_code
    [150, 1, 150, "_FXT_150"],   // insights unique_constraints 테스트용
    [200, 1, 200, "_FXT_200"],
    [250, 1, 250, "_FXT_250"],   // insights unique_constraints 테스트용
    [999, 1, 901, "_FXT_999"],   // assessment_id=901 (json_columns 테스트와 충돌 없음)
  ];
  for (const [pid, anon, aid, tc] of profileFixtures) {
    // INSERT (not OR IGNORE) — FK 오류 발생 시 즉시 알 수 있도록
    try {
      await env.DB.prepare(
        `INSERT INTO profiles (id, anonymous_session_id, assessment_id, personality_type_id, type_code, score_vector, strengths, caution_patterns, suggested_actions, created_at, updated_at) VALUES (${pid}, ${anon}, ${aid}, ${personalityTypeId}, '${tc}', '{}', '[]', '[]', '[]', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      ).run();
    } catch (e) {
      // 이미 존재하는 경우(UNIQUE) 무시, 그 외 에러는 재throw
      const msg = String(e);
      if (!msg.includes("UNIQUE")) throw e;
    }
  }

  // 7b. cycle 8 compliance: consents.status 컬럼 추가 (in-memory only)
  try {
    await env.DB.prepare(
      "ALTER TABLE consents ADD COLUMN status TEXT DEFAULT 'active'"
    ).run();
  } catch {
    // already exists — ignore
  }

  // 7c. cycle 8 compliance: deletion_requests.anonymous_session_id를 nullable + SET NULL로 변경
  //     (anonymous_session 삭제 시 deletion_request가 cascade 삭제되는 문제 해결)
  //     SQLite는 컬럼 타입 변경 불가 → 테이블 재생성 방식 사용
  try {
    await env.DB.prepare("ALTER TABLE deletion_requests RENAME TO deletion_requests_old").run();
    await env.DB.prepare(`
      CREATE TABLE deletion_requests (
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        anonymous_session_id INTEGER,
        request_token TEXT NOT NULL,
        status TEXT DEFAULT 'pending' NOT NULL,
        sla_deadline TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP NOT NULL,
        FOREIGN KEY (anonymous_session_id) REFERENCES anonymous_sessions(id) ON DELETE SET NULL,
        UNIQUE (request_token)
      )
    `).run();
    await env.DB.prepare(
      "INSERT INTO deletion_requests SELECT * FROM deletion_requests_old"
    ).run();
    await env.DB.prepare("DROP TABLE deletion_requests_old").run();
  } catch {
    // ignore if already migrated
  }

  // 7. FK ON으로 설정 (foreign_keys.test.ts가 PRAGMA ON을 각 테스트에서 설정하지만
  //    setup 마지막에 ON으로 두어 FK 무결성 테스트 환경 보장)
  await env.DB.prepare("PRAGMA foreign_keys = ON").run();
});
