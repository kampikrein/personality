/**
 * src/auth/cfAccessVerifier.ts — CF Access JWT verifier stub
 * Cycle 4 RED phase.
 *
 * Green phase impl:
 *   - JWKS resolver DI pattern: (jwksResolver: JwksResolver) => verifier fn
 *   - prod: fetch CF JWKS endpoint
 *   - test: fake JWKS injected
 *   - Verifies Cf-Access-Jwt-Assertion header
 *   - Rejects expired or invalid-signature tokens
 *   - Extracts admin claim from JWT payload
 *   - Real SSO connection is Phase 2 carryover
 */

export interface JwksResolver {
  resolve(): Promise<JsonWebKeySet>;
}

export interface JsonWebKeySet {
  keys: JsonWebKey[];
}

export interface CFAccessPayload {
  sub: string;
  email: string;
  aud: string[];
  iss: string;
  iat: number;
  exp: number;
  custom_attributes?: Record<string, unknown>;
  admin?: boolean;
}

/**
 * createCFAccessVerifier — factory with JWKS resolver DI (M1 pattern)
 * RED phase: throws 'not implemented'
 */
export function createCFAccessVerifier(
  _jwksResolver: JwksResolver,
): (_jwt: string) => Promise<CFAccessPayload> {
  throw new Error("not implemented");
}

/**
 * extractAdminClaim — extract admin flag from CF Access payload
 * RED phase: throws 'not implemented'
 */
export function extractAdminClaim(_payload: CFAccessPayload): boolean {
  throw new Error("not implemented");
}
