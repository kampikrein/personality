/**
 * src/services/quality/botDetector.ts — RED phase stub
 * Rails: server/app/services/quality/bot_detector.rb
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

export function detectBot(
  _responses: ResponseForBot[]
): BotDetectionResult {
  throw new Error("not implemented");
}
