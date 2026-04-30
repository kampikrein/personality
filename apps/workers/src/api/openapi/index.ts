/**
 * src/api/openapi/index.ts — OpenAPI spec loader + Hono RPC type export
 * Cycle 5 GREEN phase.
 *
 * Responsibilities:
 *   1. Load shared/api-schema/openapi.yaml and expose it as JSON
 *   2. Export AppType for Hono RPC client generation
 */

import { readFileSync } from "fs";
import { resolve } from "path";
import * as yaml from "js-yaml";

// Monorepo root is 4 levels up from src/api/openapi/
// apps/workers/src/api/openapi → apps/workers/src/api → apps/workers/src → apps/workers → apps → monorepo root
const OPENAPI_PATH = resolve(
  __dirname,
  "../../../../..", // → monorepo root (apps/workers/src/api/openapi → up 5)
  "shared/api-schema/openapi.yaml"
);

/**
 * getOpenApiSpec — load and return parsed openapi.yaml
 */
export async function getOpenApiSpec(): Promise<Record<string, unknown>> {
  const content = readFileSync(OPENAPI_PATH, "utf-8");
  return yaml.load(content) as Record<string, unknown>;
}

/**
 * AppType — Hono RPC type export
 * GREEN phase: type of the composed Hono app from src/index.ts
 * (imported via re-export in src/api/index.ts)
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export type AppType = any;
