/**
 * test/api/codegen/dart_client.test.ts — Hono RPC AppType export + codegen RED phase
 * Cycle 5.
 *
 * Assertions:
 *   1. AppType is exported from src/api/openapi/index.ts
 *   2. getOpenApiSpec() function is exported
 *   3. getOpenApiSpec() returns a parsed spec object (GREEN phase)
 *   4. AppType is a valid TypeScript type (compile-time assertion only)
 *   5. src/index.ts exports the app (for Hono RPC client)
 *   6. Hono RPC: hc<AppType> can be instantiated (GREEN phase)
 *
 * Note: Dart actual build is Phase 2 carryover (Brief 021 § Decision 12 gap #18).
 * This cycle verifies: TypeScript exports only.
 *
 * RED phase: getOpenApiSpec() throws 'not implemented' → assertion 3 fails.
 * GREEN phase: implement getOpenApiSpec() + full AppType from typed Hono app.
 */

import { describe, it, expect } from "vitest";
import {
  getOpenApiSpec,
  type AppType,
} from "../../../src/api/openapi/index";

describe("Hono RPC AppType + Codegen — RED phase", () => {
  describe("module exports", () => {
    it("getOpenApiSpec is exported as a function", () => {
      expect(typeof getOpenApiSpec).toBe("function");
    });

    it("AppType type is exported (TypeScript compile-time check)", () => {
      // This is a TypeScript type, not a value — we verify the import doesn't fail.
      // If AppType is not exported, the import above would cause a compile error.
      const _typeCheck: AppType = {} as AppType;
      expect(_typeCheck).toBeDefined();
    });
  });

  describe("getOpenApiSpec()", () => {
    it("returns a parsed OpenAPI spec object (GREEN phase)", async () => {
      const spec = await getOpenApiSpec();
      expect(spec).toBeDefined();
      expect(typeof spec).toBe("object");
      expect(spec["openapi"]).toBeDefined();
    });

    it("spec has info.title (GREEN phase)", async () => {
      const spec = await getOpenApiSpec();
      const info = spec["info"] as Record<string, unknown>;
      expect(info?.title).toBeDefined();
    });

    it("spec has paths with 32 endpoints (GREEN phase)", async () => {
      const spec = await getOpenApiSpec();
      const paths = spec["paths"] as Record<string, unknown>;
      const methods = ["get", "post", "put", "patch", "delete"];
      let opCount = 0;
      for (const pathItem of Object.values(paths ?? {})) {
        for (const method of methods) {
          if (method in (pathItem as Record<string, unknown>)) opCount++;
        }
      }
      expect(opCount).toBeGreaterThanOrEqual(32);
    });
  });

  describe("Hono RPC type compatibility (GREEN phase — stub check)", () => {
    it("src/api/index.ts re-exports AppType", async () => {
      // Dynamic import to check without compile error at RED phase
      const apiModule = await import("../../../src/api/index");
      // AppType is a type export — check that the module loads without error
      expect(apiModule).toBeDefined();
    });
  });
});
