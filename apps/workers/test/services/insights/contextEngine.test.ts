/**
 * test/services/insights/contextEngine.test.ts — RED phase
 * RSpec: server/spec/services/insights/context_engine_spec.rb (15 tests — 3 × 5 contexts + 3 extra)
 *
 * Contract: generateInsight(db, profileId, context) → InsightResult
 * CONTEXTS: collaboration | conflict | learning | career | recovery
 * - creates an Insight record (UPSERT on profile_id + context)
 * - sets correct context
 * - has non-empty explanation
 * - has suggestions array
 * - idempotent: second call updates existing record, does not create new
 * - raises ArgumentError for invalid context
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";
import {
  generateInsight,
  INSIGHT_CONTEXTS,
} from "../../../src/services/insights/contextEngine";

// Use pre-created fixture profiles from setup.ts (id=100, 150, 200, 250, 999)
const FIXTURE_PROFILE_ID = 100;

describe("Insights::ContextEngine (RED phase)", () => {
  // RSpec: Insight::CONTEXTS.each do |ctx| (5 × 3 tests = 15 tests)
  for (const ctx of INSIGHT_CONTEXTS) {
    describe(`with context '${ctx}'`, () => {
      it("creates an Insight record", async () => {
        const countBefore = await env.DB.prepare(
          "SELECT COUNT(*) as cnt FROM insights WHERE profile_id = ? AND context = ?"
        ).bind(FIXTURE_PROFILE_ID, ctx).first<{ cnt: number }>();

        await generateInsight(env.DB, FIXTURE_PROFILE_ID, ctx);

        const countAfter = await env.DB.prepare(
          "SELECT COUNT(*) as cnt FROM insights WHERE profile_id = ? AND context = ?"
        ).bind(FIXTURE_PROFILE_ID, ctx).first<{ cnt: number }>();
        expect((countAfter?.cnt ?? 0)).toBeGreaterThanOrEqual(1);
      });

      it("sets the correct context", async () => {
        const result = await generateInsight(env.DB, FIXTURE_PROFILE_ID, ctx);
        expect(result.context).toBe(ctx);
      });

      it("has an explanation", async () => {
        const result = await generateInsight(env.DB, FIXTURE_PROFILE_ID, ctx);
        expect(result.explanation).toBeTruthy();
        expect(result.explanation.length).toBeGreaterThan(0);
      });

      it("has suggestions array", async () => {
        const result = await generateInsight(env.DB, FIXTURE_PROFILE_ID, ctx);
        expect(Array.isArray(result.suggestions)).toBe(true);
      });
    });
  }

  describe("with invalid context", () => {
    it("raises ArgumentError", async () => {
      await expect(
        generateInsight(env.DB, FIXTURE_PROFILE_ID, "invalid_context")
      ).rejects.toThrow(/Unknown insight context/);
    });
  });

  describe("when called twice for the same context", () => {
    it("updates the existing insight (idempotent — no duplicate)", async () => {
      const profileId = 150; // separate fixture profile

      await generateInsight(env.DB, profileId, "collaboration");

      const countBefore = await env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM insights WHERE profile_id = ? AND context = 'collaboration'"
      ).bind(profileId).first<{ cnt: number }>();

      await generateInsight(env.DB, profileId, "collaboration");

      const countAfter = await env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM insights WHERE profile_id = ? AND context = 'collaboration'"
      ).bind(profileId).first<{ cnt: number }>();

      // Must not increase count (UPSERT)
      expect(countAfter?.cnt).toBe(countBefore?.cnt);
    });
  });

  describe("explanation enrichment", () => {
    it("produces a non-empty explanation for collaboration", async () => {
      const result = await generateInsight(env.DB, 200, "collaboration");
      expect(result.explanation.length).toBeGreaterThan(0);
    });
  });
});
