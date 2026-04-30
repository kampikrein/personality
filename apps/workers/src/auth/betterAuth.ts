/**
 * src/auth/betterAuth.ts — Auth implementation (D1 + KV)
 * Cycle 4 GREEN phase.
 *
 * Direct D1/KV implementation without better-auth dependency
 * (better-auth is marked external in vitest.config.ts due to Workers runtime constraints).
 *
 * Phase 2: Replace direct D1/KV with full BetterAuth adapter integration
 * once Workers runtime + nodejs_compat compatibility is resolved.
 *
 * Features:
 *   - signUp: PBKDF2 password hash + SHA-256 email_hash + email_enc envelope
 *   - signIn: password verify + KV session storage
 *   - signOut: KV session deletion
 *   - getSession: KV session retrieval
 *   - lookupUserByEmailHash: D1 deterministic email lookup
 */

import { sha256Hex } from "../crypto/emailHash";

export interface BetterAuthConfig {
  d1: D1Database;
  kv: KVNamespace;
}

export interface AuthUser {
  id: number;
  emailHash: string;
  emailEnc: string;
  encryptionVersion: number;
  displayName: string | null;
}

export interface SessionStore {
  userId: number;
  expiresAt: string;
}

// ─── Helpers ────────────────────────────────────────────────────────────────

const PBKDF2_ITERATIONS = 100_000;
const SESSION_TTL_SECONDS = 7 * 24 * 60 * 60; // 7 days

async function hashPassword(password: string): Promise<string> {
  const encoder = new TextEncoder();
  const salt = crypto.getRandomValues(new Uint8Array(16));
  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    encoder.encode(password),
    "PBKDF2",
    false,
    ["deriveBits"],
  );
  const derivedBits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      salt,
      iterations: PBKDF2_ITERATIONS,
      hash: "SHA-256",
    },
    keyMaterial,
    256,
  );
  const hashBytes = new Uint8Array(derivedBits);
  const saltHex = Array.from(salt)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  const hashHex = Array.from(hashBytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return `pbkdf2:${PBKDF2_ITERATIONS}:${saltHex}:${hashHex}`;
}

async function verifyPassword(
  password: string,
  digest: string,
): Promise<boolean> {
  const [, iterStr, saltHex, hashHex] = digest.split(":");
  const iterations = parseInt(iterStr, 10);
  const saltBytes = new Uint8Array(
    saltHex.match(/.{2}/g)!.map((h) => parseInt(h, 16)),
  );
  const encoder = new TextEncoder();
  const keyMaterial = await crypto.subtle.importKey(
    "raw",
    encoder.encode(password),
    "PBKDF2",
    false,
    ["deriveBits"],
  );
  const derivedBits = await crypto.subtle.deriveBits(
    {
      name: "PBKDF2",
      salt: saltBytes,
      iterations,
      hash: "SHA-256",
    },
    keyMaterial,
    256,
  );
  const derived = Array.from(new Uint8Array(derivedBits))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  return derived === hashHex;
}

function makeEmailEnc(email: string): string {
  // Placeholder envelope: stores base64-encoded email without encryption key.
  // Phase 2: replace with real encryptEnvelope using Wrangler secrets.
  const encoded = btoa(unescape(encodeURIComponent(email)));
  return JSON.stringify({ iv: "", ct: encoded, v: 1 });
}

// ─── Auth instance ────────────────────────────────────────────────────────────

interface AuthInstance {
  d1: D1Database;
  kv: KVNamespace;
}

/**
 * createAuth — Auth instance factory (D1 adapter + KV secondary storage).
 */
export function createAuth(config: BetterAuthConfig): AuthInstance {
  return { d1: config.d1, kv: config.kv };
}

// ─── Auth operations ─────────────────────────────────────────────────────────

/**
 * signUp — email/password signup.
 * Inserts user row with email_hash + email_enc + encryption_version.
 * Throws on duplicate email (unique email_hash constraint).
 */
export async function signUp(
  auth: AuthInstance,
  email: string,
  password: string,
): Promise<AuthUser> {
  const emailHash = await sha256Hex(email.toLowerCase().trim());
  const passwordDigest = await hashPassword(password);
  const emailEnc = makeEmailEnc(email);

  const result = await auth.d1
    .prepare(
      `INSERT INTO users (email_hash, email_enc, encryption_version, password_digest, created_at, updated_at)
       VALUES (?, ?, 1, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       RETURNING id, email_hash, email_enc, encryption_version, display_name`,
    )
    .bind(emailHash, emailEnc, passwordDigest)
    .first<{
      id: number;
      email_hash: string;
      email_enc: string;
      encryption_version: number;
      display_name: string | null;
    }>();

  if (!result) {
    throw new Error("Failed to create user");
  }

  return {
    id: result.id,
    emailHash: result.email_hash,
    emailEnc: result.email_enc,
    encryptionVersion: result.encryption_version,
    displayName: result.display_name,
  };
}

/**
 * signIn — email/password sign-in.
 * Verifies password and stores session in KV.
 */
export async function signIn(
  auth: AuthInstance,
  email: string,
  password: string,
): Promise<{ user: AuthUser; sessionId: string }> {
  const emailHash = await sha256Hex(email.toLowerCase().trim());

  const row = await auth.d1
    .prepare(
      `SELECT id, email_hash, email_enc, encryption_version, display_name, password_digest
       FROM users WHERE email_hash = ? AND deleted_at IS NULL LIMIT 1`,
    )
    .bind(emailHash)
    .first<{
      id: number;
      email_hash: string;
      email_enc: string;
      encryption_version: number;
      display_name: string | null;
      password_digest: string;
    }>();

  if (!row) {
    throw new Error("Invalid credentials");
  }

  const valid = await verifyPassword(password, row.password_digest);
  if (!valid) {
    throw new Error("Invalid credentials");
  }

  const user: AuthUser = {
    id: row.id,
    emailHash: row.email_hash,
    emailEnc: row.email_enc,
    encryptionVersion: row.encryption_version,
    displayName: row.display_name,
  };

  // Store session in KV
  const sessionId = crypto.randomUUID();
  const expiresAt = new Date(
    Date.now() + SESSION_TTL_SECONDS * 1000,
  ).toISOString();

  const session: SessionStore = { userId: user.id, expiresAt };
  await auth.kv.put(`session:${sessionId}`, JSON.stringify(session), {
    expirationTtl: SESSION_TTL_SECONDS,
  });

  return { user, sessionId };
}

/**
 * signOut — invalidate session in KV.
 */
export async function signOut(
  kv: KVNamespace,
  sessionId: string,
): Promise<void> {
  await kv.delete(`session:${sessionId}`);
}

/**
 * getSession — retrieve session from KV.
 * Returns null if session does not exist or is expired.
 */
export async function getSession(
  kv: KVNamespace,
  sessionId: string,
): Promise<SessionStore | null> {
  const raw = await kv.get(`session:${sessionId}`);
  if (!raw) return null;
  try {
    return JSON.parse(raw) as SessionStore;
  } catch {
    return null;
  }
}

/**
 * lookupUserByEmailHash — deterministic email lookup via SHA-256 hash.
 * Returns null if user not found or deleted.
 */
export async function lookupUserByEmailHash(
  db: D1Database,
  emailHash: string,
): Promise<AuthUser | null> {
  const row = await db
    .prepare(
      `SELECT id, email_hash, email_enc, encryption_version, display_name
       FROM users WHERE email_hash = ? AND deleted_at IS NULL LIMIT 1`,
    )
    .bind(emailHash)
    .first<{
      id: number;
      email_hash: string;
      email_enc: string;
      encryption_version: number;
      display_name: string | null;
    }>();

  if (!row) return null;

  return {
    id: row.id,
    emailHash: row.email_hash,
    emailEnc: row.email_enc,
    encryptionVersion: row.encryption_version,
    displayName: row.display_name,
  };
}
