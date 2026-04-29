/**
 * src/db/index.ts — Drizzle client export stub (RED phase)
 *
 * GREEN phase에서 D1 binding을 주입받아 Drizzle client를 export한다.
 *
 * GREEN phase 구현:
 *   import { drizzle } from "drizzle-orm/d1";
 *   import * as schema from "./schema";
 *   export function createDb(d1: D1Database) {
 *     return drizzle(d1, { schema });
 *   }
 *   export type Db = ReturnType<typeof createDb>;
 */

// RED phase stub
export const createDb = (_d1: unknown) => {
  throw new Error("createDb: schema not implemented yet (RED phase stub)");
};
