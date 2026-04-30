/**
 * src/crypto/keyRotation.ts — Parallel-key rotation (R4-F3 5-phase) stub
 * Cycle 4 RED phase.
 *
 * Green phase impl:
 *   - Phase 0: Normal operation with K_n
 *   - Phase 1: Add K_{n+1}, enable dual-read (try K_n first, fallback K_{n+1})
 *   - Phase 2: Re-encrypt existing ciphertext with K_{n+1}
 *   - Phase 3: Verify re-encryption completeness
 *   - Phase 4: Update external backup (R2 sealed) — Phase 2 carryover
 *   - Phase 5: Retire K_n
 *
 *   - dual-read: select key by encryption_version column
 *   - in-memory key map for unit test (no real wrangler secret)
 */

export interface RotationKey {
  version: number;
  key: CryptoKey;
}

export interface RotationContext {
  keys: RotationKey[];
  currentVersion: number;
}

/**
 * createRotationContext — initialise key context
 * RED phase: throws 'not implemented'
 */
export function createRotationContext(_keys: RotationKey[]): RotationContext {
  throw new Error("not implemented");
}

/**
 * selectKeyForVersion — dual-read: pick key by encryption_version
 * RED phase: throws 'not implemented'
 */
export function selectKeyForVersion(
  _ctx: RotationContext,
  _version: number,
): CryptoKey {
  throw new Error("not implemented");
}

/**
 * addNewKey — Phase 1: register K_{n+1} into context
 * RED phase: throws 'not implemented'
 */
export function addNewKey(_ctx: RotationContext, _newKey: RotationKey): RotationContext {
  throw new Error("not implemented");
}

/**
 * reEncryptRow — Phase 2: re-encrypt a single email_enc value from K_n to K_{n+1}
 * RED phase: throws 'not implemented'
 */
export async function reEncryptRow(
  _ctx: RotationContext,
  _emailEnc: string,
  _oldVersion: number,
  _newVersion: number,
): Promise<{ emailEnc: string; encryptionVersion: number }> {
  throw new Error("not implemented");
}

/**
 * retireKey — Phase 5: remove K_n from context
 * RED phase: throws 'not implemented'
 */
export function retireKey(_ctx: RotationContext, _version: number): RotationContext {
  throw new Error("not implemented");
}
