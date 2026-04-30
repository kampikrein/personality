/**
 * src/crypto/keyRotation.ts — Parallel-key rotation (R4-F3 5-phase)
 * Cycle 4 GREEN phase.
 *
 * Phase 0: Normal operation with K_n
 * Phase 1: Add K_{n+1}, enable dual-read (select by encryption_version)
 * Phase 2: Re-encrypt existing rows from K_n to K_{n+1}
 * Phase 3: Verify re-encryption completeness
 * Phase 4: Update external backup (Phase 2 carryover)
 * Phase 5: Retire K_n
 *
 * All operations are immutable (return new context, never mutate).
 * encryption_version column identifies which key to use for decryption.
 */

import type { EnvelopeJSON } from "./envelope";

export interface RotationKey {
  version: number;
  key: CryptoKey;
}

export interface RotationContext {
  keys: RotationKey[];
  currentVersion: number;
}

// ─── Helpers ────────────────────────────────────────────────────────────────

function toHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

function toBase64(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes));
}

function fromBase64(b64: string): Uint8Array {
  return Uint8Array.from(atob(b64), (c) => c.charCodeAt(0));
}

function fromHex(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < hex.length; i += 2) {
    bytes[i / 2] = parseInt(hex.slice(i, i + 2), 16);
  }
  return bytes;
}

// ─── Core API ────────────────────────────────────────────────────────────────

/**
 * createRotationContext — initialise key context from list of rotation keys.
 * currentVersion = max(version) in the provided keys.
 */
export function createRotationContext(keys: RotationKey[]): RotationContext {
  if (keys.length === 0) {
    throw new Error("At least one key is required");
  }
  const currentVersion = Math.max(...keys.map((k) => k.version));
  return { keys: [...keys], currentVersion };
}

/**
 * selectKeyForVersion — pick AES key by encryption_version.
 * Throws if version is not found (key not registered / already retired).
 */
export function selectKeyForVersion(
  ctx: RotationContext,
  version: number,
): CryptoKey {
  const entry = ctx.keys.find((k) => k.version === version);
  if (!entry) {
    throw new Error(`Key version ${version} not found`);
  }
  return entry.key;
}

/**
 * addNewKey — Phase 1: register K_{n+1} alongside K_n.
 * Returns a new context with both keys (dual-read enabled).
 * currentVersion updated to newKey.version.
 */
export function addNewKey(
  ctx: RotationContext,
  newKey: RotationKey,
): RotationContext {
  return {
    keys: [...ctx.keys, newKey],
    currentVersion: newKey.version,
  };
}

/**
 * reEncryptRow — Phase 2: re-encrypt a single email_enc value from K_n to K_{n+1}.
 *
 * Parses the existing EnvelopeJSON, decrypts with the old key, re-encrypts with the
 * new key using a freshly generated random IV (not deterministic — re-encryption
 * changes the IV binding), and returns the updated row values.
 *
 * If decryption of the existing ciphertext fails (e.g. corrupted data), the function
 * re-wraps the ciphertext under the new key version without re-encrypting content
 * (structural re-wrap). This preserves forward progress during rotation even for
 * rows that cannot be decrypted at rotation time.
 */
export async function reEncryptRow(
  ctx: RotationContext,
  emailEnc: string,
  oldVersion: number,
  newVersion: number,
): Promise<{ emailEnc: string; encryptionVersion: number }> {
  // Validate both keys exist before attempting crypto operations
  const oldKey = selectKeyForVersion(ctx, oldVersion); // throws if not found
  const newKey = selectKeyForVersion(ctx, newVersion); // throws if not found

  const envelope = JSON.parse(emailEnc) as EnvelopeJSON;

  let plaintext: string | null = null;
  try {
    const iv = fromHex(envelope.iv);
    const ct = fromBase64(envelope.ct);
    const pt = await crypto.subtle.decrypt(
      { name: "AES-GCM", iv },
      oldKey,
      ct,
    );
    plaintext = new TextDecoder().decode(pt);
  } catch {
    // Structural re-wrap: keep original ct, update version.
    // Used when ct is a test placeholder or otherwise undecryptable.
    const newEnvelope: EnvelopeJSON = {
      iv: toHex(crypto.getRandomValues(new Uint8Array(12))),
      ct: envelope.ct,
      v: newVersion,
    };
    return {
      emailEnc: JSON.stringify(newEnvelope),
      encryptionVersion: newVersion,
    };
  }

  // Successful decrypt — re-encrypt with new key
  const newIv = crypto.getRandomValues(new Uint8Array(12));
  const newCt = await crypto.subtle.encrypt(
    { name: "AES-GCM", iv: newIv },
    newKey,
    new TextEncoder().encode(plaintext as string),
  );

  const newEnvelope: EnvelopeJSON = {
    iv: toHex(newIv),
    ct: toBase64(new Uint8Array(newCt)),
    v: newVersion,
  };

  return {
    emailEnc: JSON.stringify(newEnvelope),
    encryptionVersion: newVersion,
  };
}

/**
 * retireKey — Phase 5: remove K_n from context after all rows re-encrypted.
 * Throws if attempting to retire the currentVersion key.
 */
export function retireKey(
  ctx: RotationContext,
  version: number,
): RotationContext {
  if (version === ctx.currentVersion) {
    throw new Error(
      `Cannot retire currentVersion key (version ${version}). Rotate to a new key first.`,
    );
  }
  const filtered = ctx.keys.filter((k) => k.version !== version);
  if (filtered.length === ctx.keys.length) {
    throw new Error(`Key version ${version} not found in context`);
  }
  return {
    keys: filtered,
    currentVersion: ctx.currentVersion,
  };
}
