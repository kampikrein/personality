/**
 * src/auth/betterAuth.ts — BetterAuth(D1+KV) stub
 * Cycle 4 RED phase.
 *
 * Green phase impl:
 *   - betterAuth({ database: drizzleAdapter(db, {...}), secondaryStorage: kvAdapter(kv) })
 *   - email_hash hook in beforeCreate
 *   - cookie domain isolation: api.<DOMAIN> vs admin.<DOMAIN> (BC1)
 */

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

/**
 * createAuth — BetterAuth instance factory (D1 adapter + KV secondary storage)
 * RED phase: throws 'not implemented'
 */
export function createAuth(_config: BetterAuthConfig): unknown {
  throw new Error("not implemented");
}

/**
 * signUp — email/password signup → inserts user row (email_hash + email_enc + encryption_version)
 * RED phase: throws 'not implemented'
 */
export async function signUp(
  _auth: unknown,
  _email: string,
  _password: string,
): Promise<AuthUser> {
  throw new Error("not implemented");
}

/**
 * signIn — email/password signin → KV session store
 * RED phase: throws 'not implemented'
 */
export async function signIn(
  _auth: unknown,
  _email: string,
  _password: string,
): Promise<{ user: AuthUser; sessionId: string }> {
  throw new Error("not implemented");
}

/**
 * signOut — invalidate session in KV
 * RED phase: throws 'not implemented'
 */
export async function signOut(_kv: KVNamespace, _sessionId: string): Promise<void> {
  throw new Error("not implemented");
}

/**
 * getSession — retrieve session from KV
 * RED phase: throws 'not implemented'
 */
export async function getSession(
  _kv: KVNamespace,
  _sessionId: string,
): Promise<SessionStore | null> {
  throw new Error("not implemented");
}

/**
 * lookupUserByEmailHash — deterministic email lookup
 * RED phase: throws 'not implemented'
 */
export async function lookupUserByEmailHash(
  _db: D1Database,
  _emailHash: string,
): Promise<AuthUser | null> {
  throw new Error("not implemented");
}
