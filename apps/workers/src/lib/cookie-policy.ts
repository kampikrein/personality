// Cookie 격리 정책 placeholder
// Synthesis § 2 Conflict 2 — 격리 (host-scoped) 결정
// Decision: api.<DOMAIN> host-scoped, admin.<DOMAIN> host-scoped — 두 평면 완전 격리
//
// NOTE(Phase 2 / Cycle 4): BetterAuth + CF Access 실 코드와 결합 시 본 함수를 사용.
//   Cycle 4에서 betterauth.ts, cf_access_verifier.ts가 cookieDomainForHost()를 import.
//   로컬 wrangler dev 환경에서는 hostname이 "localhost"로 들어오므로 null을 반환 —
//   Cycle 4 makeplan에서 테스트 시 hostname mock 처리 필요 (Scope 026 Mn6).

export function cookieDomainForHost(host: string): string | null {
  if (host.startsWith("api.")) return host;    // host-scoped — BetterAuth session cookie
  if (host.startsWith("admin.")) return host;  // host-scoped — CF_Authorization (CF Access 자동)
  return null;                                  // dev / fallback (no domain attribute)
}

export const COOKIE_DEFAULTS = {
  sameSite: "Lax" as const,
  secure: true,
  httpOnly: true,
  path: "/",
} as const;
