/**
 * test/services/profiles/composer.test.ts — RED phase
 * RSpec: server/spec/services/profiles/composer_spec.rb (8 tests)
 *
 * Contract: composeProfile(db, assessmentId, typeCode) → ComposedProfile
 * - UPSERT: INSERT ... ON CONFLICT(assessment_id) DO UPDATE (step 7 R2-F2)
 * - builds score_vector from domain_scores
 * - applies ToneFilter to text content
 * - generates suggested_actions from personality type fields
 * - raises error for unknown type_code
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";
import { composeProfile } from "../../../src/services/profiles/composer";

async function setupComposerFixture(db: D1Database): Promise<{
  assessmentId: number;
  sessionId: number;
}> {
  const assessmentId = 7000 + Math.floor(Math.random() * 1000);
  const sessionId = 7000 + Math.floor(Math.random() * 1000);

  await db.prepare(
    `INSERT OR IGNORE INTO anonymous_sessions (id, session_token, created_at, updated_at)
     VALUES (?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
  ).bind(sessionId, `composer_session_${sessionId}`).run();

  await db.prepare(
    `INSERT OR IGNORE INTO assessments
       (id, anonymous_session_id, question_set_id, status, created_at, updated_at)
     VALUES (?, ?, 1, 'scored', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
  ).bind(assessmentId, sessionId).run();

  // Create domain scores (all 60.0)
  for (const domain of ["energy", "decision_making", "relationship", "recovery"]) {
    await db.prepare(
      `INSERT OR IGNORE INTO domain_scores
         (assessment_id, domain, raw_score, normalized_score, consistency_index,
          reliability_coefficient, speed_flag, policy_blocked, created_at, updated_at)
       VALUES (?, ?, 15, 60.0, 0.7, 0.8, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
    ).bind(assessmentId, domain).run();
  }

  return { assessmentId, sessionId };
}

describe("Profiles::Composer (RED phase)", () => {
  it("creates a Profile record (UPSERT)", async () => {
    const { assessmentId } = await setupComposerFixture(env.DB);

    const countBefore = await env.DB.prepare(
      "SELECT COUNT(*) as cnt FROM profiles WHERE assessment_id = ?"
    ).bind(assessmentId).first<{ cnt: number }>();
    expect(countBefore?.cnt).toBe(0);

    await composeProfile(env.DB, assessmentId, "INTP");

    const countAfter = await env.DB.prepare(
      "SELECT COUNT(*) as cnt FROM profiles WHERE assessment_id = ?"
    ).bind(assessmentId).first<{ cnt: number }>();
    expect(countAfter?.cnt).toBe(1);
  });

  it("sets correct type_code", async () => {
    const { assessmentId } = await setupComposerFixture(env.DB);
    const profile = await composeProfile(env.DB, assessmentId, "INTP");
    expect(profile.typeCode).toBe("INTP");
  });

  it("builds score_vector from domain scores", async () => {
    const { assessmentId } = await setupComposerFixture(env.DB);
    const profile = await composeProfile(env.DB, assessmentId, "INTP");
    expect(profile.scoreVector).toMatchObject({
      energy: 60.0,
      decision_making: 60.0,
      relationship: 60.0,
      recovery: 60.0,
    });
  });

  it("includes personality type strengths (non-empty)", async () => {
    const { assessmentId } = await setupComposerFixture(env.DB);
    const profile = await composeProfile(env.DB, assessmentId, "INTP");
    expect(profile.strengths.length).toBeGreaterThan(0);
  });

  it("generates suggested actions (contains teamwork or collaboration hint)", async () => {
    const { assessmentId } = await setupComposerFixture(env.DB);
    const profile = await composeProfile(env.DB, assessmentId, "INTP");
    const actions = profile.suggestedActions.map((a) => a.action).join(" ");
    expect(actions.toLowerCase()).toMatch(/teamwork|collaborat|team/);
  });

  it("applies ToneFilter — strengths are strings (filter does not crash)", async () => {
    const { assessmentId } = await setupComposerFixture(env.DB);
    const profile = await composeProfile(env.DB, assessmentId, "INTP");
    profile.strengths.forEach((s) => {
      expect(typeof s).toBe("string");
    });
  });

  describe("UPSERT idempotency (R2-F2: step 7 must be idempotent)", () => {
    it("re-running does NOT create a second profile row", async () => {
      const { assessmentId } = await setupComposerFixture(env.DB);
      await composeProfile(env.DB, assessmentId, "INTP");
      await composeProfile(env.DB, assessmentId, "INTP"); // second run

      const count = await env.DB.prepare(
        "SELECT COUNT(*) as cnt FROM profiles WHERE assessment_id = ?"
      ).bind(assessmentId).first<{ cnt: number }>();
      expect(count?.cnt).toBe(1);
    });
  });

  describe("with unknown type code", () => {
    it("raises ArgumentError for unknown type", async () => {
      const { assessmentId } = await setupComposerFixture(env.DB);
      await expect(
        composeProfile(env.DB, assessmentId, "ZZZZ")
      ).rejects.toThrow(/Unknown personality type/);
    });
  });

  describe("with extreme scores (>= 75)", () => {
    it("adds strong domain action", async () => {
      const { assessmentId, sessionId } = await setupComposerFixture(env.DB);

      // Update energy score to 80
      await env.DB.prepare(
        "UPDATE domain_scores SET normalized_score = 80.0 WHERE assessment_id = ? AND domain = 'energy'"
      ).bind(assessmentId).run();

      const profile = await composeProfile(env.DB, assessmentId, "INTP");
      const actions = profile.suggestedActions.map((a) => a.action).join(" ");
      expect(actions.toLowerCase()).toMatch(/energy|strength/);
    });
  });

  describe("with low scores (<= 25)", () => {
    it("adds growth domain action", async () => {
      const { assessmentId } = await setupComposerFixture(env.DB);

      // Update recovery score to 20
      await env.DB.prepare(
        "UPDATE domain_scores SET normalized_score = 20.0 WHERE assessment_id = ? AND domain = 'recovery'"
      ).bind(assessmentId).run();

      const profile = await composeProfile(env.DB, assessmentId, "INTP");
      const actions = profile.suggestedActions.map((a) => a.action).join(" ");
      expect(actions.toLowerCase()).toMatch(/recovery|benefit|grow/);
    });
  });
});
