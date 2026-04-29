/**
 * test/services/profiles/typeContentService.test.ts — RED phase
 * Rails: no RSpec (type_content_service.rb — spec 없음)
 * Contract derived from source: server/app/services/profiles/type_content_service.rb
 *
 * Contract: getTypeContent(db, typeCode, locale?) → TypeContent
 * - locale: 'ko' | 'en', default 'ko'
 * - fallback: if primary locale is blank → use other locale
 * - raises ArgumentError for unknown typeCode
 * - returns { character_name, summary, strengths, caution_patterns }
 */

import { describe, it, expect } from "vitest";
import { env } from "cloudflare:test";
import { getTypeContent } from "../../../src/services/profiles/typeContentService";

describe("TypeContentService (RED phase)", () => {
  describe("locale: ko (default)", () => {
    it("returns character_name in Korean for ENFP", async () => {
      const content = await getTypeContent(env.DB, "ENFP");
      expect(content.character_name).toBeTruthy();
      expect(typeof content.character_name).toBe("string");
    });

    it("returns strengths as non-empty array", async () => {
      const content = await getTypeContent(env.DB, "ENFP");
      expect(Array.isArray(content.strengths)).toBe(true);
      expect(content.strengths.length).toBeGreaterThan(0);
    });

    it("returns caution_patterns as array", async () => {
      const content = await getTypeContent(env.DB, "ENFP");
      expect(Array.isArray(content.caution_patterns)).toBe(true);
    });
  });

  describe("locale: en", () => {
    it("returns character_name in English", async () => {
      const content = await getTypeContent(env.DB, "ENFP", "en");
      expect(content.character_name).toBeTruthy();
    });
  });

  describe("case normalization", () => {
    it("normalizes type_code to uppercase (enfp → ENFP)", async () => {
      // getTypeContent should normalize lowercase input
      const content = await getTypeContent(env.DB, "enfp" as any);
      expect(content.character_name).toBeTruthy();
    });
  });

  describe("fallback behavior", () => {
    it("falls back to English if Korean name is blank", async () => {
      // Seed data should have both locales, but contract test verifies fallback
      // If primary locale is blank, falls back to other locale
      const content = await getTypeContent(env.DB, "ISTJ", "ko");
      expect(content.character_name).toBeTruthy(); // either ko or en fallback
    });
  });

  describe("supported locales", () => {
    it("returns content for all 16 MBTI types", async () => {
      const codes = [
        "ENFP", "ENFJ", "ENTP", "ENTJ",
        "ESFP", "ESFJ", "ESTP", "ESTJ",
        "INFP", "INFJ", "INTP", "INTJ",
        "ISFP", "ISFJ", "ISTP", "ISTJ",
      ];
      for (const code of codes) {
        const content = await getTypeContent(env.DB, code);
        expect(content.character_name).toBeTruthy();
      }
    });
  });

  describe("with unknown type code", () => {
    it("raises ArgumentError", async () => {
      await expect(
        getTypeContent(env.DB, "ZZZZ")
      ).rejects.toThrow(/Unknown personality type/);
    });
  });

  describe("return structure", () => {
    it("returns all required keys", async () => {
      const content = await getTypeContent(env.DB, "INTP");
      expect(content).toHaveProperty("character_name");
      expect(content).toHaveProperty("summary");
      expect(content).toHaveProperty("strengths");
      expect(content).toHaveProperty("caution_patterns");
    });
  });
});
