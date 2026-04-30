/**
 * src/services/scoring/typeClassifier.ts — GREEN phase
 * Rails: server/app/services/scoring/type_classifier.rb
 *
 * classifyType(normalizedScores) → { type_code, axes }
 * Axis mapping (score >= 50 → high letter):
 *   energy:          >= 50 → E, < 50 → I
 *   decision_making: >= 50 → N, < 50 → S
 *   relationship:    >= 50 → F, < 50 → T
 *   recovery:        >= 50 → P, < 50 → J
 *   null → defaults to low letter
 */

export interface AxisResult {
  letter: string;
  score: number | null;
}

export interface ClassificationResult {
  type_code: string;
  axes: {
    energy: AxisResult;
    decision_making: AxisResult;
    relationship: AxisResult;
    recovery: AxisResult;
  };
}

const AXIS_MAP: Record<string, [string, string]> = {
  energy:          ["E", "I"],
  decision_making: ["N", "S"],
  relationship:    ["F", "T"],
  recovery:        ["P", "J"],
};

const AXIS_ORDER = ["energy", "decision_making", "relationship", "recovery"] as const;

export function classifyType(
  normalizedScores: Record<string, number | null>
): ClassificationResult {
  const axes = {} as ClassificationResult["axes"];
  let type_code = "";

  for (const domain of AXIS_ORDER) {
    const score = normalizedScores[domain] ?? null;
    const [high, low] = AXIS_MAP[domain];
    const letter = score != null && score >= 50 ? high : low;
    axes[domain] = { letter, score };
    type_code += letter;
  }

  return { type_code, axes };
}
