/**
 * src/ui/pages/public/consents/new.tsx — Consent collection form stub
 * Cycle 6 RED phase.
 */

export interface ConsentsNewProps {
  csrfToken: string;
  assessmentId: string;
}

export function ConsentsNewPage(props: ConsentsNewProps): string {
  return `<div class="consents-new">
  <h1>Data Consent</h1>
  <form method="post" action="/api/consents">
    <input type="hidden" name="csrf_token" value="${props.csrfToken}">
    <input type="hidden" name="assessment_id" value="${props.assessmentId}">
    <label><input type="checkbox" name="data_processing" required> I consent to data processing</label>
    <label><input type="checkbox" name="third_party"> I consent to third-party sharing</label>
    <button type="submit">Continue</button>
  </form>
</div>`;
}
