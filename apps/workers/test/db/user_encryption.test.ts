/**
 * test/db/user_encryption.test.ts — R4 user 분리 컬럼 + envelope JSON 검증 (RED phase)
 *
 * Brief 021 Decision 3 + R4 + Synthesis S-018-F1:
 *   - users.email_hash: TEXT, NOT NULL, UNIQUE — SHA-256 hex(64자)
 *   - users.email_enc: TEXT, NOT NULL — R1 envelope JSON 저장
 *   - users.encryption_version: INTEGER, NOT NULL DEFAULT 1
 *
 * Envelope JSON 형태 (Synthesis 018 결정 — R1 wire-format 보존):
 *   { "iv": "<base64>", "ct": "<base64>", "v": 1 }
 *   (Rails ActiveRecord::Encryption::Message wire-format 호환)
 *
 * RED phase: 테이블 없음 → insert fail → 의도된 fail
 * GREEN phase: users 테이블 생성 후 통과
 */

import { describe, it, expect, beforeEach } from "vitest";
import { env } from "cloudflare:test";

/**
 * SHA-256 hex 형식 검증 — 64자 16진수
 */
function isSha256Hex(value: string): boolean {
  return /^[0-9a-f]{64}$/.test(value);
}

/**
 * envelope JSON 형태 검증
 * { iv: string, ct: string, v: number }
 */
function isValidEnvelope(value: string): boolean {
  try {
    const parsed = JSON.parse(value);
    return (
      typeof parsed === "object" &&
      parsed !== null &&
      typeof parsed.iv === "string" &&
      typeof parsed.ct === "string" &&
      typeof parsed.v === "number"
    );
  } catch {
    return false;
  }
}

const SAMPLE_EMAIL_HASH = "a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4";
const SAMPLE_ENVELOPE = JSON.stringify({
  iv: "base64EncodedIV==",
  ct: "base64EncodedCiphertext==",
  v: 1,
});

describe("User Encryption — R4 분리 컬럼 (RED phase)", () => {
  beforeEach(async () => {
    await env.DB.prepare("PRAGMA foreign_keys = OFF").run();
    try {
      await env.DB.prepare(
        `DELETE FROM users WHERE email_hash = ?`
      )
        .bind(SAMPLE_EMAIL_HASH)
        .run();
    } catch {
      // RED phase: 테이블 없음 → 무시
    }
  });

  describe("users 테이블 컬럼 구조", () => {
    it("users table should have email_hash column (TEXT, NOT NULL)", async () => {
      const result = await env.DB.prepare(`PRAGMA table_info(users)`).all();
      const cols = result.results as {
        name: string;
        type: string;
        notnull: number;
      }[];

      const emailHash = cols.find((c) => c.name === "email_hash");
      expect(emailHash).toBeDefined();
      expect(emailHash!.type.toUpperCase()).toContain("TEXT");
      expect(emailHash!.notnull).toBe(1); // NOT NULL
    });

    it("users table should have email_enc column (TEXT, NOT NULL)", async () => {
      const result = await env.DB.prepare(`PRAGMA table_info(users)`).all();
      const cols = result.results as {
        name: string;
        type: string;
        notnull: number;
      }[];

      const emailEnc = cols.find((c) => c.name === "email_enc");
      expect(emailEnc).toBeDefined();
      expect(emailEnc!.type.toUpperCase()).toContain("TEXT");
      expect(emailEnc!.notnull).toBe(1); // NOT NULL
    });

    it("users table should have encryption_version column (INTEGER, NOT NULL, DEFAULT 1)", async () => {
      const result = await env.DB.prepare(`PRAGMA table_info(users)`).all();
      const cols = result.results as {
        name: string;
        type: string;
        notnull: number;
        dflt_value: string | null;
      }[];

      const encVer = cols.find((c) => c.name === "encryption_version");
      expect(encVer).toBeDefined();
      expect(encVer!.type.toUpperCase()).toContain("INTEGER");
      expect(encVer!.notnull).toBe(1); // NOT NULL
      // DEFAULT 1
      expect(encVer!.dflt_value).toBe("1");
    });

    it("users table should have email_hash as UNIQUE", async () => {
      const result = await env.DB.prepare(`PRAGMA index_list(users)`).all();
      const indexes = result.results as {
        seq: number;
        name: string;
        unique: number;
        origin: string;
        partial: number;
      }[];

      // email_hash UNIQUE index 존재 확인
      // Rails: t.index ["email"], name: "index_users_on_email", unique: true
      // R4: email → email_hash 로 변경
      const hasUniqueEmailHash = indexes.some(
        (idx) =>
          idx.unique === 1 &&
          (idx.name.includes("email_hash") || idx.name.includes("email"))
      );
      expect(hasUniqueEmailHash).toBe(true);
    });
  });

  describe("email_enc — envelope JSON round-trip", () => {
    it("should insert and select envelope JSON correctly", async () => {
      await env.DB.prepare(
        `INSERT INTO users (email_hash, email_enc, encryption_version, created_at, updated_at)
         VALUES (?, ?, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(SAMPLE_EMAIL_HASH, SAMPLE_ENVELOPE)
        .run();

      const result = await env.DB.prepare(
        `SELECT email_hash, email_enc, encryption_version FROM users WHERE email_hash = ?`
      )
        .bind(SAMPLE_EMAIL_HASH)
        .first<{
          email_hash: string;
          email_enc: string;
          encryption_version: number;
        }>();

      expect(result).not.toBeNull();
      expect(result!.email_hash).toBe(SAMPLE_EMAIL_HASH);
      expect(isValidEnvelope(result!.email_enc)).toBe(true);
      expect(result!.encryption_version).toBe(1);
    });

    it("email_enc should store and preserve R1 envelope structure (iv, ct, v)", async () => {
      const envelope = { iv: "abc123==", ct: "def456==", v: 1 };

      await env.DB.prepare(
        `INSERT INTO users (email_hash, email_enc, encryption_version, created_at, updated_at)
         VALUES (?, ?, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(SAMPLE_EMAIL_HASH, JSON.stringify(envelope))
        .run();

      const result = await env.DB.prepare(
        `SELECT email_enc FROM users WHERE email_hash = ?`
      )
        .bind(SAMPLE_EMAIL_HASH)
        .first<{ email_enc: string }>();

      expect(result).not.toBeNull();
      const parsed = JSON.parse(result!.email_enc);
      expect(parsed.iv).toBe(envelope.iv);
      expect(parsed.ct).toBe(envelope.ct);
      expect(parsed.v).toBe(envelope.v);
    });
  });

  describe("email_hash — SHA-256 형식 검증", () => {
    it("should be exactly 64 hex characters (SHA-256)", () => {
      // email_hash 값이 64자 hex 형식인지 확인
      expect(isSha256Hex(SAMPLE_EMAIL_HASH)).toBe(true);
    });

    it("should reject email_hash that is not 64 hex characters", () => {
      const invalidHash = "too_short";
      expect(isSha256Hex(invalidHash)).toBe(false);
    });

    it("should store and retrieve 64-char hex email_hash", async () => {
      await env.DB.prepare(
        `INSERT INTO users (email_hash, email_enc, encryption_version, created_at, updated_at)
         VALUES (?, ?, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(SAMPLE_EMAIL_HASH, SAMPLE_ENVELOPE)
        .run();

      const result = await env.DB.prepare(
        `SELECT email_hash FROM users WHERE email_hash = ?`
      )
        .bind(SAMPLE_EMAIL_HASH)
        .first<{ email_hash: string }>();

      expect(result).not.toBeNull();
      expect(isSha256Hex(result!.email_hash)).toBe(true);
      expect(result!.email_hash.length).toBe(64);
    });
  });

  describe("encryption_version — nullable 아님", () => {
    it("should reject null encryption_version", async () => {
      await expect(
        env.DB.prepare(
          `INSERT INTO users (email_hash, email_enc, encryption_version, created_at, updated_at)
           VALUES (?, ?, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
        )
          .bind(SAMPLE_EMAIL_HASH, SAMPLE_ENVELOPE)
          .run()
      ).rejects.toThrow();
    });

    it("should default encryption_version to 1 when not provided", async () => {
      // DEFAULT 1이 적용되어야 함
      await env.DB.prepare(
        `INSERT INTO users (email_hash, email_enc, created_at, updated_at)
         VALUES (?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(SAMPLE_EMAIL_HASH, SAMPLE_ENVELOPE)
        .run();

      const result = await env.DB.prepare(
        `SELECT encryption_version FROM users WHERE email_hash = ?`
      )
        .bind(SAMPLE_EMAIL_HASH)
        .first<{ encryption_version: number }>();

      expect(result).not.toBeNull();
      expect(result!.encryption_version).toBe(1);
      expect(typeof result!.encryption_version).toBe("number");
    });
  });

  describe("parallel-key rotation 지원 — encryption_version 추적", () => {
    it("should allow updating encryption_version for key rotation", async () => {
      await env.DB.prepare(
        `INSERT INTO users (email_hash, email_enc, encryption_version, created_at, updated_at)
         VALUES (?, ?, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`
      )
        .bind(SAMPLE_EMAIL_HASH, SAMPLE_ENVELOPE)
        .run();

      // key rotation 후 버전 업데이트
      const newEnvelope = JSON.stringify({ iv: "newIV==", ct: "newCT==", v: 2 });
      await env.DB.prepare(
        `UPDATE users SET email_enc = ?, encryption_version = 2, updated_at = CURRENT_TIMESTAMP
         WHERE email_hash = ?`
      )
        .bind(newEnvelope, SAMPLE_EMAIL_HASH)
        .run();

      const result = await env.DB.prepare(
        `SELECT encryption_version FROM users WHERE email_hash = ?`
      )
        .bind(SAMPLE_EMAIL_HASH)
        .first<{ encryption_version: number }>();

      expect(result).not.toBeNull();
      expect(result!.encryption_version).toBe(2);
    });

    it("should count users by encryption_version (rotation progress)", async () => {
      // batch re-encryption 진척률 추적 쿼리 (R4 Q4 rotation 절차 Phase 3)
      const result = await env.DB.prepare(
        `SELECT encryption_version, COUNT(*) as cnt FROM users GROUP BY encryption_version`
      ).all();

      // 테이블이 존재하면 결과를 반환 (비어있어도 됨)
      expect(result).toBeDefined();
    });
  });
});
