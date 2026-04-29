/**
 * src/services/scoring/typeClassifier.ts — RED phase stub
 * Rails: server/app/services/scoring/type_classifier.rb
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

export function classifyType(
  _normalizedScores: Record<string, number | null>
): ClassificationResult {
  throw new Error("not implemented");
}
