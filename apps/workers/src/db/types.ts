/**
 * src/db/types.ts — Drizzle JSON 컬럼 타입 정의
 *
 * 9 JSON 컬럼별 $type<T>() 인터페이스 정의.
 * schema.ts에서 import하여 사용.
 *
 * Rails schema.rb의 t.json 컬럼 9개:
 *   1. alerts.metadata (default: {})
 *   2. audit_logs.metadata (default: {})
 *   3. insights.suggestions (default: [])
 *   4. personality_types.caution_patterns (default: [])
 *   5. personality_types.strengths (default: [])
 *   6. profiles.caution_patterns (default: [])
 *   7. profiles.score_vector (default: {})
 *   8. profiles.strengths (default: [])
 *   9. profiles.suggested_actions (default: [])
 */

// 1. alerts.metadata
export type AlertMetadata = Record<string, unknown>;

// 2. audit_logs.metadata
export interface AuditMetadata {
  before?: Record<string, unknown>;
  after?: Record<string, unknown>;
  ip_hash?: string;
  user_agent_hash?: string;
  [key: string]: unknown;
}

// 3. insights.suggestions — string[]
export type InsightSuggestion = string;

// 4 & 5. personality_types.caution_patterns / personality_types.strengths — string[]
// (inline string[] 타입 사용)

// 6 & 8. profiles.caution_patterns / profiles.strengths — string[]
// (inline string[] 타입 사용)

// 7. profiles.score_vector — domain별 점수 (0–100 float)
export interface ScoreVector {
  energy?: number;
  decision_making?: number;
  relationship?: number;
  recovery?: number;
  [domain: string]: number | undefined;
}

// 9. profiles.suggested_actions
export interface SuggestedAction {
  action: string;
  priority?: "high" | "medium" | "low" | number;
  context?: string;
  [key: string]: unknown;
}
