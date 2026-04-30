import { defineWorkersConfig } from "@cloudflare/vitest-pool-workers/config";

export default defineWorkersConfig({
  test: {
    poolOptions: {
      workers: {
        // wrangler.toml 에서 D1/KV/R2 binding 자동 로드
        wrangler: { configPath: "./wrangler.toml" },
        miniflare: {
          // in-memory D1 — 외부 자원 미접촉, 로컬 완결
          d1Databases: ["DB"],
          kvNamespaces: ["KV"],
          r2Buckets: ["R2_BACKUP", "R2_SECRETS", "R2_UPLOADS"],
        },
      },
    },
    // test/setup.ts: D1 binding 준비 hook
    setupFiles: ["./test/setup.ts"],
    // 타임아웃 넉넉히 (D1 in-memory 초기화 포함)
    testTimeout: 15000,
  },
  // Cycle 4: better-auth depends on Node.js internals (crypto, etc.)
  // Mark as external so vitest-pool-workers does NOT bundle it into the Workers runtime.
  // Stubs in src/auth/betterAuth.ts do NOT import better-auth at RED phase.
  // GREEN phase: use cloudflare:node-compat or separate the betterAuth adapter layer.
  resolve: {
    external: ["better-auth"],
  },
});
