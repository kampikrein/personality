/**
 * test/api/openapi/spec.test.ts — OpenAPI spec validation RED phase
 * Cycle 5.
 *
 * Assertions:
 *   1. shared/api-schema/openapi.yaml exists and is readable
 *   2. YAML is valid (parseable)
 *   3. openapi version is 3.0.x
 *   4. info.title and info.version are present
 *   5. paths object exists
 *   6. paths count === 32 (public 22 + admin 10)
 *   7. All public endpoints are present in paths
 *   8. All admin endpoints are present in paths
 *   9. Each path has at least one operationId
 *  10. components.schemas.SuccessResponse is defined
 *  11. components.schemas.ErrorResponse is defined
 *  12. error code enum includes all 7 codes
 *
 * RED phase:
 *   - openapi.yaml stub has paths: {} (empty) — assertions 6-9 FAIL.
 *   - Assertions 1-5, 10-12 may pass once spec is created.
 *
 * GREEN phase: fill in all 32 endpoints with full schemas.
 */

import { describe, it, expect } from "vitest";
import { readFileSync } from "fs";
import { resolve } from "path";
import * as yaml from "js-yaml";

// Path relative to workers package root → up 3 levels to monorepo root → shared/api-schema
const OPENAPI_PATH = resolve(
  __dirname,
  "../../../../..",  // -> monorepo root
  "shared/api-schema/openapi.yaml"
);

// Expected public endpoints: method:path
const EXPECTED_PUBLIC_ENDPOINTS = [
  // sessions
  "post:/api/sessions",
  "delete:/api/sessions",
  "get:/api/sessions/me",
  // accounts
  "post:/api/accounts",
  "get:/api/accounts/me",
  "patch:/api/accounts/me",
  // assessments
  "post:/api/assessments",
  "get:/api/assessments/{id}",
  "post:/api/assessments/{id}/complete",
  "patch:/api/assessments/{id}/submit",
  // assessment_questions
  "get:/api/assessment_questions",
  "get:/api/assessment_questions/{id}",
  "patch:/api/assessment_questions/{id}",
  // results
  "get:/api/results/{assessment_id}",
  "get:/api/results/{assessment_id}/share",
  // consents
  "post:/api/consents",
  "get:/api/consents/{id}",
  "delete:/api/consents/{id}",
  "patch:/api/consents/{id}",
  // deletion_requests
  "post:/api/deletion_requests",
  "get:/api/deletion_requests/{id}",
  // health
  "get:/api/health",
];

// Expected admin endpoints: method:path
const EXPECTED_ADMIN_ENDPOINTS = [
  "get:/admin/audit_logs",
  "get:/admin/audit_logs/{id}",
  "get:/admin/question_sets",
  "post:/admin/question_sets",
  "get:/admin/question_sets/{id}",
  "patch:/admin/question_sets/{id}",
  "delete:/admin/question_sets/{id}",
  "get:/admin/alerts",
  "get:/admin/alerts/{id}",
  "patch:/admin/alerts/{id}",
  "get:/admin/dashboard",
  "get:/admin/dashboard/completion_rates",
  "get:/admin/dashboard/drop_off_analysis",
];

type OpenApiSpec = {
  openapi?: string;
  info?: { title?: string; version?: string };
  paths?: Record<string, Record<string, { operationId?: string }>>;
  components?: {
    schemas?: Record<string, unknown>;
    securitySchemes?: Record<string, unknown>;
  };
};

describe("OpenAPI Spec Validation — RED phase", () => {
  let spec: OpenApiSpec;

  it("shared/api-schema/openapi.yaml exists and is readable", () => {
    expect(() => {
      readFileSync(OPENAPI_PATH, "utf-8");
    }).not.toThrow();
  });

  it("YAML is valid (parseable)", () => {
    const content = readFileSync(OPENAPI_PATH, "utf-8");
    expect(() => {
      spec = yaml.load(content) as OpenApiSpec;
    }).not.toThrow();
    expect(spec).toBeDefined();
    expect(typeof spec).toBe("object");
  });

  it("openapi version is 3.0.x", () => {
    const content = readFileSync(OPENAPI_PATH, "utf-8");
    spec = yaml.load(content) as OpenApiSpec;
    expect(spec.openapi).toBeDefined();
    expect(spec.openapi).toMatch(/^3\.0\./);
  });

  it("info.title is present", () => {
    const content = readFileSync(OPENAPI_PATH, "utf-8");
    spec = yaml.load(content) as OpenApiSpec;
    expect(spec.info?.title).toBeDefined();
    expect(spec.info!.title!.length).toBeGreaterThan(0);
  });

  it("info.version is present", () => {
    const content = readFileSync(OPENAPI_PATH, "utf-8");
    spec = yaml.load(content) as OpenApiSpec;
    expect(spec.info?.version).toBeDefined();
  });

  it("paths object exists", () => {
    const content = readFileSync(OPENAPI_PATH, "utf-8");
    spec = yaml.load(content) as OpenApiSpec;
    expect(spec.paths).toBeDefined();
    expect(typeof spec.paths).toBe("object");
  });

  it("paths has 32 unique operation paths (public 22 + admin 10 — GREEN phase target)", () => {
    const content = readFileSync(OPENAPI_PATH, "utf-8");
    spec = yaml.load(content) as OpenApiSpec;
    // Count total operations (method × path combinations)
    let totalOps = 0;
    for (const pathItem of Object.values(spec.paths ?? {})) {
      const methods = ["get", "post", "put", "patch", "delete"];
      for (const method of methods) {
        if (method in pathItem) totalOps++;
      }
    }
    // RED phase: paths is empty → this FAILS (0 !== 32)
    expect(totalOps).toBeGreaterThanOrEqual(32);
  });

  describe("public endpoints in paths", () => {
    it("all 22+ public endpoints are registered", () => {
      const content = readFileSync(OPENAPI_PATH, "utf-8");
      spec = yaml.load(content) as OpenApiSpec;
      const paths = spec.paths ?? {};

      for (const endpoint of EXPECTED_PUBLIC_ENDPOINTS) {
        const [method, path] = endpoint.split(":", 2);
        const pathItem = paths[path] as Record<string, unknown> | undefined;
        // RED phase: paths is empty → fails
        expect(pathItem, `Missing path ${path}`).toBeDefined();
        expect(
          pathItem![method],
          `Missing method ${method.toUpperCase()} ${path}`
        ).toBeDefined();
      }
    });
  });

  describe("admin endpoints in paths", () => {
    it("all 10+ admin endpoints are registered", () => {
      const content = readFileSync(OPENAPI_PATH, "utf-8");
      spec = yaml.load(content) as OpenApiSpec;
      const paths = spec.paths ?? {};

      for (const endpoint of EXPECTED_ADMIN_ENDPOINTS) {
        const [method, path] = endpoint.split(":", 2);
        const pathItem = paths[path] as Record<string, unknown> | undefined;
        expect(pathItem, `Missing path ${path}`).toBeDefined();
        expect(
          pathItem![method],
          `Missing method ${method.toUpperCase()} ${path}`
        ).toBeDefined();
      }
    });
  });

  it("each registered path operation has operationId", () => {
    const content = readFileSync(OPENAPI_PATH, "utf-8");
    spec = yaml.load(content) as OpenApiSpec;
    const paths = spec.paths ?? {};
    const methods = ["get", "post", "put", "patch", "delete"];

    for (const [path, pathItem] of Object.entries(paths)) {
      for (const method of methods) {
        const op = (pathItem as Record<string, { operationId?: string }>)[method];
        if (op) {
          expect(op.operationId, `Missing operationId for ${method.toUpperCase()} ${path}`).toBeDefined();
        }
      }
    }
  });

  it("components.schemas.SuccessResponse is defined", () => {
    const content = readFileSync(OPENAPI_PATH, "utf-8");
    spec = yaml.load(content) as OpenApiSpec;
    expect(spec.components?.schemas?.SuccessResponse).toBeDefined();
  });

  it("components.schemas.ErrorResponse is defined", () => {
    const content = readFileSync(OPENAPI_PATH, "utf-8");
    spec = yaml.load(content) as OpenApiSpec;
    expect(spec.components?.schemas?.ErrorResponse).toBeDefined();
  });

  it("ErrorResponse.error.code enum includes all 7 error codes", () => {
    const content = readFileSync(OPENAPI_PATH, "utf-8");
    spec = yaml.load(content) as OpenApiSpec;
    const errorResponse = spec.components?.schemas?.ErrorResponse as Record<string, unknown> | undefined;
    const errorProp = (errorResponse?.properties as Record<string, unknown>)?.error as Record<string, unknown> | undefined;
    const codeProp = (errorProp?.properties as Record<string, unknown>)?.code as Record<string, unknown> | undefined;
    const codeEnum = codeProp?.enum as string[] | undefined;

    expect(codeEnum).toBeDefined();
    const required = [
      "validation_failed", "unauthorized", "forbidden",
      "not_found", "conflict", "rate_limited", "internal_error",
    ];
    for (const code of required) {
      expect(codeEnum).toContain(code);
    }
  });
});
