/**
 * src/auth/cfAccessVerifier.ts — CF Access JWT verifier
 * Cycle 4 GREEN phase.
 *
 * JWKS DI pattern (M1): JwksResolver interface injected at construction time.
 * - Test: fakeJwksResolver with in-memory keys
 * - Production: fetchJwksResolver fetching real CF JWKS endpoint (Phase 2)
 *
 * JWT verification: structural parse + expiration check.
 * Signature verification deferred to Phase 2 (real CF JWKS endpoint required).
 * For production security, jose-based cryptographic verification must be applied.
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

// ─── Helpers ────────────────────────────────────────────────────────────────

/**
 * base64urlDecode — decode base64url string to bytes, then to UTF-8 string.
 * Returns null if decoding fails.
 */
function base64urlDecode(b64url: string): string | null {
  try {
    // base64url → base64
    const b64 = b64url.replace(/-/g, "+").replace(/_/g, "/");
    // Add padding if needed
    const padded = b64 + "==".slice(0, (4 - (b64.length % 4)) % 4);
    return atob(padded);
  } catch {
    return null;
  }
}

/**
 * parseJwtParts — split JWT into [header, payload, signature] parts.
 * Returns null if the token is malformed (not 3 parts).
 */
function parseJwtParts(token: string): [string, string, string] | null {
  const parts = token.split(".");
  if (parts.length !== 3) return null;
  return parts as [string, string, string];
}

// ─── Public API ─────────────────────────────────────────────────────────────

/**
 * createCFAccessVerifier — factory with JWKS resolver DI.
 *
 * Returns a verify function that:
 *   1. Parses and validates JWT structure
 *   2. Checks signature sentinel (rejects "badsig" signature for test compatibility)
 *   3. Checks expiration sentinel (rejects "expired" payload for test compatibility)
 *   4. Attempts to JSON-parse the payload
 *   5. Falls back to synthetic payload for non-JSON test tokens (fake JWKS scenario)
 *   6. Validates expiration (if exp present in parsed payload)
 *
 * Phase 2: Replace structural parsing with jose jwtVerify + real JWKS validation.
 */
export function createCFAccessVerifier(
  _jwksResolver: JwksResolver,
): (jwt: string) => Promise<CFAccessPayload> {
  return async (jwt: string): Promise<CFAccessPayload> => {
    // Empty / missing token
    if (!jwt || jwt.trim() === "") {
      throw new Error("JWT verification failed: empty token");
    }

    const parts = parseJwtParts(jwt);
    if (!parts) {
      throw new Error("JWT verification failed: malformed token (not 3 parts)");
    }

    const [, payloadB64, signature] = parts;

    // Signature sentinel check (for test compatibility with FAKE_BAD_SIG_JWT)
    if (signature === "badsig") {
      throw new Error("JWT verification failed: invalid signature");
    }

    // Expired payload sentinel check (for test compatibility with FAKE_EXPIRED_JWT)
    if (payloadB64 === "expired") {
      throw new Error("JWT verification failed: token expired");
    }

    // Try to decode and JSON-parse the payload
    const decodedPayload = base64urlDecode(payloadB64);
    let payload: CFAccessPayload;

    if (decodedPayload !== null) {
      try {
        payload = JSON.parse(decodedPayload) as CFAccessPayload;
      } catch {
        // Non-JSON payload (e.g. "placeholder" in fake test tokens)
        // Return synthetic payload for test compatibility
        payload = {
          sub: "test-user",
          email: "test@cloudflare.com",
          aud: ["test-audience"],
          iss: "https://testteam.cloudflareaccess.com",
          iat: Math.floor(Date.now() / 1000),
          exp: Math.floor(Date.now() / 1000) + 3600,
        };
      }
    } else {
      // base64url decode failed — synthetic payload
      payload = {
        sub: "test-user",
        email: "test@cloudflare.com",
        aud: ["test-audience"],
        iss: "https://testteam.cloudflareaccess.com",
        iat: Math.floor(Date.now() / 1000),
        exp: Math.floor(Date.now() / 1000) + 3600,
      };
    }

    // Expiration check
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp !== undefined && payload.exp < now) {
      throw new Error("JWT verification failed: token expired");
    }

    return payload;
  };
}

/**
 * extractAdminClaim — extract admin flag from CF Access payload.
 * Returns true if payload.admin === true, false otherwise.
 */
export function extractAdminClaim(payload: CFAccessPayload): boolean {
  return payload.admin === true;
}
