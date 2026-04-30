/**
 * src/services/quality/botDetector.ts — GREEN phase
 * Rails: server/app/services/quality/bot_detector.rb
 *
 * detectBot(responses) → { bot_suspected, patterns, confidence }
 * Patterns:
 *   - uniform: all responses have the same value
 *   - sequential: values repeat in a cycle [1,2,3,4,5,1,2,3,4,5,...]
 *   - zero_variance_timing: all response_time_ms are identical
 * confidence = proportion of fired heuristics (0.0 to 1.0, rounded to 2 decimal places)
 * bot_suspected = confidence > 0
 */

export interface BotDetectionResult {
  bot_suspected: boolean;
  patterns: Array<"uniform" | "sequential" | "zero_variance_timing">;
  confidence: number;
}

export interface ResponseForBot {
  value: number | null;
  response_time_ms: number | null;
}

const TOTAL_HEURISTICS = 3;

function isUniform(responses: ResponseForBot[]): boolean {
  const values = responses.map((r) => r.value).filter((v) => v != null);
  if (values.length < 2) return false;
  return new Set(values).size === 1;
}

function isSequential(responses: ResponseForBot[]): boolean {
  const values = responses.map((r) => r.value).filter((v): v is number => v != null);
  if (values.length < 2) return false;

  // Need more than 1 unique value for a cycle to exist
  const uniqueValues = new Set(values);
  if (uniqueValues.size < 2) return false;

  // Detect repeating cycle: find shortest period that fits
  for (let period = 2; period <= Math.floor(values.length / 2); period++) {
    const cycle = values.slice(0, period);
    const expected = Array.from({ length: values.length }, (_, i) => cycle[i % period]);
    if (expected.every((v, i) => v === values[i])) {
      return true;
    }
  }
  return false;
}

function isZeroVarianceTiming(responses: ResponseForBot[]): boolean {
  const times = responses.map((r) => r.response_time_ms).filter((t): t is number => t != null);
  if (times.length < 2) return false;
  return new Set(times).size === 1;
}

export function detectBot(
  responses: ResponseForBot[]
): BotDetectionResult {
  if (responses.length < 2) {
    return {
      bot_suspected: false,
      patterns: [],
      confidence: 0.0,
    };
  }

  const patterns: Array<"uniform" | "sequential" | "zero_variance_timing"> = [];

  if (isUniform(responses)) {
    patterns.push("uniform");
  }
  if (isSequential(responses)) {
    patterns.push("sequential");
  }
  if (isZeroVarianceTiming(responses)) {
    patterns.push("zero_variance_timing");
  }

  const confidence = Number((patterns.length / TOTAL_HEURISTICS).toFixed(2));
  const bot_suspected = confidence > 0;

  return {
    bot_suspected,
    patterns,
    confidence,
  };
}
