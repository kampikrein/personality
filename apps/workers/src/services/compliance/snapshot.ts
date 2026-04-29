/**
 * src/services/compliance/snapshot.ts — RED phase stub
 * Rails: spec/services/compliance/snapshot_spec.rb에만 존재 (service 파일 없음)
 *
 * Legal content verification: scans personality_types seed data and
 * template content for restricted terms compliance.
 *
 * Note: In Rails this is a "model spec" that tests the seed data and
 * template files directly via Compliance::RestrictedTerms. In TS,
 * this becomes a snapshot verification utility against the D1 seed data.
 */

export interface SnapshotViolation {
  code: string;
  field: string;
  value: string;
  terms: string[];
}

export async function scanSeedDataForViolations(
  _db: unknown
): Promise<SnapshotViolation[]> {
  throw new Error("not implemented");
}

export async function verifyCharacterNameOriginality(
  _db: unknown
): Promise<{ violations: SnapshotViolation[]; hasUniqueNames: boolean }> {
  throw new Error("not implemented");
}
