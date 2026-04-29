/**
 * src/db/index.ts — Drizzle client (GREEN phase)
 *
 * D1 binding을 주입받아 type-safe DrizzleD1Database를 반환.
 * 서비스 레이어, API routes, 테스트에서 이 함수를 통해 DB에 접근.
 */

import { drizzle } from "drizzle-orm/d1";
import * as schema from "./schema";

export function createDb(d1: D1Database) {
  return drizzle(d1, { schema });
}

export type Db = ReturnType<typeof createDb>;

// 편의 re-export (테스트 및 서비스에서 직접 임포트)
export * from "./schema";
export * from "./types";
