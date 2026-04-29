/**
 * test/setup.ts — vitest global setup hook
 *
 * @cloudflare/vitest-pool-workers 환경에서 실행됨.
 * D1 binding(DB)이 miniflare in-memory SQLite로 주입되므로,
 * 여기서 schema migration SQL을 적용한다.
 *
 * GREEN phase 이후: migrations/ 디렉토리의 SQL 파일을 읽어
 * DB.exec()으로 순서대로 적용한다.
 *
 * RED phase: migration 파일이 없으므로 이 hook은 no-op.
 * 테스트는 "table does not exist" 에러로 fail — 의도된 동작.
 */

// @cloudflare/vitest-pool-workers 는 globalThis.env 를 통해
// wrangler.toml binding을 inject한다.
// setup 파일에서 직접 DB 초기화가 필요하면 아래 패턴 사용:
//
// import { env } from "cloudflare:test";
// beforeAll(async () => {
//   const migrations = await loadMigrations(); // GREEN phase에서 구현
//   for (const sql of migrations) {
//     await env.DB.exec(sql);
//   }
// });
//
// RED phase에서는 schema.ts / migrations/ 가 없으므로 no-op 유지.
// GREEN phase 진입 시 이 파일을 활성화한다.

export {};
