/**
 * src/api/openapi/index.ts — OpenAPI spec loader + Hono RPC type export
 * Cycle 5 stub — RED phase.
 *
 * Responsibilities:
 *   1. Load shared/api-schema/openapi.yaml and expose it as JSON
 *   2. Export AppType for Hono RPC client generation
 *
 * GREEN phase:
 *   - Load and validate openapi.yaml (zod-openapi or @hono/zod-openapi)
 *   - Export AppType from fully-typed app instance
 *   - Wire into src/api/index.ts
 */

/**
 * getOpenApiSpec — load and return parsed openapi.yaml
 * RED: throws 'not implemented'
 */
export async function getOpenApiSpec(): Promise<Record<string, unknown>> {
  throw new Error("not implemented");
}

/**
 * AppType — Hono RPC type export placeholder
 * GREEN phase: export typeof app from src/api/index.ts for hono/client
 */
export type AppType = Record<string, never>;
