import { defineWorkersProject } from "@cloudflare/vitest-pool-workers/config";
import { defineProject } from "vitest/config";

export default [
  // ── Workers pool (Cloudflare runtime) ─────────────────────────────────────
  defineWorkersProject({
    test: {
      name: "workers",
      include: ["test/**/*.test.ts"],
      // openapi/spec.test.ts + codegen/dart_client.test.ts use Node.js fs
      // → excluded from Workers pool, run in Node pool below
      exclude: [
        "test/api/openapi/**",
        "test/api/codegen/**",
      ],
      poolOptions: {
        workers: {
          // wrangler.toml 에서 D1/KV/R2 binding 자동 로드
          wrangler: { configPath: "./wrangler.toml" },
          // singleWorker=true: 모든 테스트를 단일 Worker 인스턴스에서 실행
          singleWorker: true,
          miniflare: {
            d1Databases: ["DB"],
            kvNamespaces: ["KV"],
            r2Buckets: ["R2_BACKUP", "R2_SECRETS", "R2_UPLOADS"],
          },
        },
      },
      setupFiles: ["./test/setup.ts"],
      testTimeout: 15000,
    },
    // Cycle 4: better-auth depends on Node.js internals
    resolve: {
      external: ["better-auth"],
    },
  }),
  // ── Node pool (openapi/spec + codegen/dart_client — use Node.js fs) ───────
  defineProject({
    test: {
      name: "node",
      include: [
        "test/api/openapi/**/*.test.ts",
        "test/api/codegen/**/*.test.ts",
      ],
      environment: "node",
      testTimeout: 15000,
    },
  }),
];
