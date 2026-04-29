// D1 → R2 export scheduled handler
// Cron: 0 17 * * 0 (UTC) = 한국 일요일 02:00 KST
// Brief In Scope 1 (M14 보강), Constraint "D1 export → R2 주 1회"
//
// NOTE(Phase 2): Phase 1에서는 wrangler dev --local 환경에서 동작 확인.
//   production cron 실 트리거는 Phase 2 cutover 후 CF dashboard에서 활성화.
//   stub-only 응답(501)은 제거하고 아래 실제 구현으로 교체됨 (Scope 026 Mn4).

type Bindings = {
  DB: D1Database;
  R2_BACKUP: R2Bucket;
  ENV: string;
};

export const scheduled: ExportedHandlerScheduledHandler<Bindings> =
  async (event, env, ctx) => {
    ctx.waitUntil(performBackup(env, event.scheduledTime));
  };

async function performBackup(env: Bindings, scheduledTime: number): Promise<void> {
  const ts = new Date(scheduledTime).toISOString().replace(/[:.]/g, "-");
  const key = `${env.ENV}/d1-backup-${ts}.sql`;

  // 1) 모든 테이블 목록 조회 (Cycle 1 시점엔 schema 미존재 — 빈 결과도 정상)
  const tablesRes = await env.DB.prepare(
    `SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE '_cf_%'`
  ).all<{ name: string }>();
  const tables = tablesRes.results ?? [];

  // 2) 각 테이블의 schema + data를 SQL 형태로 dump
  const lines: string[] = [];
  lines.push(`-- D1 Backup ${ts} | env=${env.ENV} | tables=${tables.length}`);

  for (const { name } of tables) {
    const schemaRes = await env.DB.prepare(
      `SELECT sql FROM sqlite_master WHERE type='table' AND name = ?`
    ).bind(name).first<{ sql: string }>();
    if (schemaRes?.sql) lines.push(`${schemaRes.sql};`);

    const rowsRes = await env.DB.prepare(`SELECT * FROM ${name}`).all();
    for (const row of rowsRes.results ?? []) {
      const cols = Object.keys(row).join(", ");
      const vals = Object.values(row)
        .map((v) =>
          v === null
            ? "NULL"
            : typeof v === "number"
            ? String(v)
            : `'${String(v).replace(/'/g, "''")}'`
        )
        .join(", ");
      lines.push(`INSERT INTO ${name} (${cols}) VALUES (${vals});`);
    }
  }

  // 3) R2 put
  const body = lines.join("\n");
  await env.R2_BACKUP.put(key, body, {
    httpMetadata: { contentType: "application/sql" },
    customMetadata: { env: env.ENV, scheduledTime: String(scheduledTime) },
  });
}
